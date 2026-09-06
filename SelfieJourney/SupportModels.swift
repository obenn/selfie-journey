import Foundation

nonisolated enum TelemetryLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case off, limited, full
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var detail: String {
        switch self {
        case .off: "No automatic usage or reliability reports leave this device. You can still send feedback and choose to attach local logs."
        case .limited: "Send anonymous totals for app opens, saves, exports, and fixed error codes. No installation identifier or device details."
        case .full: "Send those totals with a random installation identifier, app version, iOS version, and iPhone or iPad device class. This helps us understand reliability over time."
        }
    }
}

/// The only data accepted by the automatic diagnostics recorder. Never add
/// arbitrary strings, file paths, portrait metadata, or error descriptions here.
nonisolated enum SupportEvent: String, Codable, CaseIterable, Sendable {
    case appOpen = "app_open"
    case portraitSaved = "portrait_saved"
    case portraitRetake = "portrait_retake"
    case cameraOpened = "camera_opened"
    case cameraError = "camera_error"
    case backupError = "backup_error"
    case backupCompleted = "backup_completed"
    case exportCompleted = "export_completed"
    case exportError = "export_error"
    case feedbackOpened = "feedback_opened"
}

nonisolated struct LocalDiagnostic: Codable, Sendable {
    let code: SupportEvent
    let recordedAt: Date
}

nonisolated struct DiagnosticReport: Codable, Equatable, Sendable {
    struct Event: Codable, Equatable, Sendable {
        let code: SupportEvent
        /// Rounded to a minute. The local absolute timestamp never leaves the device.
        let ageSeconds: Int
    }
    let appVersion: String
    let osVersion: String
    let deviceClass: String
    let events: [Event]

    var preview: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}

nonisolated struct TelemetryPayload: Codable, Equatable, Sendable {
    struct Event: Codable, Equatable, Sendable { let name: SupportEvent; let count: Int }
    let batchId: UUID
    let mode: TelemetryLevel
    let events: [Event]
    let appVersion: String?
    let osVersion: String?
    let deviceClass: String?
    let installationId: String?
}

nonisolated enum FeedbackCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case bug, idea, other
    var id: String { rawValue }
    var title: String {
        switch self { case .bug: "Something isn't working"; case .idea: "An idea for the journey"; case .other: "Something else" }
    }
}

nonisolated struct FeedbackPayload: Encodable, Equatable, Sendable {
    let submissionId: UUID
    let source = "ios"
    let category: FeedbackCategory
    let message: String
    let contactEmail: String?
    let diagnostics: DiagnosticReport?

    init(submissionId: UUID = UUID(), category: FeedbackCategory, message: String, contactEmail: String, diagnostics: DiagnosticReport?) throws {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, message.utf16.count <= 4_000,
              !message.unicodeScalars.contains(where: { (0...8).contains($0.value) || (11...12).contains($0.value) || (14...31).contains($0.value) }) else {
            throw SupportError.invalidMessage
        }
        guard email.isEmpty || (email.utf16.count <= 254 && email.range(of: "^[^\\s@<>]+@[^\\s@<>]+\\.[^\\s@<>]+$", options: .regularExpression) != nil) else {
            throw SupportError.invalidEmail
        }
        self.submissionId = submissionId
        self.category = category
        self.message = message
        self.contactEmail = email.isEmpty ? nil : email
        self.diagnostics = diagnostics
    }
}

nonisolated enum SupportError: LocalizedError {
    case invalidMessage, invalidEmail, unavailable, rateLimited, response, testing
    var errorDescription: String? {
        switch self {
        case .invalidMessage: "Please write between 1 and 4,000 characters."
        case .invalidEmail: "Check your email address, or leave it empty to send without a reply address."
        case .unavailable: "We couldn't reach Selfie Journey. Your message is still here. Check your connection and try again."
        case .rateLimited: "Please wait a little before trying again. Your message is still here."
        case .response: "We couldn't confirm delivery. Your message is still here. Please try again."
        case .testing: "Sending is disabled in automated tests."
        }
    }
}
