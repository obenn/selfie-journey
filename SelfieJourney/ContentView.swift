import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Portrait.date, order: .reverse) private var portraits: [Portrait]
    @State private var reminders = ReminderManager()
    @State private var preferences = JourneyPreferences()
    @State private var backup = CloudBackupManager()
    @State private var support = AppSupport.shared
    @State private var selection = 0
    @State private var showingCamera = false
    @State private var showingSettings = false
    @State private var saveCelebration = false
    @State private var savedStreak = 0
    @State private var savedRetake = false
    @State private var reminderError: String?
    @State private var hasReportedCurrentSession = false

    var body: some View {
        Group {
            if preferences.hasCompletedOnboarding {
                journey
            } else {
                OnboardingView(reminders: reminders, preferences: preferences, support: support) {
                    reportSessionIfReady()
                    Task { await refreshRitual() }
                }
            }
        }
        .tint(JourneyTheme.accent)
        .sheet(isPresented: Binding(
            get: { preferences.hasCompletedOnboarding && !support.hasAcknowledgedReporting },
            set: { _ in }
        )) {
            ReportingWelcomeView(support: support) {
                support.acknowledgeReporting()
                reportSessionIfReady()
            }
        }
        .task {
            reportSessionIfReady()
            await refreshRitual()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                reportSessionIfReady()
                Task { await refreshRitual() }
            } else if phase == .background {
                hasReportedCurrentSession = false
            }
        }
        .onChange(of: collectionRevision) { _, _ in
            Task { await refreshRitual() }
        }
        .alert("Reminder needs attention", isPresented: Binding(
            get: { reminderError != nil }, set: { if !$0 { reminderError = nil } }
        )) { Button("OK", role: .cancel) {} } message: {
            Text(reminderError ?? "")
        }
    }

    private var journey: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sun.max", value: 0) {
                TodayView(portraits: portraits, reminders: reminders,
                          onCapture: { showingCamera = true },
                          onSettings: { showingSettings = true },
                          onLookback: { selection = 2 })
            }
            Tab("Journal", systemImage: "square.stack", value: 1) {
                LibraryView(portraits: portraits, onCapture: { showingCamera = true })
            }
            Tab("Lookback", systemImage: "play.rectangle", value: 2) {
                LookbackView(portraits: portraits, onCapture: { showingCamera = true })
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CaptureView(referenceImage: portraits.first(where: {
                $0.poseRawValue == preferences.selectedPose.rawValue
            })?.image, pose: preferences.selectedPose, onSave: savePortrait)
        }
        .sheet(isPresented: $showingSettings) {
            RitualSettingsView(reminders: reminders, portraitDates: portraits.map(\.date),
                               preferences: preferences, backup: backup, support: support)
        }
        .overlay(alignment: .top) {
            if saveCelebration && !showingCamera {
                StreakCelebrationView(streak: savedStreak, isRetake: savedRetake)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: showingCamera) { _, showing in
            if showing { support.record(.cameraOpened) }
            if !showing && saveCelebration {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(reduceMotion ? nil : .easeOut) { saveCelebration = false }
                }
            }
        }
    }

    /// Scalar metadata also catches retakes, notes, and deletions without loading photo bytes.
    private var collectionRevision: [String] {
        portraits.map { "\($0.id)|\($0.imageRevision)|\($0.date.timeIntervalSince1970)|\($0.note)|\($0.poseRawValue)" }
    }

    private func savePortrait(_ image: UIImage, _ note: String) throws {
        let data = try PortraitImageProcessor.jpegData(from: image)
        savedRetake = portraits.contains { Calendar.current.isDateInToday($0.date) }
        let saved = try PortraitStore.save(imageData: data, note: note, pose: preferences.selectedPose, context: modelContext)
        support.record(savedRetake ? .portraitRetake : .portraitSaved)
        let dates = portraits.filter { $0.id != saved.id }.map(\.date) + [saved.date]
        savedStreak = StreakCalculator.currentStreak(dates: dates)
        selection = 0
        withAnimation(reduceMotion ? nil : .spring) { saveCelebration = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func refreshRitual() async {
        guard preferences.hasCompletedOnboarding else { return }
        await reminders.refreshAuthorization()
        do { try await reminders.syncPortraitDates(portraits.map(\.date)) }
        catch { reminderError = error.localizedDescription }
        await backup.refresh()
        await backup.backUp(portraits)
    }

    private func reportSessionIfReady() {
        guard preferences.hasCompletedOnboarding, support.hasAcknowledgedReporting else { return }
        support.activateAfterSetup()
        guard !hasReportedCurrentSession else { return }
        hasReportedCurrentSession = true
        support.record(.appOpen)
    }
}

#Preview {
    ContentView().modelContainer(try! ModelContainer(for: Portrait.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)))
}
