import Foundation

enum PrivacyMigration {
    /// Earlier builds stored reporting preferences, an installation identifier,
    /// and a small diagnostic timeline. Remove only those retired values so an
    /// upgrade preserves the journal, portrait frame, reminders, and backups.
    static func removeLegacyReportingData(from defaults: UserDefaults = .standard) {
        for key in [
            "journey.telemetry.level",
            "journey.telemetry.id",
            "journey.telemetry.disclosureVersion",
            "journey.support.diagnostics"
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}
