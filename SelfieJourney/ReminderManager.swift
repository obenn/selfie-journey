import Foundation
import Observation
import UserNotifications

/// A rolling 30-day window of individual notifications lets a saved portrait
/// cancel only today's nudge. Refresh on activation and collection changes.
@Observable
@MainActor
final class ReminderManager {
    private(set) var enabled: Bool
    private(set) var hour: Int
    private(set) var minute: Int
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let center: UNUserNotificationCenter
    @ObservationIgnored private let notificationIDs: [String]
    @ObservationIgnored private var portraitDates: [Date]
    @ObservationIgnored private var schedulingTask: Task<Void, Error>?

    private enum Keys {
        static let enabled = "dailyReminder.enabled"
        static let hour = "dailyReminder.hour"
        static let minute = "dailyReminder.minute"
        static let lastPortrait = "dailyReminder.lastPortrait"
    }

    init(defaults: UserDefaults? = nil, center: UNUserNotificationCenter = .current()) {
        let storage: UserDefaults
        let prefix: String
        #if DEBUG
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        if let defaults {
            storage = defaults
        } else if isUITesting {
            let suiteName = "com.picaday.ui-testing.reminders"
            storage = UserDefaults(suiteName: suiteName)!
            storage.removePersistentDomain(forName: suiteName)
        } else {
            storage = .standard
        }
        prefix = isUITesting ? "picaday.ui-testing.daily" : "picaday.daily"
        #else
        storage = defaults ?? .standard
        prefix = "picaday.daily"
        #endif
        self.defaults = storage
        self.center = center
        notificationIDs = (0..<30).map { "\(prefix).\($0)" }
        enabled = storage.bool(forKey: Keys.enabled)
        hour = storage.object(forKey: Keys.hour) == nil ? 9 : min(23, max(0, storage.integer(forKey: Keys.hour)))
        minute = min(59, max(0, storage.integer(forKey: Keys.minute)))
        portraitDates = (storage.object(forKey: Keys.lastPortrait) as? Date).map { [$0] } ?? []
    }

    var date: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    var status: String {
        guard enabled else { return "A gentle daily nudge, on your terms." }
        switch authorizationStatus {
        case .denied:
            return "Allow notifications in Settings to receive your reminder."
        case .notDetermined:
            return "Allow notifications to receive your daily reminder."
        default:
            return "Every day at \(date.formatted(date: .omitted, time: .shortened)). Today's nudge disappears once you save."
        }
    }

    func refreshAuthorization() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    func setReminder(enabled: Bool, time: Date) async throws {
        if enabled {
            await refreshAuthorization()
            if authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
                await refreshAuthorization()
            }
            guard canDeliverNotifications else { throw ReminderError.permissionDenied }
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        hour = components.hour ?? 9
        minute = components.minute ?? 0
        self.enabled = enabled
        persistPreferences()
        try await reschedule()
    }

    /// Call with the complete collection after loading, saving, or deleting.
    func syncPortraitDates(_ dates: [Date]) async throws {
        portraitDates = dates
        defaults.set(dates.filter { $0 <= Date() }.max(), forKey: Keys.lastPortrait)
        await refreshAuthorization()
        try await reschedule()
    }

    private var canDeliverNotifications: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
    }

    private func persistPreferences() {
        defaults.set(enabled, forKey: Keys.enabled)
        defaults.set(hour, forKey: Keys.hour)
        defaults.set(minute, forKey: Keys.minute)
    }

    /// Serialize updates so activation and capture cannot restore stale requests.
    private func reschedule() async throws {
        let previous = schedulingTask
        let task = Task { @MainActor in
            if let previous { _ = try? await previous.value }
            try await self.performReschedule()
        }
        schedulingTask = task
        try await task.value
    }

    private func performReschedule() async throws {
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs)
        center.removeDeliveredNotifications(withIdentifiers: notificationIDs)
        guard enabled, canDeliverNotifications else { return }

        let dates = Self.scheduledDates(hour: hour, minute: minute, portraitDates: portraitDates)
        do {
            for (index, date) in dates.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "A little moment for future you"
                content.body = "Take today's portrait. Your story is growing, one day at a time."
                content.sound = .default
                content.threadIdentifier = "picaday.daily"
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let request = UNNotificationRequest(
                    identifier: notificationIDs[index],
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try await center.add(request)
            }
        } catch {
            center.removePendingNotificationRequests(withIdentifiers: notificationIDs)
            throw error
        }
    }

    /// Calendar arithmetic respects local midnight and daylight-saving changes.
    /// A skipped clock time moves to the next available time on that day;
    /// a repeated clock time uses the first occurrence.
    static func scheduledDates(
        hour: Int,
        minute: Int,
        portraitDates: [Date],
        now: Date = Date(),
        calendar: Calendar = .current,
        days: Int = 30
    ) -> [Date] {
        let today = calendar.startOfDay(for: now)
        let completed = Set(portraitDates.filter { $0 <= now }.map { calendar.startOfDay(for: $0) })
        return (0..<max(0, days)).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  !completed.contains(day),
                  let fireDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: day,
                    matchingPolicy: .nextTime,
                    repeatedTimePolicy: .first,
                    direction: .forward
                  ),
                  calendar.isDate(fireDate, inSameDayAs: day),
                  fireDate > now else { return nil }
            return fireDate
        }
    }

    enum ReminderError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "Notifications are off for Selfie Journey. You can allow them in the Settings app, then turn your reminder on."
        }
    }
}
