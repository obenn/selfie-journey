import Foundation
import Testing
@testable import SelfieJourney

@MainActor
struct AppSupportTests {
    private func isolatedDefaults() -> (UserDefaults, String) {
        let suite = "journey-support-tests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite)!, suite)
    }

    private func activate(_ support: AppSupport) {
        support.acknowledgeReporting()
        support.activateAfterSetup()
    }

    @Test func freshInstallDefaultsToFullAndPersistsRandomIdentifier() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = AppSupport(defaults: defaults, transport: RecordingSupportTransport(), automaticallyFlush: false)
        #expect(first.level == .full)
        #expect(first.installationID.flatMap(UUID.init(uuidString:)) != nil)
        let next = AppSupport(defaults: defaults, transport: RecordingSupportTransport(), automaticallyFlush: false)
        #expect(first.installationID == next.installationID)
    }

    @Test func offKeepsLocalLogsButMakesNoAutomaticRequests() async {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport()
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        support.setLevel(.off)
        support.record(.cameraError)
        await support.flush()
        #expect(await transport.telemetryRequests.isEmpty)
        #expect(support.diagnostics.map(\.code) == [.cameraError])
        #expect(support.installationID == nil)
    }

    @Test func limitedWirePayloadOmitsAllIdentifiersAndDeviceMetadata() async throws {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport()
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        support.setLevel(.limited)
        support.record(.appOpen)
        support.record(.cameraError)
        await support.flush()
        let payload = try #require(await transport.telemetryRequests.first)
        let dictionary = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])
        #expect(Set(dictionary.keys) == ["batchId", "mode", "events"])
        #expect(payload.events.count == 2)
        #expect(payload.mode == .limited)
    }

    @Test func modeChangesDiscardPendingEventsAndRotateFullIdentity() async {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport()
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        let oldID = support.installationID
        support.record(.portraitSaved)
        support.setLevel(.limited)
        await support.flush()
        #expect(await transport.telemetryRequests.isEmpty)
        support.setLevel(.full)
        #expect(support.installationID != oldID)
        let intermediate = support.installationID
        support.resetIdentifier()
        #expect(support.installationID != intermediate)
    }

    @Test func offCancelsAnInFlightReport() async throws {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport(delay: true)
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        support.record(.appOpen)
        let request = Task { await support.flush() }
        for _ in 0..<100 {
            if await transport.started { break }
            try await Task.sleep(for: .milliseconds(2))
        }
        #expect(await transport.started)
        support.setLevel(.off)
        await request.value
        #expect(await transport.cancelled)
        #expect(support.telemetryPayload().events.isEmpty)
    }

    @Test func diagnosticsAreBoundedExpireAndUseRelativeMinuteAges() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let clock = SupportTestClock()
        let support = AppSupport(defaults: defaults, transport: RecordingSupportTransport(), now: { clock.date }, automaticallyFlush: false)
        for _ in 0..<130 { support.record(.cameraError) }
        #expect(support.diagnostics.count == 80)
        clock.date.addTimeInterval(125)
        let report = support.diagnosticReport()
        #expect(report.events.allSatisfy { $0.ageSeconds == 120 })
        #expect(!report.preview.contains("recordedAt"))
        clock.date.addTimeInterval(8 * 24 * 60 * 60)
        #expect(support.diagnosticReport().events.isEmpty)
        support.record(.appOpen)
        support.clearDiagnostics()
        #expect(support.diagnostics.isEmpty)
    }

    @Test func telemetryCountIsBoundedAndFailedRequestsAreNotRetained() async {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport(fail: true)
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        for _ in 0..<150 { support.record(.appOpen) }
        #expect(support.telemetryPayload().events.first?.count == 100)
        await support.flush()
        await support.flush()
        #expect(await transport.telemetryRequests.count == 1)
    }

    @Test func feedbackOmitsUnselectedLogsAndContactAndCanBeSentWithTelemetryOff() async throws {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport()
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        support.setLevel(.off)
        support.record(.cameraError)
        let id = UUID()
        let payload = try FeedbackPayload(submissionId: id, category: .bug, message: "  Camera didn't start  ", contactEmail: " ", diagnostics: nil)
        let dictionary = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])
        #expect(dictionary["diagnostics"] == nil)
        #expect(dictionary["contactEmail"] == nil)
        #expect(dictionary["source"] as? String == "ios")
        #expect(payload.message == "Camera didn't start")
        _ = try await support.sendFeedback(payload)
        _ = try await support.sendFeedback(payload)
        #expect(await transport.feedbackRequests.map(\.submissionId) == [id, id])
        #expect(await transport.telemetryRequests.isEmpty)
    }

    @Test func feedbackValidationRejectsBlankOversizedAndMalformedContact() {
        #expect(throws: SupportError.self) { try FeedbackPayload(category: .idea, message: " \n ", contactEmail: "", diagnostics: nil) }
        #expect(throws: SupportError.self) { try FeedbackPayload(category: .idea, message: String(repeating: "a", count: 4_001), contactEmail: "", diagnostics: nil) }
        #expect(throws: SupportError.self) { try FeedbackPayload(category: .idea, message: "An idea", contactEmail: "someone", diagnostics: nil) }
        #expect(throws: SupportError.self) { try FeedbackPayload(category: .bug, message: "A pasted\u{0000}control code", contactEmail: "", diagnostics: nil) }
        #expect(throws: Never.self) { try FeedbackPayload(category: .idea, message: "A note\nwith a new line\tand a tab", contactEmail: "", diagnostics: nil) }
    }

    @Test func unknownStoredPrivacyLevelFailsClosed() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("unexpected", forKey: "journey.telemetry.level")
        let support = AppSupport(defaults: defaults, transport: RecordingSupportTransport(), automaticallyFlush: false)
        #expect(support.level == .off)
    }

    @Test func setupGateDiscardsPreSetupEventsBeforeAnyUpload() async throws {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport()
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        support.activateAfterSetup()
        support.record(.cameraError)
        await support.flush()
        #expect(!support.hasAcknowledgedReporting)
        #expect(await transport.telemetryRequests.isEmpty)
        #expect(support.telemetryPayload().events.isEmpty)
        activate(support)
        support.record(.appOpen)
        await support.flush()
        let sent = try #require(await transport.telemetryRequests.first)
        #expect(sent.events == [.init(name: .appOpen, count: 1)])
    }

    @Test func fullWirePayloadContainsOnlyDocumentedMetadata() async throws {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let transport = RecordingSupportTransport()
        let support = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        activate(support)
        support.record(.portraitSaved)
        await support.flush()
        let payload = try #require(await transport.telemetryRequests.first)
        let dictionary = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])
        #expect(Set(dictionary.keys) == ["batchId", "mode", "events", "installationId", "appVersion", "osVersion", "deviceClass"])
        #expect(payload.installationId == support.installationID)
        #expect(payload.mode == .full)
    }

    @Test func corruptStoredIdentifierIsReplacedWithAValidRandomIdentifier() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("invalid", forKey: "journey.telemetry.id")
        let support = AppSupport(defaults: defaults, transport: RecordingSupportTransport(), automaticallyFlush: false)
        #expect(support.installationID.flatMap(UUID.init(uuidString:)) != nil)
        #expect(support.installationID == defaults.string(forKey: "journey.telemetry.id"))
    }

    @Test func acknowledgementSurvivesRelaunchButStillWaitsForSetupActivation() async {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = AppSupport(defaults: defaults, transport: RecordingSupportTransport(), automaticallyFlush: false)
        #expect(!first.hasAcknowledgedReporting)
        first.setLevel(.limited)
        first.acknowledgeReporting()
        let transport = RecordingSupportTransport()
        let restored = AppSupport(defaults: defaults, transport: transport, automaticallyFlush: false)
        #expect(restored.hasAcknowledgedReporting)
        #expect(restored.level == .limited)
        restored.record(.cameraError)
        await restored.flush()
        #expect(await transport.telemetryRequests.isEmpty)
        restored.activateAfterSetup()
        restored.record(.appOpen)
        await restored.flush()
        #expect(await transport.telemetryRequests.first?.events == [.init(name: .appOpen, count: 1)])
    }
}

@MainActor private final class SupportTestClock {
    var date = Date(timeIntervalSince1970: 1_800_000_000)
}

private actor RecordingSupportTransport: SupportTransport {
    var telemetryRequests: [TelemetryPayload] = []
    var feedbackRequests: [FeedbackPayload] = []
    var started = false
    var cancelled = false
    let delay: Bool
    let fail: Bool
    init(delay: Bool = false, fail: Bool = false) { self.delay = delay; self.fail = fail }
    func feedback(_ payload: FeedbackPayload) async throws -> String {
        feedbackRequests.append(payload)
        if fail { throw SupportError.unavailable }
        return payload.submissionId.uuidString
    }
    func telemetry(_ payload: TelemetryPayload) async throws {
        telemetryRequests.append(payload)
        started = true
        if delay {
            do { try await Task.sleep(for: .seconds(30)) }
            catch { cancelled = true; throw error }
        }
        if fail { throw SupportError.unavailable }
    }
}
