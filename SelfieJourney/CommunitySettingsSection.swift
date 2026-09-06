import SwiftUI

struct CommunitySettingsSection: View {
    var body: some View {
        Section {
            Link(destination: URL(string: "https://github.com/obenn/selfie-journey/issues")!) {
                Label("Suggest a change or report a bug", systemImage: "bubble.left.and.bubble.right")
            }
            .accessibilityIdentifier("settings.githubIssues")
            Link(destination: URL(string: "https://github.com/obenn/selfie-journey")!) {
                Label("Selfie Journey on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .accessibilityIdentifier("settings.githubRepository")
        } header: {
            Text("HELP SHAPE SELFIE JOURNEY")
        } footer: {
            Text("Have an idea for your daily ritual? We'd love to hear it on GitHub. These links open in your browser. Issues are public, so share only what you'd like others to see. The app attaches no logs or personal data.")
        }

        Section {
            Label("No data collected", systemImage: "hand.raised")
            Link("Privacy policy", destination: URL(string: "https://selfiejourney.com/privacy/")!)
        } header: {
            Text("PRIVATE BY DESIGN")
        } footer: {
            Text("No analytics, tracking, or diagnostic uploads. Face guidance runs on your device. Your portraits and notes stay on your device and in your personal iCloud Drive backups. Completely free, with no subscriptions.")
        }
    }
}
