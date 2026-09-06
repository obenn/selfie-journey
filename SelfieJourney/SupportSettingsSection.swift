import SwiftUI

struct SupportSettingsSection: View {
    let support: AppSupport
    let onFeedback: () -> Void
    @State private var confirmClear = false
    @State private var confirmReset = false

    var body: some View {
        Section {
            Button("Send app feedback", systemImage: "text.bubble") {
                support.record(.feedbackOpened)
                onFeedback()
            }.accessibilityIdentifier("settings.feedback")
            NavigationLink {
                reportingSettings
            } label: {
                LabeledContent("Usage & reliability", value: support.level.title)
            }.accessibilityIdentifier("settings.telemetry")
        } header: { Text("A BETTER JOURNEY, TOGETHER") } footer: {
            Text("You're in control of what you share. Feedback is always your choice; automatic reporting can be Full, Limited, or Off.")
        }
    }

    private var reportingSettings: some View {
        Form {
            Section {
                TelemetryChoiceView(support: support)
            } header: { Text("AUTOMATIC REPORTING") } footer: {
                Text("Changes take effect immediately. Off cancels queued and in-flight reports. Data already received follows the retention periods below. Photos, journal content, face tracking data, and precise dates are never included.")
            }
            if support.level == .full {
                Section {
                    Button("Reset reporting identifier", systemImage: "arrow.trianglehead.2.clockwise") { confirmReset = true }
                } footer: {
                    Text("A new random identifier stops future reports being grouped with the old one. This doesn't delete reports already received.")
                }
            }
            Section {
                Button("Clear local diagnostic logs", systemImage: "trash", role: .destructive) { confirmClear = true }
            } header: { Text("ON THIS DEVICE") } footer: {
                    Text("Up to 80 safe event codes are kept locally for seven days to help troubleshoot issues. This local timeline leaves your device only if you attach it to feedback; automatic reporting sends event totals separately. Clearing logs doesn't change your reporting preference.")
            }
            Section {
                Link("Read our privacy policy", destination: URL(string: "https://selfiejourney.com/privacy")!)
            } footer: {
                Text("Full reporting details are retained for 30 days. Anonymous daily totals are retained for up to 365 days. Feedback is retained for 180 days and attached diagnostic logs for 30 days. Network providers process connection information when delivering a request; it isn't added to our analytics database.")
            }
        }
        .scrollContentBackground(.hidden).background(JourneyTheme.background)
        .navigationTitle("Usage & reliability").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear the local diagnostic history?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear logs", role: .destructive) { support.clearDiagnostics() }
        }
        .confirmationDialog("Start with a new reporting identifier?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset identifier") { support.resetIdentifier() }
        }
    }
}

struct TelemetryChoiceView: View {
    let support: AppSupport
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Reporting level", selection: Binding(get: { support.level }, set: { support.setLevel($0) })) {
                ForEach(TelemetryLevel.allCases) { level in Text(level.title).tag(level) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("settings.telemetryLevel")
            Text(support.level.detail)
                .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 5)
    }
}
