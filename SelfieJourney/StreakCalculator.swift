import Foundation

enum StreakCalculator {
    /// Yesterday keeps a streak alive until the end of today. Taking another
    /// portrait on the same local day never adds another day to the streak.
    static func currentStreak(
        dates: [Date],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let days = recordedDays(dates, now: now, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return days.contains(today) ? 1 : 0
        }
        var cursor = days.contains(today) ? today : yesterday
        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func longestStreak(
        dates: [Date],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let days = recordedDays(dates, now: now, calendar: calendar).sorted()
        var previous: Date?
        var current = 0
        var longest = 0
        for day in days {
            if let previous,
               calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = day
        }
        return longest
    }

    private static func recordedDays(_ dates: [Date], now: Date, calendar: Calendar) -> Set<Date> {
        Set(dates.filter { $0 <= now }.map { calendar.startOfDay(for: $0) })
    }
}
