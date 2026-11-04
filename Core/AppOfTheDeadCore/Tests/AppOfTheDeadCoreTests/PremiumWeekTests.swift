import Foundation
import Testing
@testable import AppOfTheDeadCore

@Suite("Premium Week")
struct PremiumWeekTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func noStartMeansNotStarted() {
        #expect(PremiumWeek.phase(start: nil, now: start) == .notStarted)
    }

    @Test func activeForSevenDays() {
        let end = start.addingTimeInterval(PremiumWeek.length)
        #expect(PremiumWeek.phase(start: start, now: start) == .active(endsAt: end))
        #expect(PremiumWeek.phase(start: start, now: end.addingTimeInterval(-1)) == .active(endsAt: end))
        #expect(PremiumWeek.phase(start: start, now: end) == .over(endedAt: end))
    }

    @Test func clockWoundBackReadsAsTheFirstMoment() {
        let phase = PremiumWeek.phase(start: start, now: start.addingTimeInterval(-86_400 * 30))
        #expect(phase.isActive)
    }

    @Test func daysLeftRoundsUpAndNeverReadsZero() {
        let end = start.addingTimeInterval(PremiumWeek.length)
        #expect(PremiumWeek.daysLeft(until: end, now: start) == 7)
        #expect(PremiumWeek.daysLeft(until: end, now: start.addingTimeInterval(1)) == 7)
        #expect(PremiumWeek.daysLeft(until: end, now: end.addingTimeInterval(-60)) == 1)
        #expect(PremiumWeek.daysLeft(until: end, now: end.addingTimeInterval(60)) == 1)
    }
}
