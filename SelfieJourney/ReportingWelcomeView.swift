import SwiftUI

/// Existing journals see this once when reporting is introduced or its
/// disclosure changes. New journals make the same choice during onboarding.
struct ReportingWelcomeView: View {
    let support: AppSupport
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "hand.raised.heart")
                        .font(.system(size: 45, weight: .ultraLight))
                        .foregroundStyle(JourneyTheme.accent)
                    Text("A better journey,\non your terms.")
                        .font(JourneyTheme.serif(36)).tracking(-0.8)
                        .accessibilityIdentifier("reporting.disclosure")
                    Text("You can now send feedback and help us improve Selfie Journey with usage and reliability reports.")
                        .foregroundStyle(JourneyTheme.secondary)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CHOOSE WHAT YOU SHARE")
                            .font(.caption.weight(.semibold)).tracking(1.5)
                        TelemetryChoiceView(support: support)
                    }
                    .padding(20)
                    .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                    Text("Full is the default. Your portraits, journal content, and face tracking data are never included. Reporting starts after you continue; change this anytime in Settings.")
                        .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                    Link("Privacy policy", destination: URL(string: "https://selfiejourney.com/privacy")!)
                        .font(.subheadline)
                }
                .padding(26).frame(maxWidth: 540).frame(maxWidth: .infinity)
            }
            .background(JourneyTheme.background)
            .foregroundStyle(JourneyTheme.ink)
            .navigationTitle("Your privacy choices").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Continue", symbol: "checkmark", action: onContinue)
                    .accessibilityIdentifier("reporting.continue")
                    .padding(24).background(JourneyTheme.background)
            }
        }
        .tint(JourneyTheme.accent)
        .interactiveDismissDisabled()
        .presentationDetents([.large])
    }
}
