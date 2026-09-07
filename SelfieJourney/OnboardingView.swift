import SwiftUI
import UserNotifications

struct OnboardingView: View {
    let reminders: ReminderManager
    @Bindable var preferences: JourneyPreferences
    let onComplete: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var reminderTime = Date()
    @State private var saving = false
    @State private var permissionDeclined = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                Group {
                    switch step {
                    case 0: welcome
                    case 1: poseSetup
                    default: reminderSetup
                    }
                }
                .id(step)
                .transition(.opacity)
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 25)
            .padding(.top, 22)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
        }
        .background(JourneyTheme.background)
        .foregroundStyle(JourneyTheme.ink)
        .tint(JourneyTheme.accent)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .interactiveDismissDisabled()
        .task {
            reminderTime = reminders.date
            await reminders.refreshAuthorization()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reminders.refreshAuthorization() } }
        }
        .alert("Your reminder needs a moment", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Try again", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Text("Selfie Journey")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .tracking(-0.4)
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Capsule().fill(index <= step ? JourneyTheme.accent : JourneyTheme.line)
                        .frame(width: index == step ? 23 : 7, height: 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Setup step \(step + 1) of 3")
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                Circle().fill(JourneyTheme.softAccent.opacity(0.7)).frame(width: 230, height: 230)
                PoseIllustration(pose: .classic, selected: false)
                    .frame(width: 133, height: 178).rotationEffect(.degrees(-12)).offset(x: -70, y: 7)
                PoseIllustration(pose: .classic, selected: false)
                    .frame(width: 133, height: 178).rotationEffect(.degrees(12)).offset(x: 70, y: 7)
                PoseIllustration(pose: .classic, selected: true)
                    .frame(width: 146, height: 195)
                    .shadow(color: JourneyTheme.ink.opacity(0.12), radius: 18, y: 10)
                Label("A little, every day.", systemImage: "sparkle")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 15).padding(.vertical, 11)
                    .background(JourneyTheme.surface, in: Capsule())
                    .offset(y: 108)
            }
            .frame(height: 255).frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 13) {
                Eyebrow(text: "DAILY SELFIES. REAL CHANGES.")
                Text("One selfie a day.\nWatch yourself change.")
                    .font(JourneyTheme.serif(38)).tracking(-1.2)
                    .accessibilityIdentifier("onboarding.welcome")
                Text("Take a selfie each day, using face guides to keep your framing consistent. Turn your photos into a time-lapse video and see how you change with age, month by month and year by year.")
                    .font(.body).foregroundStyle(JourneyTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 15) {
                welcomeBenefit("viewfinder", "Face guides for a consistent daily selfie")
                welcomeBenefit("flame", "Daily reminders and a streak to keep you going")
                welcomeBenefit("play.rectangle", "Your own photos, together in a time-lapse video")
                welcomeBenefit("icloud", "Dated backups in your personal iCloud Drive")
            }
            Text("iCloud backups are on by default when available. You can manage them and restore your story in your daily ritual settings.")
                .font(.footnote).foregroundStyle(JourneyTheme.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Label("Your story stays yours", systemImage: "lock.shield")
                    .font(.subheadline.weight(.semibold))
                Text("We collect no data from the app. Your portraits and notes stay on your device and in your personal iCloud Drive backups.")
                    .font(.footnote).foregroundStyle(JourneyTheme.secondary)
                Link("Privacy policy", destination: URL(string: "https://selfiejourney.com/privacy/")!)
                    .font(.footnote)
            }
            .padding(18).background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var poseSetup: some View {
        VStack(alignment: .leading, spacing: 23) {
            VStack(alignment: .leading, spacing: 11) {
                Eyebrow(text: "01 / YOUR SIGNATURE PORTRAIT")
                Text("Choose your selfie frame.").font(JourneyTheme.serif(38)).tracking(-1)
                Text("Choose a distance from the camera. Use the same face guide each day for a steadier time-lapse.")
                    .foregroundStyle(JourneyTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PoseSelectionView(selection: $preferences.selectedPose)
            Label("You can change your frame anytime in your daily ritual settings.", systemImage: "slider.horizontal.3")
                .font(.footnote).foregroundStyle(JourneyTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reminderSetup: some View {
        VStack(alignment: .leading, spacing: 22) {
            ZStack {
                Circle().fill(JourneyTheme.softAccent).frame(width: 104, height: 104)
                Image(systemName: "bell.badge")
                    .font(.system(size: 42, weight: .light)).foregroundStyle(JourneyTheme.accent)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "02 / YOUR DAILY MOMENT")
                Text("A moment for your selfie.").font(JourneyTheme.serif(38)).tracking(-1)
                Text("After your coffee, or before the day winds down. When should we remind you to take your daily selfie?")
                    .foregroundStyle(JourneyTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 0) {
                Text("YOUR DAILY REMINDER")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(2)
                    .foregroundStyle(JourneyTheme.secondary).padding(.top, 20)
                DatePicker("Daily reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel).labelsHidden()
                    .frame(maxWidth: .infinity).padding(.horizontal, 10)
                    .accessibilityIdentifier("onboarding.reminderTime")
            }
            .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 25))

            Label("Today's reminder disappears once your selfie is saved. Every day adds another frame to your time-lapse.", systemImage: "checkmark.circle")
                .font(.subheadline).foregroundStyle(JourneyTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if permissionDeclined || reminders.authorizationStatus == .denied {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Your journey can start without notifications.")
                        .font(.subheadline.weight(.semibold))
                    Text("To get your daily nudge, allow notifications in Settings. You can also do this later.")
                        .font(.footnote).foregroundStyle(JourneyTheme.secondary)
                    Button("Open notification settings", systemImage: "arrow.up.right") { openSettings() }
                        .font(.subheadline.weight(.medium))
                        .accessibilityIdentifier("onboarding.openSettings")
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(JourneyTheme.softAccent.opacity(0.6), in: RoundedRectangle(cornerRadius: 19))
                .accessibilityIdentifier("onboarding.permissionDeclined")
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if step < 2 {
                PrimaryButton(title: step == 0 ? "Begin your journey" : "This feels like me", symbol: step == 0 ? "sparkle" : "checkmark") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { step += 1 }
                }
                .accessibilityIdentifier("onboarding.continue")
            } else {
                PrimaryButton(title: saving ? "Setting your reminder…" : "Enable my daily reminder", symbol: "bell") {
                    Task { await enableReminder() }
                }
                .disabled(saving)
                .accessibilityIdentifier("onboarding.enableReminder")
            }
            HStack {
                if step > 0 {
                    Button("Back") {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { step -= 1 }
                    }
                    .disabled(saving).accessibilityIdentifier("onboarding.back")
                }
                Spacer()
                if step == 2 {
                    Button(permissionDeclined ? "Continue without reminders" : "Maybe later") {
                        Task { await skipReminders() }
                    }
                    .disabled(saving).accessibilityIdentifier("onboarding.skipReminder")
                } else {
                    Text("A few moments to make it yours.")
                        .foregroundStyle(JourneyTheme.secondary)
                }
                Spacer()
            }
            .font(.footnote).frame(minHeight: 28)
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, 25).padding(.top, 16).padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(JourneyTheme.background)
    }

    private func welcomeBenefit(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 18, weight: .regular))
                .foregroundStyle(JourneyTheme.accent).frame(width: 25)
            Text(title).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func enableReminder() async {
        saving = true
        defer { saving = false }
        do {
            try await reminders.setReminder(enabled: true, time: reminderTime)
            finish()
        } catch ReminderManager.ReminderError.permissionDenied {
            permissionDeclined = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func skipReminders() async {
        saving = true
        defer { saving = false }
        do {
            // Keep the chosen time even when permission is postponed.
            try await reminders.setReminder(enabled: false, time: reminderTime)
            finish()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finish() {
        preferences.hasCompletedOnboarding = true
        onComplete()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PoseSelectionView: View {
    @Binding var selection: PortraitPose
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(PortraitPose.allCases) { pose in
                Button {
                    selection = pose
                } label: {
                    VStack(alignment: .leading, spacing: 11) {
                        PoseIllustration(pose: pose, selected: selection == pose)
                            .aspectRatio(1.12, contentMode: .fit)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: selection == pose ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21, weight: .medium))
                                    .foregroundStyle(selection == pose ? JourneyTheme.accent : JourneyTheme.secondary.opacity(0.65))
                                    .background(JourneyTheme.surface, in: Circle())
                                    .padding(10)
                                    .accessibilityHidden(true)
                            }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Text(pose.title).font(.subheadline.weight(.semibold))
                                if pose == .classic {
                                    Image(systemName: "sparkle").font(.caption2).foregroundStyle(JourneyTheme.accent)
                                }
                            }
                            Text(pose.subtitle).font(.caption).foregroundStyle(JourneyTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }.padding(.horizontal, 11).padding(.bottom, 11)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(selection == pose ? JourneyTheme.accent : JourneyTheme.line, lineWidth: selection == pose ? 2 : 1)
                    }
                    .foregroundStyle(JourneyTheme.ink)
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(pose.title). \(pose.subtitle)\(pose == .classic ? ". Recommended" : "")")
                .accessibilityAddTraits(selection == pose ? .isSelected : [])
                .accessibilityIdentifier("pose.\(pose.rawValue)")
            }
        }
    }
}

/// A deliberately abstract portrait, so framing choices never suggest one
/// person's face is the ideal. The same proportions power the camera guide.
struct PoseIllustration: View {
    let pose: PortraitPose
    var selected = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // A 3:4 reference keeps the distance preview truthful even inside
            // the shorter setup cards; the frame is clipped as a photograph.
            let portraitHeight = max(height, width * 4 / 3)
            let headWidth = width * pose.faceWidth
            let headHeight = portraitHeight * pose.faceHeight
            let centerY = height * 0.43
            ZStack {
                (selected ? JourneyTheme.softAccent : JourneyTheme.line.opacity(0.52))
                Path { path in
                    let neckY = centerY + headHeight * 0.31
                    path.move(to: CGPoint(x: width * 0.5 - headWidth * 0.16, y: neckY))
                    path.addLine(to: CGPoint(x: width * 0.5 - headWidth * 0.18, y: neckY + headHeight * 0.26))
                    path.addCurve(to: CGPoint(x: width * 0.5 - headWidth * 1.03, y: neckY + headHeight * 0.70),
                                  control1: CGPoint(x: width * 0.5 - headWidth * 0.96, y: neckY + headHeight * 0.30),
                                  control2: CGPoint(x: width * 0.5 - headWidth * 1.03, y: neckY + headHeight * 0.40))
                    path.addLine(to: CGPoint(x: width * 0.5 - headWidth * 1.16, y: height + portraitHeight))
                    path.addLine(to: CGPoint(x: width * 0.5 + headWidth * 1.16, y: height + portraitHeight))
                    path.addLine(to: CGPoint(x: width * 0.5 + headWidth * 1.03, y: neckY + headHeight * 0.70))
                    path.addCurve(to: CGPoint(x: width * 0.5 + headWidth * 0.18, y: neckY + headHeight * 0.26),
                                  control1: CGPoint(x: width * 0.5 + headWidth * 1.03, y: neckY + headHeight * 0.40),
                                  control2: CGPoint(x: width * 0.5 + headWidth * 0.96, y: neckY + headHeight * 0.30))
                    path.addLine(to: CGPoint(x: width * 0.5 + headWidth * 0.16, y: neckY))
                    path.closeSubpath()
                }.fill(JourneyTheme.accent.opacity(selected ? 0.45 : 0.25))
                Ellipse()
                    .fill(JourneyTheme.accent.opacity(selected ? 0.64 : 0.4))
                    .frame(width: headWidth, height: headHeight)
                    .position(x: width * 0.5, y: centerY)
                Path { path in
                    let eyeY = centerY - headHeight * 0.12
                    path.move(to: CGPoint(x: width * 0.5 - headWidth * 0.25, y: eyeY))
                    path.addLine(to: CGPoint(x: width * 0.5 + headWidth * 0.25, y: eyeY))
                }
                .stroke(JourneyTheme.surface.opacity(0.85), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            }
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .accessibilityHidden(true)
    }
}
