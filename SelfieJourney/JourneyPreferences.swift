import Foundation
import Observation

@Observable
@MainActor
final class JourneyPreferences {
    var selectedPose: PortraitPose {
        didSet { defaults.set(selectedPose.rawValue, forKey: Keys.pose) }
    }
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboardingComplete) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let pose = "journey.portraitPose"
        static let onboardingComplete = "journey.onboardingComplete"
    }

    #if DEBUG
    private static var didResetUITestDefaults = false
    #endif

    init(defaults: UserDefaults? = nil) {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--uitesting")
        let skipOnboarding = isUITesting && !arguments.contains("--onboarding")
        #else
        let isUITesting = false
        let skipOnboarding = false
        #endif
        let storage = defaults ?? (isUITesting
            ? UserDefaults(suiteName: "com.selfiejourney.ui-testing.preferences")!
            : .standard)
        #if DEBUG
        if defaults == nil, isUITesting, arguments.contains("--reset-onboarding"), !Self.didResetUITestDefaults {
            // Reset only the isolated test suite, once per launch. Recreating
            // this object during the same run must preserve completed setup.
            storage.removePersistentDomain(forName: "com.selfiejourney.ui-testing.preferences")
            Self.didResetUITestDefaults = true
        }
        #endif
        self.defaults = storage
        selectedPose = storage.string(forKey: Keys.pose).flatMap(PortraitPose.init(rawValue:)) ?? .classic
        // An explicit defaults argument always uses its own persisted state.
        // Test mode never clears preferences during view/store recreation.
        hasCompletedOnboarding = storage.bool(forKey: Keys.onboardingComplete)
            || (defaults == nil && skipOnboarding)
    }
}
