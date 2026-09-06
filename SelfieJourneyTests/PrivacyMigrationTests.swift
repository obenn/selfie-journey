import Foundation
import Testing
@testable import SelfieJourney

@MainActor
struct PrivacyMigrationTests {
    @Test func upgradingClearsReportingDataAndPreservesJourneyPreferences() throws {
        let suite = "journey-privacy-tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let retiredKeys = ["journey.telemetry.level", "journey.telemetry.id",
                           "journey.telemetry.disclosureVersion", "journey.support.diagnostics"]
        for key in retiredKeys { defaults.set("old reporting value", forKey: key) }
        defaults.set("wide", forKey: "journey.portraitPose")
        defaults.set(true, forKey: "journey.onboardingComplete")
        defaults.set(Data([1, 2, 3]), forKey: "unrelated.saved.value")

        PrivacyMigration.removeLegacyReportingData(from: defaults)
        PrivacyMigration.removeLegacyReportingData(from: defaults)

        for key in retiredKeys { #expect(defaults.object(forKey: key) == nil) }
        let preferences = JourneyPreferences(defaults: defaults)
        #expect(preferences.selectedPose == .wide)
        #expect(preferences.hasCompletedOnboarding)
        #expect(defaults.data(forKey: "unrelated.saved.value") == Data([1, 2, 3]))
    }
}
