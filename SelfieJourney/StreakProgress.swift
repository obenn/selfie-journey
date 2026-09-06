import Foundation

/// Presentation milestones always follow the actual consecutive-day streak.
/// A missed day never removes the portraits already collected.
nonisolated struct StreakProgress: Equatable {
    static let milestones = [3, 7, 14, 30, 100, 365]

    let streak: Int
    let hasPortraits: Bool
    let completedToday: Bool

    var nextMilestone: Int {
        Self.milestones.first { $0 > streak } ?? ((max(streak, 0) / 365) + 1) * 365
    }

    var fractionComplete: Double {
        min(max(Double(streak) / Double(nextMilestone), 0), 1)
    }

    var daysToMilestone: Int { nextMilestone - max(streak, 0) }

    var milestoneLabel: String {
        switch nextMilestone {
        case 3: "A little rhythm"
        case 7: "A week of you"
        case 14: "A growing habit"
        case 30: "One lovely month"
        case 100: "A hundred moments"
        case 365: "A year of you"
        default: "Another year of you"
        }
    }

    var encouragement: String {
        if completedToday { return "Today is kept. Come back as you are tomorrow." }
        if streak > 0 { return "One little portrait keeps your story growing." }
        return hasPortraits
            ? "Welcome back. Your story carries on from here."
            : "Every journey begins with one little portrait."
    }

    static func isMilestone(_ streak: Int) -> Bool {
        milestones.contains(streak) || (streak > 365 && streak.isMultiple(of: 365))
    }

    static func celebrationTitle(streak: Int, isRetake: Bool) -> String {
        if isRetake { return "Today, beautifully kept." }
        if isMilestone(streak) { return "\(streak) days. Look at you grow." }
        if streak == 1 { return "Your journey starts here." }
        if streak > 1 { return "\(streak) days of showing up." }
        return "A little moment, kept."
    }
}
