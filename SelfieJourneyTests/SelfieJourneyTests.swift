import Foundation
import SwiftData
import Testing
@testable import SelfieJourney

struct SelfieJourneyTests {
    private func calendar(_ timeZone: String = "America/Toronto") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    @Test func currentStreakDeduplicatesDaysAndKeepsYesterdayGrace() {
        let now = date("2026-09-05T16:00:00Z")
        let portraits = [
            date("2026-09-02T14:00:00Z"),
            date("2026-09-03T14:00:00Z"),
            date("2026-09-04T14:00:00Z"),
            date("2026-09-04T19:00:00Z")
        ]
        #expect(StreakCalculator.currentStreak(dates: portraits, now: now, calendar: calendar()) == 3)
        #expect(StreakCalculator.currentStreak(dates: portraits + [now], now: now, calendar: calendar()) == 4)
    }

    @Test func aMissedDayResetsCurrentButPreservesLongest() {
        let portraits = ["2026-09-01T14:00:00Z", "2026-09-02T14:00:00Z", "2026-09-03T14:00:00Z"].map(date)
        let now = date("2026-09-05T16:00:00Z")
        #expect(StreakCalculator.currentStreak(dates: portraits, now: now, calendar: calendar()) == 0)
        #expect(StreakCalculator.longestStreak(dates: portraits, now: now, calendar: calendar()) == 3)
    }

    @Test func futurePortraitsNeverExtendAStreak() {
        let now = date("2026-09-05T16:00:00Z")
        let future = [date("2026-09-05T17:00:00Z"), date("2026-09-06T14:00:00Z")]
        #expect(StreakCalculator.currentStreak(dates: future, now: now, calendar: calendar()) == 0)
        #expect(StreakCalculator.longestStreak(dates: future + [now], now: now, calendar: calendar()) == 1)
        #expect(StreakCalculator.longestStreak(dates: [], now: now, calendar: calendar()) == 0)
    }

    @Test func streaksFollowLocalDaysAcrossUTCMidnight() {
        let portraits = [date("2026-09-05T03:45:00Z"), date("2026-09-05T04:15:00Z")]
        let now = date("2026-09-05T05:00:00Z")
        #expect(StreakCalculator.currentStreak(dates: portraits, now: now, calendar: calendar()) == 2)
        #expect(StreakCalculator.currentStreak(dates: portraits, now: now, calendar: calendar("UTC")) == 1)
    }

    @Test(arguments: [
        ["2026-03-07T17:00:00Z", "2026-03-08T16:00:00Z", "2026-03-09T16:00:00Z"],
        ["2026-10-31T16:00:00Z", "2026-11-01T17:00:00Z", "2026-11-02T17:00:00Z"]
    ])
    func streaksCrossDaylightSavingWithoutAssuming24HourDays(values: [String]) {
        let portraits = values.map(date)
        let now = portraits.last!
        #expect(StreakCalculator.currentStreak(dates: portraits, now: now, calendar: calendar()) == 3)
        #expect(StreakCalculator.longestStreak(dates: portraits, now: now, calendar: calendar()) == 3)
    }

    @Test @MainActor func reminderSkipsCompletedTodayAndTimesAlreadyPassed() {
        let now = date("2026-09-05T12:00:00Z")
        let beforeReminder = ReminderManager.scheduledDates(hour: 9, minute: 0, portraitDates: [], now: now, calendar: calendar())
        #expect(beforeReminder.count == 30)
        #expect(beforeReminder.first == date("2026-09-05T13:00:00Z"))
        let completed = ReminderManager.scheduledDates(hour: 9, minute: 0, portraitDates: [now], now: now, calendar: calendar())
        #expect(completed.count == 29)
        #expect(completed.first == date("2026-09-06T13:00:00Z"))
        let afterReminder = ReminderManager.scheduledDates(hour: 9, minute: 0, portraitDates: [], now: date("2026-09-05T14:00:00Z"), calendar: calendar())
        #expect(afterReminder.first == completed.first)
    }

    @Test @MainActor func reminderRecoversFromSkippedSpringClockTime() {
        let dates = ReminderManager.scheduledDates(
            hour: 2,
            minute: 30,
            portraitDates: [],
            now: date("2026-03-07T15:00:00Z"),
            calendar: calendar(),
            days: 3
        )
        #expect(dates.count == 2)
        #expect(dates.first == date("2026-03-08T07:00:00Z"))
        #expect(dates.last == date("2026-03-09T06:30:00Z"))
    }

    @Test @MainActor func portraitCanBePersistedFetchedUpdatedAndDeleted() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Portrait.self, configurations: configuration)
        let context = ModelContext(container)
        let recordedAt = date("2026-09-05T14:00:00Z")
        let portrait = Portrait(date: recordedAt, imageData: Data([1, 2, 3]), note: "A fresh start")
        let id = portrait.id
        context.insert(portrait)
        try context.save()

        let readContext = ModelContext(container)
        let saved = try #require(readContext.fetch(FetchDescriptor<Portrait>()).first)
        #expect(saved.id == id)
        #expect(saved.date == recordedAt)
        #expect(saved.imageData == Data([1, 2, 3]))
        #expect(saved.note == "A fresh start")

        saved.note = "One small moment"
        saved.imageData = Data([4, 5, 6])
        try readContext.save()
        let updatedContext = ModelContext(container)
        let updated = try #require(updatedContext.fetch(FetchDescriptor<Portrait>()).first)
        #expect(updated.note == "One small moment")
        #expect(updated.imageData == Data([4, 5, 6]))

        updatedContext.delete(updated)
        try updatedContext.save()
        #expect(try updatedContext.fetchCount(FetchDescriptor<Portrait>()) == 0)
    }

    @Test @MainActor func retakingAPortraitUpdatesTheSameLocalDayAndKeepsItsIdentity() throws {
        let container = try ModelContainer(
            for: Portrait.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        let firstDate = date("2026-09-05T14:00:00Z")
        let first = try PortraitStore.save(
            imageData: Data([1, 2, 3]), note: "  A fresh start\n", date: firstDate,
            context: context, calendar: calendar()
        )
        let originalID = first.id
        let originalRevision = first.imageRevision
        #expect(first.note == "A fresh start")

        // These timestamps have different UTC dates but share September 5 in Toronto.
        let retake = try PortraitStore.save(
            imageData: Data([4, 5, 6]), note: "\n A quiet evening  ",
            date: date("2026-09-06T02:00:00Z"), pose: .wide, context: context, calendar: calendar()
        )
        #expect(try context.fetchCount(FetchDescriptor<Portrait>()) == 1)
        #expect(retake.id == originalID)
        #expect(retake.date == firstDate)
        #expect(retake.imageRevision != originalRevision)
        #expect(retake.imageData == Data([4, 5, 6]))
        #expect(retake.note == "A quiet evening")
        #expect(retake.poseRawValue == "wide")

        let nextDay = try PortraitStore.save(
            imageData: Data([7, 8, 9]), note: "  \n  ",
            date: date("2026-09-06T04:30:00Z"), context: context, calendar: calendar()
        )
        #expect(nextDay.id != originalID)
        #expect(nextDay.note.isEmpty)
        let readContext = ModelContext(container)
        let persisted = try readContext.fetch(FetchDescriptor<Portrait>(sortBy: [SortDescriptor(\Portrait.date)]))
        #expect(persisted.count == 2)
        #expect(persisted.first?.id == originalID)
        #expect(persisted.first?.imageData == Data([4, 5, 6]))
        #expect(persisted.first?.date == firstDate)
        #expect(persisted.first?.poseRawValue == "wide")
        #expect(persisted.last?.id == nextDay.id)
    }

    @Test @MainActor func portraitDayBoundaryFollowsCalendarInsteadOf24HoursAcrossDST() throws {
        let container = try ModelContainer(
            for: Portrait.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        let first = try PortraitStore.save(
            imageData: Data([1]), note: "", date: date("2026-03-08T05:15:00Z"),
            context: context, calendar: calendar()
        )
        let firstID = first.id
        // March 8 is 23 hours long in Toronto. The following UTC day still
        // belongs to the same local date until 04:00 UTC.
        let evening = try PortraitStore.save(
            imageData: Data([2]), note: "", date: date("2026-03-09T03:45:00Z"),
            context: context, calendar: calendar()
        )
        #expect(evening.id == firstID)
        let followingDay = try PortraitStore.save(
            imageData: Data([3]), note: "", date: date("2026-03-09T04:15:00Z"),
            context: context, calendar: calendar()
        )
        #expect(followingDay.id != firstID)
        #expect(try context.fetchCount(FetchDescriptor<Portrait>()) == 2)
    }
}
