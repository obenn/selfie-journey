import SwiftUI
import SwiftData

struct LookbackView: View {
    let portraits: [Portrait]
    let onCapture: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedIndex = 0
    @State private var isPlaying = false
    @State private var pace: VideoExporter.Pace = .balanced
    @State private var includeDates = true
    @State private var isExporting = false
    @State private var exportProgress = 0.0
    @State private var exportTask: Task<Void, Never>?
    @State private var exportedURL: URL?
    @State private var errorMessage: String?

    private var orderedPortraits: [Portrait] { portraits.sorted { $0.date < $1.date } }
    private var currentPortrait: Portrait? {
        let ordered = orderedPortraits
        guard !ordered.isEmpty else { return nil }
        return ordered[min(selectedIndex, ordered.count - 1)]
    }
    private var canMakeFilm: Bool { portraits.count >= 2 }
    private var duration: String {
        let seconds = Double(portraits.count) * pace.secondsPerPortrait
        return seconds.formatted(.number.precision(.fractionLength(1))) + " sec"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("THE LOOKBACK")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(2.4)
                        .foregroundStyle(JourneyTheme.secondary)
                    Text("You, over time.")
                        .font(JourneyTheme.serif(43))
                        .foregroundStyle(JourneyTheme.ink)
                        .minimumScaleFactor(0.8)
                    Text("Little by little, a life comes into view.")
                        .font(.system(size: 15))
                        .foregroundStyle(JourneyTheme.secondary)
                }
                .padding(.top, 20)

                if let portrait = currentPortrait {
                    filmPreview(portrait)
                    if canMakeFilm {
                        playbackControls
                        filmOptions
                        exportControls
                    } else {
                        firstFrameMessage
                    }
                } else {
                    emptyFilm
                }

                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "lock")
                        .font(.system(size: 11))
                        .padding(.top, 2)
                    Text("Made on your device. Yours to keep, yours to share.")
                        .font(.system(size: 12))
                        .lineSpacing(3)
                }
                .foregroundStyle(JourneyTheme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(JourneyTheme.background)
        .tint(JourneyTheme.accent)
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(pace.secondsPerPortrait)) }
                catch { return }
                guard isPlaying, !Task.isCancelled, canMakeFilm else { return }
                selectedIndex = (selectedIndex + 1) % portraits.count
            }
        }
        .onChange(of: pace) { _, _ in
            isPlaying = false
            discardExport()
        }
        .onChange(of: includeDates) { _, _ in discardExport() }
        .onChange(of: portraits.map(\.id)) { _, _ in
            selectedIndex = min(selectedIndex, max(0, portraits.count - 1))
            isPlaying = false
            exportTask?.cancel()
            discardExport()
        }
        .onChange(of: portraits.map(\.imageRevision)) { _, _ in
            // A same-day retake replaces the bytes while keeping its ID and date.
            // A scalar revision avoids loading the entire collection's external image data.
            isPlaying = false
            exportTask?.cancel()
            discardExport()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isPlaying = false }
            if phase == .background { exportTask?.cancel() }
        }
        .onDisappear {
            isPlaying = false
            exportTask?.cancel()
        }
        .alert("Couldn't make your film", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func filmPreview(_ portrait: Portrait) -> some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                PortraitImage(data: portrait.imageData)
                if includeDates {
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                    Text(portrait.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 13, weight: .medium))
                        .tracking(0.4)
                        .foregroundStyle(.white)
                        .padding(.bottom, 20)
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(JourneyTheme.ink.opacity(0.06), lineWidth: 1)
            }
            .frame(maxWidth: 310)
            .shadow(color: JourneyTheme.ink.opacity(0.08), radius: 18, x: 0, y: 10)
            .accessibilityLabel("Portrait from \(portrait.date.formatted(date: .complete, time: .omitted))")

            HStack(spacing: 7) {
                Circle().fill(JourneyTheme.accent).frame(width: 4, height: 4)
                Text("FRAME \(selectedIndex + 1) OF \(portraits.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.3)
                    .foregroundStyle(JourneyTheme.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var playbackControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(JourneyTheme.ink)
                        .frame(width: 50, height: 50)
                        .background(JourneyTheme.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Pause lookback" : "Play lookback")
                Slider(value: Binding(
                    get: { Double(selectedIndex) },
                    set: { selectedIndex = Int($0) }
                ), in: 0...Double(max(portraits.count - 1, 1)), step: 1) { editing in
                    if editing { isPlaying = false }
                }
                .accessibilityLabel("Lookback frame")
                .accessibilityValue("\(selectedIndex + 1) of \(portraits.count)")
            }
            HStack {
                Text(orderedPortraits.first?.date.formatted(.dateTime.month(.abbreviated).day().year()) ?? "")
                Spacer()
                Text(orderedPortraits.last?.date.formatted(.dateTime.month(.abbreviated).day().year()) ?? "")
            }
            .font(.system(size: 11))
            .foregroundStyle(JourneyTheme.secondary)
        }
    }

    private var filmOptions: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack {
                Text("MAKE IT YOURS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.7)
                Spacer()
                Text(duration)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(JourneyTheme.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Text("The pace of your story")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JourneyTheme.ink)
                Picker("Film pace", selection: $pace) {
                    ForEach(VideoExporter.Pace.allCases) { pace in
                        Text(pace.rawValue).tag(pace)
                    }
                }
                .pickerStyle(.segmented)
            }
            Toggle(isOn: $includeDates) {
                Label("A date on every frame", systemImage: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(JourneyTheme.ink)
            }
        }
        .padding(20)
        .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .disabled(isExporting)
    }

    @ViewBuilder private var exportControls: some View {
        if isExporting {
            VStack(spacing: 13) {
                HStack {
                    Text(exportProgress >= 1 ? "Finishing your film…" : "Gathering your days…")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(exportProgress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 12, design: .monospaced))
                }
                ProgressView(value: exportProgress)
                    .accessibilityLabel("Creating film")
                Button("Cancel") { exportTask?.cancel() }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.top, 4)
            }
            .foregroundStyle(JourneyTheme.ink)
            .padding(20)
            .background(JourneyTheme.softAccent, in: RoundedRectangle(cornerRadius: 22))
        } else if let exportedURL {
            VStack(spacing: 11) {
                ShareLink(item: exportedURL, preview: SharePreview("My Selfie Journey lookback")) {
                    Label("Share your film", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 19)
                        .background(JourneyTheme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                Text("Your film is ready. Save it to Files or share it with someone.")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(JourneyTheme.secondary)
            }
        } else {
            VStack(spacing: 11) {
                Button(action: createFilm) {
                    Label("Create your film", systemImage: "film")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 19)
                        .background(JourneyTheme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                Text("\(portraits.count) portraits · \(duration) · 1080p")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(JourneyTheme.secondary)
            }
        }
    }

    private var firstFrameMessage: some View {
        VStack(spacing: 12) {
            Text("The beginning of something.")
                .font(JourneyTheme.serif(26))
                .foregroundStyle(JourneyTheme.ink)
            Text("Your first frame is here. Come back tomorrow;\na lookback begins with two portraits.")
                .font(.system(size: 14))
                .lineSpacing(4)
                .foregroundStyle(JourneyTheme.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var emptyFilm: some View {
        VStack(spacing: 26) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(JourneyTheme.sage)
                VStack(spacing: 30) {
                    HStack {
                        Text("PICA / DAY")
                        Spacer()
                        Image(systemName: "sparkle")
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(JourneyTheme.secondary)
                    ZStack {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(JourneyTheme.secondary.opacity(0.18 + Double(index) * 0.12), lineWidth: 1)
                                .frame(width: 104, height: 140)
                                .rotationEffect(.degrees(Double(index - 1) * 14))
                        }
                        Image(systemName: "play.fill")
                            .font(.system(size: 25, weight: .ultraLight))
                            .foregroundStyle(JourneyTheme.ink.opacity(0.7))
                    }
                    .frame(height: 162)
                    Text("A little every day.\nA lifetime to look back on.")
                        .font(JourneyTheme.serif(25))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(JourneyTheme.ink)
                }
                .padding(28)
            }
            .frame(height: 350)
            .accessibilityElement(children: .combine)

            VStack(spacing: 12) {
                Text("Your future favorite film.")
                    .font(JourneyTheme.serif(27))
                    .foregroundStyle(JourneyTheme.ink)
                Text("A portrait each day becomes a moving memory.\nStart today. Watch your story grow.")
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .foregroundStyle(JourneyTheme.secondary)
            }
            .multilineTextAlignment(.center)
            Button(action: onCapture) {
                Label("Begin with a portrait", systemImage: "camera")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(JourneyTheme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func createFilm() {
        guard canMakeFilm, !isExporting else { return }
        isPlaying = false
        discardExport()
        let sources = orderedPortraits.map { (portrait: $0, revision: $0.imageRevision, date: $0.date) }
        let chosenPace = pace
        let dates = includeDates
        isExporting = true
        exportProgress = 0
        exportTask = Task {
            do {
                let url = try await VideoExporter().export(dates: sources.map(\.date), pace: chosenPace, includeDates: dates, imageDataAt: { index in
                    try Task.checkCancellation()
                    let source = sources[index]
                    guard source.portrait.modelContext != nil,
                          source.portrait.imageRevision == source.revision else { throw CancellationError() }
                    return source.portrait.imageData
                }) { value in
                    Task { @MainActor in exportProgress = value }
                }
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: url)
                } else {
                    exportedURL = url
                }
            } catch is CancellationError {
                // Cancelling leaves the portraits untouched and removes the partial film.
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
            exportTask = nil
        }
    }

    private func discardExport() {
        if let exportedURL { try? FileManager.default.removeItem(at: exportedURL) }
        exportedURL = nil
    }
}
