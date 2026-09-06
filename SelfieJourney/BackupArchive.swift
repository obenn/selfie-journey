import Foundation
import CryptoKit
import ImageIO

/// Portable, versioned manifests reference immutable JPEGs, so dated backups share unchanged photos.
nonisolated struct BackupManifest: Codable, Sendable, Identifiable {
    var version = 1
    var id: UUID
    var createdAt: Date
    var entries: [Entry]

    struct Entry: Codable, Sendable {
        var id: UUID
        var imageRevision: UUID
        var date: Date
        var note: String
        var filename: String
        var checksum: String
        var poseRawValue: String? = nil
    }
}

nonisolated struct BackupSource: Sendable {
    let id: UUID
    let revision: UUID
    let date: Date
    let note: String
    var poseRawValue: String = "classic"
    var filename: String { "\(id.uuidString)-\(revision.uuidString).jpg" }
}

nonisolated enum BackupError: LocalizedError {
    case unavailable, invalidManifest, invalidPhoto, changedDuringBackup, downloading
    var errorDescription: String? {
        switch self {
        case .unavailable: "iCloud Drive isn't available. Sign in to iCloud and enable iCloud Drive in Settings."
        case .invalidManifest: "This backup couldn't be read. Your journal hasn't been replaced."
        case .invalidPhoto: "A photo in this backup is missing or damaged. Try another backup."
        case .changedDuringBackup: "Your journal changed while the backup was being prepared. It will be retried."
        case .downloading: "iCloud is still downloading this backup. Keep your connection available and try again shortly."
        }
    }
}

actor BackupArchive {
    static let containerIdentifier = "iCloud.com.strikethrough.PicaDay"
    private let fileManager = FileManager.default

    func cloudRoot() -> URL? {
        guard fileManager.ubiquityIdentityToken != nil,
              let container = fileManager.url(forUbiquityContainerIdentifier: Self.containerIdentifier) else { return nil }
        return container.appendingPathComponent("Documents/Backups", isDirectory: true)
    }

    func list(at root: URL) throws -> [URL] {
        let folder = root.appendingPathComponent("Snapshots", isDirectory: true)
        guard fileManager.fileExists(atPath: folder.path) else { return [] }
        return try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    func manifest(at url: URL) async throws -> BackupManifest {
        try await makeAvailable(url)
        let data = try coordinatedRead(url)
        let manifest = try JSONDecoder().decode(BackupManifest.self, from: data)
        guard manifest.version == 1, manifest.entries.count <= 100_000,
              Set(manifest.entries.map(\.id)).count == manifest.entries.count,
              manifest.entries.allSatisfy({ Self.validFilename($0.filename) && $0.checksum.count == 64 && $0.date.timeIntervalSince1970.isFinite }) else {
            throw BackupError.invalidManifest
        }
        return manifest
    }

    func write(
        sources: [BackupSource], to root: URL,
        imageDataAt: @MainActor @Sendable (Int) throws -> Data,
        progress: @Sendable (Double) -> Void
    ) async throws -> (BackupManifest, URL) {
        let photos = root.appendingPathComponent("Photos", isDirectory: true)
        let snapshots = root.appendingPathComponent("Snapshots", isDirectory: true)
        try fileManager.createDirectory(at: photos, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: snapshots, withIntermediateDirectories: true)
        var knownChecksums: [String: String] = [:]
        var previous: (BackupManifest, URL)?
        if let latest = try list(at: root).first,
           let old = try? await manifest(at: latest) {
            previous = (old, latest)
            knownChecksums = Dictionary(old.entries.map { ($0.filename, $0.checksum) }, uniquingKeysWith: { first, _ in first })
        }
        var entries: [BackupManifest.Entry] = []
        for (index, source) in sources.enumerated() {
            try Task.checkCancellation()
            let destination = photos.appendingPathComponent(source.filename)
            let checksum: String
            if let known = knownChecksums[source.filename],
               let existing = try? await photo(.init(id: source.id, imageRevision: source.revision, date: source.date,
                                                     note: source.note, filename: source.filename, checksum: known), root: root),
               Self.checksum(existing) == known {
                checksum = known
            } else {
                let data = try await imageDataAt(index)
                guard Self.isReadableImage(data) else { throw BackupError.invalidPhoto }
                checksum = Self.checksum(data)
                try coordinatedWrite(data, to: destination)
            }
            entries.append(.init(id: source.id, imageRevision: source.revision, date: source.date,
                                 note: source.note, filename: source.filename, checksum: checksum, poseRawValue: source.poseRawValue))
            progress(Double(index + 1) / Double(max(1, sources.count)))
        }
        try Task.checkCancellation()
        if let (old, url) = previous,
           old.entries.count == entries.count,
           zip(old.entries, entries).allSatisfy({ lhs, rhs in
               lhs.id == rhs.id && lhs.imageRevision == rhs.imageRevision && lhs.date == rhs.date &&
               lhs.note == rhs.note && lhs.checksum == rhs.checksum &&
               (lhs.poseRawValue ?? "classic") == rhs.poseRawValue
           }) { return (old, url) }
        let manifest = BackupManifest(id: UUID(), createdAt: Date(), entries: entries)
        let stamp = String(format: "%.0f", manifest.createdAt.timeIntervalSince1970 * 1000)
        let destination = snapshots.appendingPathComponent("\(stamp)-\(manifest.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        // Publish the manifest only after every referenced photo has a local iCloud copy.
        try coordinatedWrite(try encoder.encode(manifest), to: destination)
        return (manifest, destination)
    }

    func photo(_ entry: BackupManifest.Entry, root: URL) async throws -> Data {
        guard Self.validFilename(entry.filename) else { throw BackupError.invalidManifest }
        let url = root.appendingPathComponent("Photos", isDirectory: true).appendingPathComponent(entry.filename)
        try await makeAvailable(url)
        let data = try coordinatedRead(url)
        guard Self.checksum(data) == entry.checksum, Self.isReadableImage(data) else { throw BackupError.invalidPhoto }
        return data
    }

    func isFullyUploaded(_ manifest: BackupManifest, url: URL, root: URL) throws -> Bool {
        let urls = [url] + manifest.entries.map { root.appendingPathComponent("Photos").appendingPathComponent($0.filename) }
        for var item in urls {
            item.removeAllCachedResourceValues()
            let values = try item.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey, .ubiquitousItemUploadingErrorKey])
            if let error = values.ubiquitousItemUploadingError { throw error }
            guard values.ubiquitousItemIsUploaded == true else { return false }
        }
        return true
    }

    private func makeAvailable(_ url: URL) async throws {
        if fileManager.isUbiquitousItem(at: url) {
            try fileManager.startDownloadingUbiquitousItem(at: url)
            for _ in 0..<50 {
                try Task.checkCancellation()
                let status = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]).ubiquitousItemDownloadingStatus
                if status == .current || status == .downloaded { return }
                try await Task.sleep(for: .milliseconds(200))
            }
            throw BackupError.downloading
        }
    }

    private func coordinatedRead(_ url: URL) throws -> Data {
        var coordinationError: NSError?
        var result: Result<Data, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { target in
            result = Result { try Data(contentsOf: target) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw BackupError.invalidManifest }
        return try result.get()
    }

    private func coordinatedWrite(_ data: Data, to url: URL) throws {
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { target in
            do { try data.write(to: target, options: .atomic) }
            catch { writeError = error }
        }
        if let coordinationError { throw coordinationError }
        if let writeError { throw writeError }
    }

    nonisolated static func validFilename(_ value: String) -> Bool {
        // Accept only our generated UUID-revision JPEG names; a manifest cannot traverse directories.
        let pieces = value.dropLast(4).split(separator: "-")
        guard value.hasSuffix(".jpg"), value.count == 77, pieces.count == 10 else { return false }
        return UUID(uuidString: String(value.prefix(36))) != nil && UUID(uuidString: String(value.dropFirst(37).prefix(36))) != nil
    }

    nonisolated static func checksum(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func isReadableImage(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return false }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 32
        ] as CFDictionary) != nil
    }
}
