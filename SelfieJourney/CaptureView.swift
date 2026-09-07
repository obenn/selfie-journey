import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

/// A private, front-facing portrait ritual. Saving stays in review if persistence throws.
/// Both live and imported images use a centered 3:4 canvas. Live guidance stays on device.
struct CaptureView: View {
    let referenceImage: UIImage?
    let pose: PortraitPose
    let onSave: (UIImage, String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var camera = CameraService()
    @State private var ghostEnabled = true
    @State private var ghostOpacity = 0.22
    @State private var timerEnabled = true
    @State private var countdown: Int?
    @State private var countdownTask: Task<Void, Never>?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isImporting = false
    @State private var isSaving = false
    @State private var note = ""
    @State private var showTips = false
    @FocusState private var noteFocused: Bool

    private let ink = Color(red: 0.071, green: 0.078, blue: 0.075)
    private let cream = Color(red: 0.97, green: 0.95, blue: 0.90)
    private let accent = Color(red: 0.847, green: 0.353, blue: 0.212)
    private let alignedColor = Color(red: 0.65, green: 0.81, blue: 0.67)
    private var isReviewing: Bool { camera.capturedImage != nil }
    private var busy: Bool { countdown != nil || camera.isCapturing || isImporting || isSaving }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    if let image = camera.capturedImage {
                        review(image, height: max(280, min(min(geometry.size.width - 40, 480) * 4 / 3, geometry.size.height - 295)))
                    } else {
                        cameraContent(height: max(280, min(min(geometry.size.width - 40, 480) * 4 / 3, geometry.size.height - (referenceImage == nil ? 260 : 318))))
                    }
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(ink.ignoresSafeArea())
        .foregroundStyle(cream)
        .preferredColorScheme(.dark)
        .onAppear { camera.updatePose(pose); camera.start() }
        .onChange(of: pose) { _, newPose in camera.updatePose(newPose) }
        .onDisappear {
            cancelCountdown()
            camera.stop()
        }
        .onChange(of: isReviewing) { _, reviewing in
            if reviewing {
                cancelCountdown()
                camera.stop()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, !isReviewing { camera.start() }
            else if phase != .active {
                cancelCountdown()
                camera.stop()
            }
        }
        .task(id: selectedPhoto) { await importPhoto() }
        .alert("A little interruption", isPresented: Binding(get: { camera.errorMessage != nil }, set: { if !$0 { camera.errorMessage = nil } })) {
            Button("OK", role: .cancel) { camera.errorMessage = nil }
        } message: {
            Text(camera.errorMessage ?? "Please try again.")
        }
        .sheet(isPresented: $showTips) { alignmentTips }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button {
                cancelCountdown()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.07), in: Circle())
            }
            .accessibilityLabel("Close camera")
            .accessibilityIdentifier("capture.close")
            Spacer()
            VStack(spacing: 5) {
                Text(isReviewing ? "TODAY’S SELFIE" : "YOUR DAILY SELFIE")
                    .font(.system(size: 9, weight: .semibold)).tracking(2.4)
                    .foregroundStyle(cream.opacity(0.55))
                Text(isReviewing ? "This is you, today." : "Line up your face.")
                    .font(.system(size: 23, weight: .regular, design: .serif))
            }
            Spacer()
            Button { showTips = true } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.07), in: Circle())
            }
            .accessibilityLabel("Portrait alignment tips")
        }
        .buttonStyle(.plain)
    }

    private func cameraContent(height: CGFloat) -> some View {
        VStack(spacing: 18) {
            ZStack {
                viewfinderBackground
                if camera.state == .ready {
                    CameraPreview(camera: camera)
                        .accessibilityHidden(true)
                    if ghostEnabled, let referenceImage {
                        Image(uiImage: referenceImage)
                            .resizable()
                            .scaledToFill()
                            .opacity(ghostOpacity)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    PortraitAlignmentGuide(color: camera.guidance.isAligned ? alignedColor : cream, pose: pose, aligned: camera.guidance.isAligned)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    VStack {
                        HStack(spacing: 6) {
                            Image(systemName: "viewfinder")
                            Text(pose.title.uppercased())
                                .tracking(1.5)
                            Text("·").foregroundStyle(cream.opacity(0.4))
                            Image(systemName: "lock.fill").font(.system(size: 7))
                            Text("ON DEVICE").tracking(1.2)
                        }
                        .font(.system(size: 8, weight: .semibold))
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(.black.opacity(0.36), in: Capsule())
                        .padding(.top, 18)
                        Spacer()
                        guidanceOverlay
                            .padding(.horizontal, 14)
                            .padding(.bottom, 16)
                    }
                }
                if let countdown {
                    cream.opacity(0.08)
                    Text("\(countdown)")
                        .font(.system(size: 104, weight: .regular, design: .serif))
                        .contentTransition(.numericText())
                        .shadow(color: .black.opacity(0.2), radius: 20)
                        .accessibilityLabel("Taking portrait in \(countdown)")
                }
                if camera.isCapturing || isImporting {
                    Color.black.opacity(0.25)
                    ProgressView(isImporting ? "Opening your photo…" : "Holding this moment…")
                        .tint(cream)
                        .font(.footnote)
                }
            }
            .frame(width: height * 3 / 4, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(cream.opacity(0.12), lineWidth: 1))
            .frame(maxWidth: .infinity)

            if referenceImage != nil {
                HStack(spacing: 12) {
                    Button {
                        ghostEnabled.toggle()
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        Label("Last portrait", systemImage: ghostEnabled ? "square.on.square" : "square")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ghostEnabled ? cream : cream.opacity(0.45))
                    }
                    .accessibilityLabel("Previous portrait overlay")
                    .accessibilityValue(ghostEnabled ? "On" : "Off")
                    .buttonStyle(.plain)
                    Slider(value: $ghostOpacity, in: 0.08...0.5)
                        .tint(accent)
                        .disabled(!ghostEnabled)
                        .accessibilityLabel("Previous portrait overlay opacity")
                    Text("\(Int(ghostOpacity * 100))%")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(cream.opacity(0.55))
                        .frame(width: 30)
                }
                .padding(.horizontal, 8)
            }

            HStack(alignment: .center) {
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    VStack(spacing: 7) {
                        Image(systemName: "photo.on.rectangle").font(.system(size: 22, weight: .light))
                        Text("Library").font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(cream.opacity(0.65))
                    .frame(width: 66, height: 60)
                }
                .accessibilityLabel("Choose a portrait from Photos")
                .accessibilityIdentifier("capture.import")
                .disabled(busy)
                Spacer()
                Button(action: beginCapture) {
                    ZStack {
                        Circle().stroke(camera.guidance.isAligned ? alignedColor : cream.opacity(0.8), lineWidth: 1.5).frame(width: 78, height: 78)
                        Circle().fill(accent).frame(width: 64, height: 64)
                        if countdown != nil {
                            Image(systemName: "xmark").font(.system(size: 20, weight: .medium))
                        } else {
                            Image(systemName: "camera.fill").font(.system(size: 22, weight: .regular))
                        }
                    }
                    .opacity(camera.state == .ready ? 1 : 0.35)
                }
                .buttonStyle(.plain)
                .disabled(camera.state != .ready || camera.isCapturing || isImporting)
                .accessibilityLabel(countdown == nil ? "Take today’s portrait" : "Cancel countdown")
                .accessibilityIdentifier("capture.shutter")
                Spacer()
                Button {
                    timerEnabled.toggle()
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: "timer").font(.system(size: 23, weight: .light))
                        Text(timerEnabled ? "3 seconds" : "Timer off").font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(timerEnabled ? cream : cream.opacity(0.45))
                    .frame(width: 66, height: 60)
                }
                .buttonStyle(.plain)
                .disabled(busy)
                .accessibilityLabel("Three second timer")
                .accessibilityValue(timerEnabled ? "On" : "Off")
            }
            .padding(.horizontal, 20)

            Text("Match your framing each day for a steadier time-lapse.")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(cream.opacity(0.45))
        }
    }

    private var guidanceOverlay: some View {
        VStack(spacing: 9) {
            HStack(spacing: 16) {
                conditionIndicator("Face", symbol: "face.smiling", state: camera.guidance.face)
                conditionIndicator("Frame", symbol: "viewfinder", state: camera.guidance.position)
                conditionIndicator("Light", symbol: "sun.max", state: camera.guidance.light)
            }
            .padding(.horizontal, 13).padding(.vertical, 7)
            .background(.black.opacity(0.30), in: Capsule())
            Label(camera.guidance.cue.message, systemImage: camera.guidance.cue.symbol)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(camera.guidance.isAligned ? alignedColor : cream)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(camera.guidance.isAligned ? alignedColor.opacity(0.5) : cream.opacity(0.12)))
                .accessibilityIdentifier("capture.guidance")
            if camera.guidance.cue == .manual {
                Text("Live guidance is unavailable. You can still take a photo.")
                    .font(.system(size: 10)).multilineTextAlignment(.center)
                    .padding(7).background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: camera.guidance)
        .allowsHitTesting(false)
    }

    private func conditionIndicator(_ label: String, symbol: String, state: GuidanceCondition) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(label)
            if state == .good { Image(systemName: "checkmark").font(.system(size: 7, weight: .bold)) }
            else if state == .adjust { Circle().frame(width: 3, height: 3) }
            else { Text("–") }
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(state == .good ? alignedColor : cream.opacity(state == .adjust ? 0.9 : 0.55))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(state == .good ? "looks good" : state == .adjust ? "adjustment suggested" : "not measured")")
    }

    @ViewBuilder private var viewfinderBackground: some View {
        switch camera.state {
        case .preparing:
            Color.white.opacity(0.035)
            VStack(spacing: 14) {
                ProgressView().tint(cream)
                Text("Getting your camera ready…").font(.footnote).foregroundStyle(cream.opacity(0.6))
            }
        case .ready:
            Color.black
        case .denied:
            unavailableCamera(
                title: "Let’s see you.",
                message: "Allow camera access in Settings to take your daily portrait. You can also choose one from Photos.",
                settings: true
            )
        case .unavailable(let message):
            unavailableCamera(title: "Your portrait goes here.", message: message, settings: false)
        }
    }

    private func unavailableCamera(title: String, message: String, settings: Bool) -> some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.16, green: 0.19, blue: 0.17), ink], startPoint: .topLeading, endPoint: .bottomTrailing)
            PortraitAlignmentGuide(color: cream.opacity(0.18), pose: pose).accessibilityHidden(true)
            VStack(spacing: 16) {
                Image(systemName: settings ? "camera.fill" : "person.crop.rectangle")
                    .font(.system(size: 34, weight: .ultraLight))
                    .foregroundStyle(cream.opacity(0.7))
                Text(title).font(.system(size: 25, weight: .regular, design: .serif))
                Text(message)
                    .font(.system(size: 13)).foregroundStyle(cream.opacity(0.65))
                    .multilineTextAlignment(.center).lineSpacing(4)
                if settings {
                    Button("Open Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(accent, in: Capsule())
                } else {
                    Button("Try camera again") { camera.start() }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(cream.opacity(0.7))
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 34)
        }
    }

    private func review(_ image: UIImage, height: CGFloat) -> some View {
        VStack(spacing: 18) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: height * 3 / 4, height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(alignment: .bottomLeading) {
                    Label("A moment worth keeping", systemImage: "sparkle")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.black.opacity(0.40), in: Capsule())
                        .padding(16)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Your portrait to save")

            HStack(spacing: 11) {
                Image(systemName: "pencil.line").font(.system(size: 16, weight: .light))
                    .foregroundStyle(cream.opacity(0.5))
                TextField("A few words about today (optional)", text: $note, axis: .vertical)
                    .font(.system(size: 13))
                    .lineLimit(1...3)
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .onChange(of: note) { _, value in
                        if value.count > 280 { note = String(value.prefix(280)) }
                    }
                    .accessibilityLabel("A note about today, optional")
            }
            .padding(16)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 12) {
                Button {
                    noteFocused = false
                    camera.retake()
                    selectedPhoto = nil
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 54, height: 54)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                }
                .accessibilityLabel("Retake portrait")
                .accessibilityIdentifier("capture.retake")
                Button { save(image) } label: {
                    HStack(spacing: 10) {
                        if isSaving { ProgressView().tint(cream) }
                        else { Image(systemName: "checkmark") }
                        Text(isSaving ? "Saving your selfie…" : "Save today’s portrait")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(accent, in: RoundedRectangle(cornerRadius: 18))
                }
                .accessibilityIdentifier("capture.save")
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            Text("One more daily photo for your time-lapse.")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(cream.opacity(0.5))
        }
    }

    private var alignmentTips: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
            Capsule().fill(cream.opacity(0.25)).frame(width: 32, height: 4).frame(maxWidth: .infinity)
            Text("Find your familiar frame.")
                .font(.system(size: 30, weight: .regular, design: .serif))
            tip("viewfinder", "Your \(pose.title.lowercased()) frame", "Keep your face inside the oval and your eyes along the line. Change your usual distance any time in Your ritual.")
            tip("face.smiling", "A little help finding your frame", "Live face detection suggests distance, position, and head angle. The guide turns green when things line up; you can take your portrait at any time.")
            tip("square.on.square", "Match your previous selfie", "Turn on Last portrait to line up with your previous photo. Adjust its opacity until it feels right.")
            tip("sun.max", "Let the light find you", "Dim-image and backlighting hints can help. Face a window for soft, even light. Brightness hints are approximate, so trust your eyes too.")
            Text("Live guidance uses Apple Vision on your device. Preview frames and facial measurements are never saved or uploaded. If live guidance is unavailable, the visual guides still work.")
                .font(.footnote).foregroundStyle(cream.opacity(0.55)).lineSpacing(3)
            Button("I’m ready") { showTips = false }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(accent, in: Capsule())
        }
            .padding(26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ink)
        .foregroundStyle(cream)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.dark)
    }

    private func tip(_ symbol: String, _ title: String, _ message: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol).font(.system(size: 21, weight: .light))
                .foregroundStyle(accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(message).font(.system(size: 13)).foregroundStyle(cream.opacity(0.65)).lineSpacing(4)
            }
        }
    }

    private func beginCapture() {
        if countdown != nil { cancelCountdown(); return }
        guard !busy else { return }
        noteFocused = false
        guard timerEnabled else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            camera.capture()
            return
        }
        countdownTask = Task { @MainActor in
            for number in (1...3).reversed() {
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.15)) { countdown = number }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
            }
            countdown = nil
            guard !Task.isCancelled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            camera.capture()
        }
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdown = nil
    }

    private func importPhoto() async {
        guard let selectedPhoto else { return }
        isImporting = true
        defer { isImporting = false }
        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                throw PortraitImportError.unreadable
            }
            guard !Task.isCancelled else { return }
            camera.capturedImage = CameraImageProcessor.portrait(from: image)
        } catch {
            guard !Task.isCancelled else { return }
            camera.errorMessage = "This photo couldn’t be opened. Please choose another portrait."
        }
    }

    private func save(_ image: UIImage) {
        guard !isSaving else { return }
        noteFocused = false
        isSaving = true
        do {
            try onSave(image, note.trimmingCharacters(in: .whitespacesAndNewlines))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            isSaving = false
            camera.errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

private enum PortraitImportError: Error { case unreadable }

private struct PortraitAlignmentGuide: View {
    let color: Color
    let pose: PortraitPose
    var aligned = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let eyeY = height * pose.eyeLineY
            let faceTop = height * (pose.centerY - pose.faceHeight * 0.62)
            let faceBottom = height * (pose.centerY + pose.faceHeight * 0.5)
            let shoulderY = min(height * 0.88, faceBottom + height * 0.09)
            ZStack {
                Ellipse()
                    .stroke(color.opacity(aligned ? 0.85 : 0.55), style: StrokeStyle(lineWidth: aligned ? 1.6 : 1, dash: aligned ? [] : [7, 6]))
                    .frame(width: width * pose.faceWidth, height: height * pose.faceHeight * 1.12)
                    .position(x: width / 2, y: height * (pose.centerY - pose.faceHeight * 0.06))
                Path { path in
                    path.move(to: CGPoint(x: width * (0.5 - pose.faceWidth * 0.62), y: eyeY))
                    path.addLine(to: CGPoint(x: width * (0.5 + pose.faceWidth * 0.62), y: eyeY))
                    path.move(to: CGPoint(x: width * 0.5, y: faceTop))
                    path.addLine(to: CGPoint(x: width * 0.5, y: faceBottom))
                }
                .stroke(color.opacity(0.35), style: StrokeStyle(lineWidth: 0.7, dash: [3, 6]))
                Path { path in
                    for x in [width * (0.5 - pose.faceWidth * 0.22), width * (0.5 + pose.faceWidth * 0.22)] {
                        path.move(to: CGPoint(x: x - 7, y: eyeY))
                        path.addLine(to: CGPoint(x: x + 7, y: eyeY))
                    }
                    path.move(to: CGPoint(x: width * 0.14, y: shoulderY + height * 0.05))
                    path.addQuadCurve(to: CGPoint(x: width * 0.34, y: shoulderY), control: CGPoint(x: width * 0.22, y: shoulderY))
                    path.move(to: CGPoint(x: width * 0.66, y: shoulderY))
                    path.addQuadCurve(to: CGPoint(x: width * 0.86, y: shoulderY + height * 0.05), control: CGPoint(x: width * 0.78, y: shoulderY))
                }
                .stroke(color.opacity(0.65), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let camera: CameraService

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = camera.session
        view.refreshRotation = { [weak camera] in camera?.refreshPreviewRotation() }
        view.detachRotation = { [weak camera] layer in camera?.detachPreview(layer) }
        camera.attachPreview(view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.previewLayer.session !== camera.session { uiView.previewLayer.session = camera.session }
        camera.attachPreview(uiView.previewLayer)
    }

    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        uiView.detachRotation?(uiView.previewLayer)
        uiView.refreshRotation = nil
        uiView.detachRotation = nil
        uiView.previewLayer.session = nil
    }
}

private final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var refreshRotation: (() -> Void)?
    var detachRotation: ((AVCaptureVideoPreviewLayer) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshRotation?()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // A rotation coordinator can only resolve the preview angle once its
        // layer has entered the window hierarchy.
        refreshRotation?()
    }
}
