import Testing
@testable import SelfieJourney

struct StreakProgressTests {
    @Test(arguments: [(0, 3), (2, 3), (3, 7), (7, 14), (14, 30), (30, 100), (100, 365), (365, 730), (730, 1095)])
    func milestoneAdvancesOnlyAfterTheThresholdIsReached(streak: Int, expected: Int) {
        let progress = StreakProgress(streak: streak, hasPortraits: streak > 0, completedToday: false)
        #expect(progress.nextMilestone == expected)
        #expect(progress.daysToMilestone == expected - streak)
        #expect(progress.fractionComplete == Double(streak) / Double(expected))
    }

    @Test func firstDayShowsZeroProgressAndReturningUserKeepsSupportiveCopy() {
        let firstDay = StreakProgress(streak: 0, hasPortraits: false, completedToday: false)
        let returning = StreakProgress(streak: 0, hasPortraits: true, completedToday: false)
        #expect(firstDay.fractionComplete == 0)
        #expect(firstDay.daysToMilestone == 3)
        #expect(firstDay.encouragement != returning.encouragement)
        #expect(returning.encouragement == "Welcome back. Your story carries on from here.")
    }

    @Test func milestoneCelebrationIsNotRepeatedForARetake() {
        #expect(StreakProgress.isMilestone(3))
        #expect(StreakProgress.isMilestone(365))
        #expect(StreakProgress.isMilestone(730))
        #expect(!StreakProgress.isMilestone(0))
        #expect(!StreakProgress.isMilestone(8))
        #expect(StreakProgress.celebrationTitle(streak: 7, isRetake: false) == "7 days. Look at you grow.")
        #expect(StreakProgress.celebrationTitle(streak: 7, isRetake: true) == "Today, beautifully kept.")
    }
}
