import SwiftUI

struct FeedbackView: View {
    let support: AppSupport
    @Environment(\.dismiss) private var dismiss
    @State private var category: FeedbackCategory = .idea
    @State private var message = ""
    @State private var email = ""
    @State private var includeLogs = false
    @State private var report: DiagnosticReport?
    @State private var submissionID = UUID()
    @State private var sending = false
    @State private var receipt: String?
    @State private var errorMessage: String?
    @State private var sendTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if let receipt { thankYou(receipt) }
                else { editor }
            }
            .navigationTitle("A note to Selfie Journey").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(receipt == nil ? "Close" : "Done") { dismiss() }.disabled(sending)
                }
                if receipt == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") { send() }
                            .fontWeight(.semibold)
                            .disabled(sending || !validDraft)
                            .accessibilityIdentifier("feedback.send")
                    }
                }
            }
            .tint(JourneyTheme.accent)
            .foregroundStyle(JourneyTheme.ink)
            .interactiveDismissDisabled(sending)
            .onDisappear { sendTask?.cancel() }
            .onChange(of: message) { _, _ in resetSubmission() }
            .onChange(of: email) { _, _ in resetSubmission() }
            .onChange(of: category) { _, _ in resetSubmission() }
            .onChange(of: includeLogs) { _, included in
                report = included ? support.diagnosticReport() : nil
                resetSubmission()
            }
        }
    }

    private var editor: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 9) {
                    Image(systemName: "text.bubble").font(.system(size: 34, weight: .light)).foregroundStyle(JourneyTheme.accent)
                    Text("Help shape the journey.").font(JourneyTheme.serif(29)).tracking(-0.7)
                    Text("A small idea or something that got in the way—we'd love to hear it.")
                        .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                }.padding(.vertical, 8).listRowBackground(Color.clear)
            }
            Section("YOUR NOTE") {
                Picker("About", selection: $category) {
                    ForEach(FeedbackCategory.allCases) { value in Text(value.title).tag(value) }
                }
                TextEditor(text: $message)
                    .frame(minHeight: 155)
                    .accessibilityLabel("Your feedback")
                    .accessibilityIdentifier("feedback.message")
                Text("\(message.utf16.count) / 4,000")
                    .font(.caption).foregroundStyle(message.utf16.count > 4_000 ? .red : JourneyTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                TextField("Email for a reply (optional)", text: $email)
                    .textContentType(.emailAddress).keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("feedback.email")
            }
            .disabled(sending)
            Section {
                Toggle("Attach local diagnostic logs", isOn: $includeLogs)
                    .accessibilityIdentifier("feedback.includeLogs")
                if let report, includeLogs {
                    NavigationLink {
                        DiagnosticPreviewView(report: report)
                    } label: {
                        Label("Preview the exact logs", systemImage: "doc.text.magnifyingglass")
                    }.accessibilityIdentifier("feedback.previewLogs")
                    Button("Refresh log preview", systemImage: "arrow.clockwise") {
                        self.report = support.diagnosticReport()
                        resetSubmission()
                    }
                }
            } header: { Text("HELP WITH A TECHNICAL ISSUE") } footer: {
                Text("Optional logs contain up to 80 fixed event codes from the last seven days, their relative age, and basic app and device details. No portraits, journal notes, face data, file paths, or raw error messages. You can attach them even when automatic reporting is Off.")
            }
            .disabled(sending)
            if sending {
                Section {
                    HStack { ProgressView(); Text("Sending your note…").padding(.leading, 8) }
                    Button("Cancel sending", role: .cancel) { sendTask?.cancel() }
                }
            }
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.bubble")
                        .font(.subheadline).foregroundStyle(JourneyTheme.accent)
                        .accessibilityIdentifier("feedback.error")
                }
            }
            Section {
                Link("Privacy policy", destination: URL(string: "https://selfiejourney.com/privacy")!)
            } footer: {
                Text("Sending shares your note, optional email, and only the logs you chose with Selfie Journey. Avoid including private details in your message. Feedback is retained for 180 days; attached logs for 30 days.")
            }
        }
        .scrollContentBackground(.hidden).background(JourneyTheme.background)
    }

    private var validDraft: Bool {
        (try? FeedbackPayload(submissionId: submissionID, category: category, message: message, contactEmail: email, diagnostics: nil)) != nil
    }

    private func resetSubmission() {
        submissionID = UUID()
        errorMessage = nil
    }

    private func send() {
        guard !sending else { return }
        do {
            let payload = try FeedbackPayload(submissionId: submissionID, category: category, message: message,
                                              contactEmail: email, diagnostics: includeLogs ? report : nil)
            sending = true
            errorMessage = nil
            sendTask = Task {
                defer { sending = false; sendTask = nil }
                do {
                    receipt = try await support.sendFeedback(payload)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch is CancellationError {
                    errorMessage = "Sending stopped. Your draft is still here. If it already arrived, retrying this unchanged note won't create a duplicate."
                } catch {
                    errorMessage = (error as? SupportError)?.errorDescription ?? SupportError.unavailable.errorDescription
                }
            }
        } catch { errorMessage = (error as? SupportError)?.errorDescription }
    }

    private func thankYou(_ receipt: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.bubble").font(.system(size: 56, weight: .ultraLight)).foregroundStyle(JourneyTheme.accent)
            Text("A little better, together.").font(JourneyTheme.serif(33)).multilineTextAlignment(.center)
            Text("Your note has arrived. Thank you for helping Selfie Journey grow.")
                .foregroundStyle(JourneyTheme.secondary).multilineTextAlignment(.center)
            VStack(spacing: 6) {
                Text("YOUR REFERENCE").font(.caption2.weight(.semibold)).tracking(1.4)
                Text(receipt).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }.foregroundStyle(JourneyTheme.secondary).padding(.top, 8)
        }
        .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JourneyTheme.background)
        .accessibilityIdentifier("feedback.success")
    }
}

struct DiagnosticPreviewView: View {
    let report: DiagnosticReport
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Exactly what will be attached.").font(JourneyTheme.serif(29))
                Text("Times are rounded to minutes before sending. The preview stays fixed until you refresh it.")
                    .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                Text(report.preview).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(24)
        }
        .background(JourneyTheme.background).foregroundStyle(JourneyTheme.ink)
        .navigationTitle("Diagnostic preview").navigationBarTitleDisplayMode(.inline)
    }
}
