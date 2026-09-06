import Foundation
import SwiftData
import Testing
import UIKit
@testable import SelfieJourney

struct CloudBackupRestoreTests {
    @Test @MainActor func restoreMergesMissingDaysAndPreservesLocalPortraitsAndPose() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("JourneyRestore-\(UUID())")
        let suite = "JourneyRestore-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        let archive = BackupArchive()
        let day = Calendar.current.startOfDay(for: Date())
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: day))
        let images = [try jpeg(.red), try jpeg(.blue)]
        let sources = [
            BackupSource(id: UUID(), revision: UUID(), date: yesterday, note: "An earlier chapter", poseRawValue: "wide"),
            BackupSource(id: UUID(), revision: UUID(), date: day, note: "Cloud's version")
        ]
        let (_, url) = try await archive.write(sources: sources, to: root, imageDataAt: { images[$0] }, progress: { _ in })
        let container = try ModelContainer(for: Portrait.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = ModelContext(container)
        let existing = Portrait(date: day.addingTimeInterval(60), imageData: try jpeg(.green), note: "Keep this one", pose: .close)
        let existingID = existing.id
        context.insert(existing)
        try context.save()
        let manager = CloudBackupManager(defaults: defaults, archiveRoot: root)
        await manager.refresh()
        await manager.restore(BackupSummary(url: url), into: context)
        #expect(manager.errorMessage == nil)
        #expect(manager.restorationMessage?.contains("Restored 1 missing portrait") == true)
        let results = try context.fetch(FetchDescriptor<Portrait>(sortBy: [SortDescriptor(\Portrait.date)]))
        #expect(results.count == 2)
        #expect(results[0].id == sources[0].id)
        #expect(results[0].imageRevision == sources[0].revision)
        #expect(results[0].imageData == images[0])
        #expect(results[0].note == sources[0].note)
        #expect(results[0].poseRawValue == "wide")
        #expect(results[1].id == existingID)
        #expect(results[1].note == "Keep this one")
        #expect(results[1].poseRawValue == "close")
        await manager.restore(BackupSummary(url: url), into: context)
        #expect(try context.fetchCount(FetchDescriptor<Portrait>()) == 2)
        #expect(manager.restorationMessage?.contains("already in your journal") == true)
    }

    @Test @MainActor func damagedBackupStopsSafelyAndCanResumeAfterRepair() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("JourneyRestore-\(UUID())")
        let suite = "JourneyRestore-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        let archive = BackupArchive()
        let day = Calendar.current.startOfDay(for: Date())
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: day))
        let images = [try jpeg(.red), try jpeg(.blue)]
        let sources = [
            BackupSource(id: UUID(), revision: UUID(), date: yesterday, note: "First"),
            BackupSource(id: UUID(), revision: UUID(), date: day, note: "Second")
        ]
        let (_, url) = try await archive.write(sources: sources, to: root, imageDataAt: { images[$0] }, progress: { _ in })
        let damaged = root.appendingPathComponent("Photos").appendingPathComponent(sources[1].filename)
        try Data([0, 1]).write(to: damaged)
        let container = try ModelContainer(for: Portrait.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = ModelContext(container)
        let manager = CloudBackupManager(defaults: defaults, archiveRoot: root)
        await manager.refresh()
        await manager.restore(BackupSummary(url: url), into: context)
        #expect(manager.errorMessage?.contains("1 portraits restored so far") == true)
        #expect(try context.fetchCount(FetchDescriptor<Portrait>()) == 1)
        #expect(!manager.busy)
        try images[1].write(to: damaged)
        manager.errorMessage = nil
        await manager.restore(BackupSummary(url: url), into: context)
        #expect(manager.errorMessage == nil)
        #expect(try context.fetchCount(FetchDescriptor<Portrait>()) == 2)
    }

    @MainActor private func jpeg(_ color: UIColor) throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 40)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 30, height: 40))
        }
        return try #require(image.jpegData(compressionQuality: 0.9))
    }
}
