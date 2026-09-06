import Foundation
import Testing
@testable import SelfieJourney

@MainActor
struct JourneyPreferencesTests {
    @Test func firstLaunchUsesClassicPoseAndNeedsSetup() throws {
        let suite = "journey-tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = JourneyPreferences(defaults: defaults)
        #expect(preferences.selectedPose == .classic)
        #expect(!preferences.hasCompletedOnboarding)
    }

    @Test func poseAndCompletedSetupSurviveRecreatingPreferences() throws {
        let suite = "journey-tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = JourneyPreferences(defaults: defaults)
        first.selectedPose = .wide
        first.hasCompletedOnboarding = true

        let restored = JourneyPreferences(defaults: defaults)
        #expect(restored.selectedPose == .wide)
        #expect(restored.hasCompletedOnboarding)
    }

    @Test func unrecognizedStoredPoseRecoversWithoutResettingCompletedSetup() throws {
        let suite = "journey-tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("future-pose", forKey: "journey.portraitPose")
        defaults.set(true, forKey: "journey.onboardingComplete")

        let preferences = JourneyPreferences(defaults: defaults)
        #expect(preferences.selectedPose == .classic)
        #expect(preferences.hasCompletedOnboarding)
    }

    @Test func poseTargetsStayWithinViewfinderAndStepDownInDistance() {
        let poses = PortraitPose.allCases
        #expect(poses.count == 4)
        #expect(zip(poses, poses.dropFirst()).allSatisfy { $0.faceHeight > $1.faceHeight && $0.faceWidth > $1.faceWidth })
        for pose in poses {
            #expect(pose.centerY - pose.faceHeight / 2 > 0)
            #expect(pose.centerY + pose.faceHeight / 2 < 1)
            #expect(pose.eyeLineY > pose.centerY - pose.faceHeight / 2)
            #expect(pose.eyeLineY < pose.centerY)
            #expect(pose.faceWidth > 0 && pose.faceWidth < 1)
        }
    }
}
