import SwiftUI
import UserNotifications

struct RitualSettingsView: View {
    let reminders: ReminderManager
    let portraitDates: [Date]
    let preferences: JourneyPreferences
    let backup: CloudBackupManager
    let support: AppSupport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var enabled = false
    @State private var time = Date()
    @State private var saving = false
    @State private var errorMessage: String?
    @State private var showingGuide = false
    @State private var showingFeedback = false
    @State private var selectedPose: PortraitPose = .classic
    @State private var didLoadPreferences = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "sun.horizon").font(.system(size: 38, weight: .ultraLight)).foregroundStyle(JourneyTheme.accent)
                        Text("A small ritual.\nA remarkable story.").font(JourneyTheme.serif(32)).tracking(-0.7)
                        Text("After your coffee. Before you head out. Find a moment that's already yours.")
                            .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                    }.padding(.vertical, 12).listRowBackground(Color.clear)
                }
                Section {
                    Toggle("A gentle daily reminder", isOn: $enabled)
                        .accessibilityIdentifier("settings.reminderToggle")
                    if enabled {
                        DatePicker("Your moment", selection: $time, displayedComponents: .hourAndMinute)
                            .accessibilityIdentifier("settings.reminderTime")
                    }
                    if reminders.authorizationStatus == .denied {
                        Button("Allow notifications in Settings", systemImage: "arrow.up.right") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                } header: { Text("YOUR DAILY RHYTHM") } footer: {
                    Text("We'll skip today's reminder once you've taken your portrait. Reminders are prepared for the next 30 days and renewed whenever you open Selfie Journey.")
                }
                Section {
                    NavigationLink {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 22) {
                                Text("A familiar frame,\nevery day.")
                                    .font(JourneyTheme.serif(33)).tracking(-0.8)
                                Text("Choose how much of you fills the portrait. Your viewfinder and live positioning advice will follow this frame.")
                                    .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                                PoseSelectionView(selection: $selectedPose)
                                Label("For the smoothest lookback, stick with the same frame and a familiar spot.", systemImage: "sparkles")
                                    .font(.footnote).foregroundStyle(JourneyTheme.secondary)
                            }
                            .padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
                        }
                        .background(JourneyTheme.background)
                        .navigationTitle("Your portrait frame").navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack(spacing: 15) {
                            PoseIllustration(pose: selectedPose, selected: true)
                                .frame(width: 49, height: 63)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(selectedPose.title).font(.headline)
                                Text(selectedPose.subtitle).font(.caption).foregroundStyle(JourneyTheme.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("settings.pose")
                } header: { Text("YOUR SIGNATURE PORTRAIT") } footer: {
                    Text("Four distances, one consistent guide. Face tracking and light checks happen on your device while the camera is open.")
                }
                CloudBackupSection(backup: backup)
                SupportSettingsSection(support: support) { showingFeedback = true }
                Section("MAKE IT FEEL EFFORTLESS") {
                    Label("Same light. A familiar spot.", systemImage: "sun.max")
                    Label("Eyes on the guide. Shoulders relaxed.", systemImage: "person.crop.rectangle")
                    Label("A missed day is just a day. Keep going.", systemImage: "heart")
                    Button("A guide to your daily portrait", systemImage: "book.closed") { showingGuide = true }
                }
                Section {
                    LabeledContent("Portraits kept", value: "\(portraitDates.count)")
                    LabeledContent("Longest streak", value: "\(StreakCalculator.longestStreak(dates: portraitDates)) days")
                    Label("Your private portrait collection", systemImage: "lock.shield")
                } header: { Text("YOUR STORY, YOURS TO KEEP") } footer: {
                    Text("Face and lighting analysis stays on your device. Backups use your personal iCloud Drive. Face guidance doesn't identify you. Export a film or share portraits anytime. Deleting the app removes its local journal; completed iCloud backups can restore missing days.")
                }
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Text("Selfie Journey").font(.system(size: 22, weight: .semibold, design: .rounded)).tracking(-0.7)
                            Text("A little, every day.  ·  Version 1.0").font(.caption2).foregroundStyle(JourneyTheme.secondary)
                        }
                        Spacer()
                    }.listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden).background(JourneyTheme.background)
            .foregroundStyle(JourneyTheme.ink).tint(JourneyTheme.accent)
            .navigationTitle("Your daily ritual").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Task { await save() } }.fontWeight(.semibold).disabled(saving)
                        .accessibilityIdentifier("settings.done")
                }
            }
            .onAppear {
                guard !didLoadPreferences else { return }
                didLoadPreferences = true
                enabled = reminders.enabled
                time = reminders.date
                selectedPose = preferences.selectedPose
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await reminders.refreshAuthorization() } }
            }
            .sheet(isPresented: $showingGuide) { PortraitGuideView() }
            .sheet(isPresented: $showingFeedback) { FeedbackView(support: support) }
            .alert(errorMessage == nil ? "iCloud backup" : "Couldn't update your reminder", isPresented: Binding(
                get: { errorMessage != nil || backup.errorMessage != nil || backup.restorationMessage != nil },
                set: { if !$0 { clearMessages() } }
            )) {
                Button("OK", role: .cancel) { clearMessages() }
            } message: { Text(errorMessage ?? backup.errorMessage ?? backup.restorationMessage ?? "") }
            .interactiveDismissDisabled(saving)
        }
    }

    private func clearMessages() {
        errorMessage = nil
        backup.errorMessage = nil
        backup.restorationMessage = nil
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            try await reminders.syncPortraitDates(portraitDates)
            try await reminders.setReminder(enabled: enabled, time: time)
            preferences.selectedPose = selectedPose
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}

struct PortraitGuideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Just as you are.").font(JourneyTheme.serif(38)).tracking(-1)
                    Text("You don't need a perfect portrait. A little consistency is what makes your lookback magical.")
                        .foregroundStyle(JourneyTheme.secondary)
                    tip("01", "Find your light", "Face a window, with the light in front of you. A simple background lets you be the story.", "sun.max")
                    tip("02", "Meet the guide", "Pick your favorite framing distance in Your daily ritual. Hold your phone at eye level, center your face in the oval, and rest your eyes along the dotted line. Live hints help with distance, position, head angle, and light.", "viewfinder")
                    tip("03", "Echo yesterday", "After your first portrait, turn on the ghost overlay. Match your eyes and shoulders to your previous photo.", "square.on.square")
                    tip("04", "Take a breath", "Use the three-second timer, relax your shoulders, and look into the lens. There's no need to smile unless you feel like it.", "timer")
                    Text("Let the years change you. Keep this little moment the same.")
                        .font(JourneyTheme.serif(25)).italic().padding(.top, 12)
                }.padding(27).frame(maxWidth: 560)
            }
            .frame(maxWidth: .infinity).background(JourneyTheme.background).foregroundStyle(JourneyTheme.ink)
            .navigationTitle("The portrait guide").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.tint(JourneyTheme.accent)
    }
    private func tip(_ number: String, _ title: String, _ text: String, _ symbol: String) -> some View {
        HStack(alignment: .top, spacing: 17) {
            Text(number).font(.system(.caption, design: .monospaced)).foregroundStyle(JourneyTheme.accent).padding(.top, 5)
            VStack(alignment: .leading, spacing: 7) {
                Label(title, systemImage: symbol).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(JourneyTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
