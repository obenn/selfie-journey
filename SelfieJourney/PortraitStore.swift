import Foundation
import SwiftData

/// Keep one portrait per local day, including days that cross a clock change.
@MainActor
enum PortraitStore {
    @discardableResult
    static func save(
        imageData: Data,
        note: String,
        date: Date = Date(),
        pose: PortraitPose = .classic,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> Portrait {
        guard let day = calendar.dateInterval(of: .day, for: date) else {
            throw SaveError.invalidDate
        }
        let start = day.start
        let end = day.end
        var descriptor = FetchDescriptor<Portrait>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\Portrait.date)]
        )
        descriptor.fetchLimit = 1

        do {
            let portrait: Portrait
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if let existing = try context.fetch(descriptor).first {
                existing.imageData = imageData
                existing.imageRevision = UUID()
                existing.note = trimmedNote
                existing.poseRawValue = pose.rawValue
                portrait = existing
            } else {
                portrait = Portrait(date: date, imageData: imageData, note: trimmedNote, pose: pose)
                context.insert(portrait)
            }
            try context.save()
            return portrait
        } catch {
            context.rollback()
            throw error
        }
    }

    private enum SaveError: LocalizedError {
        case invalidDate

        var errorDescription: String? {
            "This portrait's date could not be saved. Please try again."
        }
    }
}
