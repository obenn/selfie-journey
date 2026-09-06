import SwiftUI
import SwiftData
import ImageIO

struct LibraryView: View {
    let portraits: [Portrait]
    let onCapture: () -> Void
    @State private var selectedPortrait: Portrait?

    private var months: [(date: Date, portraits: [Portrait])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: portraits) { portrait in
            calendar.date(from: calendar.dateComponents([.year, .month], from: portrait.date)) ?? portrait.date
        }
        return grouped.keys.sorted(by: >).map { month in
            (month, (grouped[month] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("THE COLLECTION")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(2.4)
                        .foregroundStyle(JourneyTheme.secondary)
                    Text("Your story.")
                        .font(JourneyTheme.serif(43))
                        .foregroundStyle(JourneyTheme.ink)
                    Text(portraits.isEmpty ? "An ordinary day. A little piece of you." : "\(portraits.count) \(portraits.count == 1 ? "portrait" : "portraits"). Each one, a day worth keeping.")
                        .font(.system(size: 15))
                        .foregroundStyle(JourneyTheme.secondary)
                }
                .padding(.top, 20)

                if portraits.isEmpty {
                    emptyState
                } else {
                    ForEach(months, id: \.date) { month in
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(month.date.formatted(.dateTime.month(.wide).year()))
                                    .font(JourneyTheme.serif(25))
                                Spacer()
                                Text("\(month.portraits.count) \(month.portraits.count == 1 ? "DAY" : "DAYS")")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .tracking(1.2)
                                    .foregroundStyle(JourneyTheme.secondary)
                            }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 16) {
                                ForEach(month.portraits) { portrait in
                                    Button {
                                        selectedPortrait = portrait
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            PortraitImage(data: portrait.imageData, maximumPixelSize: 420)
                                                .aspectRatio(3 / 4, contentMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                                .overlay(alignment: .bottomTrailing) {
                                                    if !portrait.note.isEmpty {
                                                        Image(systemName: "text.alignleft")
                                                            .font(.system(size: 9, weight: .semibold))
                                                            .foregroundStyle(.white)
                                                            .padding(6)
                                                            .background(.black.opacity(0.3), in: Circle())
                                                            .padding(6)
                                                    }
                                                }
                                            Text(portrait.date.formatted(.dateTime.day().weekday(.abbreviated)))
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(JourneyTheme.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Portrait, \(portrait.date.formatted(date: .complete, time: .omitted))\(portrait.note.isEmpty ? "" : ", has a note")")
                                }
                            }
                        }
                    }
                    Text("The small changes are the story.")
                        .font(JourneyTheme.serif(19))
                        .italic()
                        .foregroundStyle(JourneyTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(JourneyTheme.background)
        .sheet(item: $selectedPortrait) { portrait in
            PortraitDetailView(portrait: portrait)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 26)
                    .fill(JourneyTheme.softAccent)
                    .frame(width: 142, height: 180)
                    .rotationEffect(.degrees(-9))
                RoundedRectangle(cornerRadius: 26)
                    .fill(JourneyTheme.surface)
                    .frame(width: 142, height: 180)
                    .rotationEffect(.degrees(7))
                    .shadow(color: JourneyTheme.ink.opacity(0.05), radius: 14, y: 8)
                Image(systemName: "person.crop.rectangle")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(JourneyTheme.accent)
            }
            .accessibilityHidden(true)
            .padding(.top, 30)
            VStack(spacing: 10) {
                Text("A collection of you.")
                    .font(JourneyTheme.serif(29))
                    .foregroundStyle(JourneyTheme.ink)
                Text("Your portraits will find a home here.\nStart with who you are today.")
                    .font(.system(size: 15))
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(JourneyTheme.secondary)
            }
            Button(action: onCapture) {
                Label("Take your first portrait", systemImage: "camera")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 17)
                    .background(JourneyTheme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

/// Decode only the pixels needed for display, including the photo's EXIF orientation.
struct PortraitImage: View {
    let data: Data
    var maximumPixelSize: Int = 1200
    @State private var decoded: UIImage?

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let decoded {
                    Image(uiImage: decoded)
                        .resizable()
                        .scaledToFill()
                } else {
                    JourneyTheme.sage
                        .overlay {
                            Image(systemName: "person.crop.rectangle")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(JourneyTheme.secondary)
                        }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .task(id: data) {
            let bytes = data
            let pixels = maximumPixelSize
            let result = await Task.detached(priority: .userInitiated) {
                Self.thumbnail(data: bytes, maximumPixelSize: pixels)
            }.value
            guard !Task.isCancelled else { return }
            decoded = result
        }
        .accessibilityHidden(true)
    }

    nonisolated static func thumbnail(data: Data, maximumPixelSize: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}

private struct PortraitDetailView: View {
    let portrait: Portrait
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var confirmDelete = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PortraitImage(data: portrait.imageData)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(portrait.date.formatted(.dateTime.month(.wide).day()))
                            .font(JourneyTheme.serif(34))
                        Text(portrait.date.formatted(.dateTime.weekday(.wide).year()))
                            .font(.system(size: 13))
                            .foregroundStyle(JourneyTheme.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("A NOTE TO REMEMBER")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(1.8)
                            .foregroundStyle(JourneyTheme.secondary)
                        TextField("How did today feel?", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 16))
                            .padding(18)
                            .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                    HStack {
                        if let image = portrait.image {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview("My Selfie Journey portrait", image: Image(uiImage: image))) {
                                Label("Share portrait", systemImage: "square.and.arrow.up")
                            }
                        }
                        Spacer()
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Image(systemName: "trash")
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Delete portrait")
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .padding(24)
            }
            .background(JourneyTheme.background)
            .foregroundStyle(JourneyTheme.ink)
            .navigationTitle("A day of you")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveNote() }
                        .fontWeight(.semibold)
                }
            }
            .tint(JourneyTheme.accent)
            .onAppear { note = portrait.note }
            .confirmationDialog("Delete this portrait?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete portrait", role: .destructive) {
                    modelContext.delete(portrait)
                    do {
                        try modelContext.save()
                        dismiss()
                    } catch {
                        modelContext.rollback()
                        errorMessage = "Your portrait could not be deleted. Please try again."
                    }
                }
            } message: {
                Text("This removes the portrait and its note from your collection. This can't be undone and may change your streak.")
            }
            .alert("Couldn't save your change", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private func saveNote() {
        let previousNote = portrait.note
        portrait.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            portrait.note = previousNote
            errorMessage = "Your note could not be saved. Please try again."
        }
    }
}
