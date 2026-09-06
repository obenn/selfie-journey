import Foundation
import Testing
import UIKit
@testable import SelfieJourney

struct BackupArchiveTests {
    @Test @MainActor func roundtripPreservesPortraitMetadataAndExactImageBytes() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let sources = [
            source(note: "Morning light — a new chapter ☀️"),
            source(date: Date(timeIntervalSince1970: 1_700_086_400), note: "Second day", poseRawValue: "close")
        ]
        let images = [try imageData(color: .red), try imageData(color: .blue)]

        let (written, url) = try await archive.write(sources: sources, to: root, imageDataAt: { images[$0] }, progress: { _ in })
        let loaded = try await archive.manifest(at: url)
        #expect(loaded.id == written.id)
        #expect(loaded.createdAt == written.createdAt)
        #expect(loaded.version == 1)
        #expect(loaded.entries.count == 2)
        for index in sources.indices {
            let entry = loaded.entries[index]
            let original = sources[index]
            #expect(entry.id == original.id)
            #expect(entry.imageRevision == original.revision)
            #expect(entry.date == original.date)
            #expect(entry.note == original.note)
            #expect(entry.poseRawValue == original.poseRawValue)
            #expect(entry.filename == original.filename)
            #expect(entry.checksum == BackupArchive.checksum(images[index]))
            #expect(try await archive.photo(entry, root: root) == images[index])
        }
        #expect(try await archive.list(at: root) == [url])
    }

    @Test @MainActor func unchangedJournalReusesSnapshotAndEditsKeepHistoricalAssets() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let original = source(note: "First note")
        let originalImage = try imageData(color: .red)
        let (first, firstURL) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in originalImage }, progress: { _ in })

        let (unchanged, unchangedURL) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in
            throw ProviderFailure.unexpectedRead
        }, progress: { _ in })
        #expect(unchanged.id == first.id)
        #expect(unchangedURL == firstURL)
        #expect(try await archive.list(at: root).count == 1)

        let edited = source(id: original.id, revision: original.revision, date: original.date, note: "A better description")
        let (second, _) = try await archive.write(sources: [edited], to: root, imageDataAt: { _ in
            throw ProviderFailure.unexpectedRead
        }, progress: { _ in })
        #expect(second.id != first.id)
        #expect(second.entries[0].filename == first.entries[0].filename)
        #expect(try await archive.manifest(at: firstURL).entries[0].note == "First note")
        #expect(second.entries[0].note == "A better description")
        #expect(try photoFiles(at: root).count == 1)

        let retake = source(id: original.id, date: original.date, note: edited.note)
        let retakeImage = try imageData(color: .blue)
        let (third, _) = try await archive.write(sources: [retake], to: root, imageDataAt: { _ in retakeImage }, progress: { _ in })
        #expect(third.entries[0].filename != first.entries[0].filename)
        #expect(try await archive.photo(first.entries[0], root: root) == originalImage)
        #expect(try await archive.photo(third.entries[0], root: root) == retakeImage)
        #expect(try photoFiles(at: root).count == 2)
        #expect(try await archive.list(at: root).count == 3)
    }

    @Test @MainActor func laterBackupRepairsDamagedReusableAssetFromJournal() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let original = source()
        let image = try imageData(color: .green)
        let (first, firstURL) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in image }, progress: { _ in })
        let photoURL = root.appendingPathComponent("Photos").appendingPathComponent(original.filename)
        try Data([0, 1, 2]).write(to: photoURL)

        let (repaired, repairedURL) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in image }, progress: { _ in })
        #expect(try await archive.photo(repaired.entries[0], root: root) == image)
        #expect(try await archive.photo(first.entries[0], root: root) == image)
        #expect(repairedURL == firstURL)
        #expect(try await archive.list(at: root).count == 1)
    }

    @Test @MainActor func legacySnapshotWithoutPoseStillReadsAndMatchesClassicPose() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let original = source()
        let image = try imageData(color: .green)
        let (written, url) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in image }, progress: { _ in })
        var legacy = written
        legacy.entries[0].poseRawValue = nil
        try JSONEncoder().encode(legacy).write(to: url)

        let decoded = try await archive.manifest(at: url)
        #expect(decoded.entries[0].poseRawValue == nil)
        #expect(try await archive.photo(decoded.entries[0], root: root) == image)
        let (reused, reusedURL) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in
            throw ProviderFailure.unexpectedRead
        }, progress: { _ in })
        #expect(reused.id == legacy.id)
        #expect(reusedURL == url)
    }

    @Test func generatedFilenamesAreAcceptedButPathsAndLookalikesAreRejected() {
        let filename = source().filename
        #expect(BackupArchive.validFilename(filename))
        let invalid = [
            "../" + filename, "Photos/" + filename, "/" + filename,
            "..%2f" + filename, "file:///" + filename, filename + "/..",
            filename.replacingOccurrences(of: ".jpg", with: ".png"),
            filename.replacingOccurrences(of: ".jpg", with: ".JPG"),
            "not-a-uuid-not-a-revision.jpg", "", ".jpg"
        ]
        for value in invalid { #expect(!BackupArchive.validFilename(value), "Reject \(value)") }
    }

    @Test @MainActor func manifestRejectsUnsupportedVersionsDuplicateIDsAndTraversal() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let image = try imageData(color: .orange)
        let (valid, _) = try await archive.write(sources: [source(), source()], to: root, imageDataAt: { _ in image }, progress: { _ in })
        var unsupported = valid
        unsupported.version = 99
        var duplicate = valid
        duplicate.entries[1].id = duplicate.entries[0].id
        var traversal = valid
        traversal.entries[0].filename = "../" + traversal.entries[0].filename
        var truncatedChecksum = valid
        truncatedChecksum.entries[0].checksum = "abc"

        for manifest in [unsupported, duplicate, traversal, truncatedChecksum] {
            let url = root.appendingPathComponent("invalid-\(UUID().uuidString).json")
            try JSONEncoder().encode(manifest).write(to: url)
            do {
                _ = try await archive.manifest(at: url)
                Issue.record("An invalid manifest must not be accepted for restore.")
            } catch BackupError.invalidManifest {
                // Validation happens before the restore can mutate the local journal.
            }
        }
        do {
            _ = try await archive.photo(traversal.entries[0], root: root)
            Issue.record("Direct photo reads must also reject traversal.")
        } catch BackupError.invalidManifest {}
    }

    @Test @MainActor func photoRejectsChangedBytesEvenWhenTheyStillDecodeAsAnImage() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let original = source()
        let image = try imageData(color: .red)
        let (manifest, _) = try await archive.write(sources: [original], to: root, imageDataAt: { _ in image }, progress: { _ in })
        let photoURL = root.appendingPathComponent("Photos").appendingPathComponent(original.filename)
        try imageData(color: .blue).write(to: photoURL)
        do {
            _ = try await archive.photo(manifest.entries[0], root: root)
            Issue.record("A valid but altered JPEG must fail its stored checksum.")
        } catch BackupError.invalidPhoto {}

        let unreadable = Data("not a portrait".utf8)
        try unreadable.write(to: photoURL)
        var entry = manifest.entries[0]
        entry.checksum = BackupArchive.checksum(unreadable)
        do {
            _ = try await archive.photo(entry, root: root)
            Issue.record("Matching checksums must not let non-image data into a restore.")
        } catch BackupError.invalidPhoto {}
    }

    @Test @MainActor func failedImageReadDoesNotPublishAPartialSnapshot() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = BackupArchive()
        let image = try imageData(color: .orange)
        do {
            _ = try await archive.write(sources: [source(), source()], to: root, imageDataAt: { index in
                if index == 1 { throw ProviderFailure.unavailable }
                return image
            }, progress: { _ in })
            Issue.record("A backup cannot succeed when an image cannot be read.")
        } catch ProviderFailure.unavailable {}
        #expect(try await archive.list(at: root).isEmpty)

        do {
            _ = try await archive.write(sources: [source()], to: root, imageDataAt: { _ in Data([1, 2, 3]) }, progress: { _ in })
            Issue.record("Unreadable images cannot be published in a snapshot.")
        } catch BackupError.invalidPhoto {}
        #expect(try await archive.list(at: root).isEmpty)
    }

    private func source(id: UUID = UUID(), revision: UUID = UUID(), date: Date = Date(timeIntervalSince1970: 1_700_000_000), note: String = "", poseRawValue: String = "classic") -> BackupSource {
        BackupSource(id: id, revision: revision, date: date, note: note, poseRawValue: poseRawValue)
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("SelfieJourney-BackupTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func photoFiles(at root: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: root.appendingPathComponent("Photos"), includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "jpg" }
    }

    @MainActor private func imageData(color: UIColor) throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 40)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 40))
        }
        return try #require(image.jpegData(compressionQuality: 0.9))
    }

    private enum ProviderFailure: Error { case unexpectedRead, unavailable }
}
