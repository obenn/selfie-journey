import Foundation
import Observation
import UIKit

@Observable @MainActor
final class AppSupport {
    static let shared = AppSupport()
    static let maximumDiagnostics = 80
    static let diagnosticLifetime: TimeInterval = 7 * 24 * 60 * 60
    static let reportingDisclosureVersion = 1
    private(set) var level: TelemetryLevel
    private(set) var hasAcknowledgedReporting: Bool
    private(set) var installationID: String?
    private(set) var diagnostics: [LocalDiagnostic]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let transport: any SupportTransport
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let appVersion: String
    @ObservationIgnored private let osVersion: String
    @ObservationIgnored private let deviceClass: String
    @ObservationIgnored private let automaticallyFlush: Bool
    @ObservationIgnored private var counts: [SupportEvent: Int] = [:]
    @ObservationIgnored private var uploadTask: Task<Void, Never>?
    @ObservationIgnored private var scheduledTask: Task<Void, Never>?
    @ObservationIgnored private var consentGeneration = UUID()
    @ObservationIgnored private var automaticReportingPermitted = false

    init(defaults: UserDefaults? = nil, transport: (any SupportTransport)? = nil,
         now: @escaping () -> Date = Date.init, automaticallyFlush: Bool = true) {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            || environment["XCTestConfigurationFilePath"] != nil
            || environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        let testing = false
        #endif
        let defaults = defaults ?? (testing ? UserDefaults(suiteName: "journey.ui-testing.support")! : .standard)
        #if DEBUG
        if testing, ProcessInfo.processInfo.arguments.contains("--reset-support") {
            ["journey.telemetry.level", "journey.telemetry.id", "journey.telemetry.disclosureVersion", "journey.support.diagnostics"].forEach(defaults.removeObject(forKey:))
        }
        #endif
        self.defaults = defaults
        self.transport = transport ?? SupportURLSession(networkingEnabled: !testing)
        self.now = now
        self.automaticallyFlush = automaticallyFlush && !testing
        let initialLevel = TelemetryLevel(rawValue: defaults.string(forKey: "journey.telemetry.level") ?? "full") ?? .off
        let storedID = defaults.string(forKey: "journey.telemetry.id").flatMap(UUID.init(uuidString:))
        let initialID = initialLevel == .full ? (storedID ?? UUID()).uuidString : nil
        level = initialLevel
        hasAcknowledgedReporting = defaults.integer(forKey: "journey.telemetry.disclosureVersion") >= Self.reportingDisclosureVersion
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        // Unrelated UI tests enter the journal directly. Disclosure tests and
        // onboarding tests exercise the real persisted acknowledgement path.
        if arguments.contains("--uitesting"), !arguments.contains("--reporting-disclosure"), !arguments.contains("--onboarding") {
            hasAcknowledgedReporting = true
        }
        #endif
        installationID = initialID
        if let initialID { defaults.set(initialID, forKey: "journey.telemetry.id") }
        else { defaults.removeObject(forKey: "journey.telemetry.id") }
        diagnostics = defaults.data(forKey: "journey.support.diagnostics")
            .flatMap { try? JSONDecoder().decode([LocalDiagnostic].self, from: $0) } ?? []
        appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let version = ProcessInfo.processInfo.operatingSystemVersion
        osVersion = "\(version.majorVersion).\(version.minorVersion)"
        deviceClass = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        pruneDiagnostics()
    }

    /// The app calls this only once setup has completed. Keeping the gate here
    /// also protects against a future instrumented operation running during setup.
    func activateAfterSetup() {
        guard hasAcknowledgedReporting else { return }
        automaticReportingPermitted = true
    }

    func acknowledgeReporting() {
        hasAcknowledgedReporting = true
        defaults.set(Self.reportingDisclosureVersion, forKey: "journey.telemetry.disclosureVersion")
    }

    /// Revocation is immediate, including queued and in-flight uploads. No
    /// pre-choice events are carried into a less private reporting level.
    func setLevel(_ value: TelemetryLevel) {
        guard value != level else { return }
        cancelTelemetry()
        level = value
        defaults.set(value.rawValue, forKey: "journey.telemetry.level")
        installationID = value == .full ? UUID().uuidString : nil
        if let installationID { defaults.set(installationID, forKey: "journey.telemetry.id") }
        else { defaults.removeObject(forKey: "journey.telemetry.id") }
    }

    func resetIdentifier() {
        cancelTelemetry()
        guard level == .full else { return }
        installationID = UUID().uuidString
        defaults.set(installationID, forKey: "journey.telemetry.id")
    }

    func record(_ event: SupportEvent) {
        diagnostics.append(LocalDiagnostic(code: event, recordedAt: now()))
        pruneDiagnostics()
        guard automaticReportingPermitted, level != .off else { return }
        counts[event] = min(100, (counts[event] ?? 0) + 1)
        guard automaticallyFlush, scheduledTask == nil, uploadTask == nil else { return }
        scheduledTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            await self?.flush()
        }
    }

    /// Counts are held only in memory and are dropped after a failed request;
    /// there is no hidden offline usage history to upload at a later date.
    func flush() async {
        scheduledTask = nil
        guard automaticReportingPermitted, uploadTask == nil, level != .off, !counts.isEmpty else { return }
        let generation = consentGeneration
        let payload = telemetryPayload()
        counts = [:]
        let task = Task {
            do {
                try Task.checkCancellation()
                try await transport.telemetry(payload)
            } catch { /* Local use never depends on analytics. */ }
        }
        uploadTask = task
        await task.value
        guard generation == consentGeneration else { return }
        uploadTask = nil
        if !counts.isEmpty, automaticallyFlush {
            scheduledTask = Task { [weak self] in await self?.flush() }
        }
    }

    func telemetryPayload() -> TelemetryPayload {
        let full = level == .full
        return TelemetryPayload(batchId: UUID(), mode: level,
            events: counts.map { TelemetryPayload.Event(name: $0.key, count: $0.value) }.sorted { $0.name.rawValue < $1.name.rawValue },
            appVersion: full ? appVersion : nil, osVersion: full ? osVersion : nil,
            deviceClass: full ? deviceClass : nil, installationId: full ? installationID : nil)
    }

    func diagnosticReport() -> DiagnosticReport {
        pruneDiagnostics()
        return DiagnosticReport(appVersion: appVersion, osVersion: osVersion, deviceClass: deviceClass,
            events: diagnostics.map { .init(code: $0.code, ageSeconds: max(0, Int(now().timeIntervalSince($0.recordedAt) / 60) * 60)) })
    }

    func clearDiagnostics() {
        diagnostics = []
        defaults.removeObject(forKey: "journey.support.diagnostics")
    }

    func sendFeedback(_ payload: FeedbackPayload) async throws -> String {
        try await transport.feedback(payload)
    }

    private func cancelTelemetry() {
        consentGeneration = UUID()
        uploadTask?.cancel()
        scheduledTask?.cancel()
        uploadTask = nil
        scheduledTask = nil
        counts = [:]
    }

    private func pruneDiagnostics() {
        let cutoff = now().addingTimeInterval(-Self.diagnosticLifetime)
        diagnostics = Array(diagnostics.filter { $0.recordedAt >= cutoff && $0.recordedAt <= now() }.suffix(Self.maximumDiagnostics))
        if let data = try? JSONEncoder().encode(diagnostics) { defaults.set(data, forKey: "journey.support.diagnostics") }
    }
}
