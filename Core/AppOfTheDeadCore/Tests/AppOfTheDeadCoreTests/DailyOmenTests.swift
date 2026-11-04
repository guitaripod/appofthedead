import Foundation
import Testing
@testable import AppOfTheDeadCore

@Suite("Daily Omen")
struct DailyOmenTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Helsinki")!
        return calendar
    }

    @Test func dayNumbersCountFromTheFirstOf2026() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23))!
        let later = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 0, minute: 5))!
        #expect(DailyOmenSchedule.dayNumber(for: start, calendar: calendar) == 0)
        #expect(DailyOmenSchedule.dayNumber(for: later, calendar: calendar) == 307)
        #expect(DailyOmenSchedule.dayKey(for: later, calendar: calendar) == "2026-11-04")
    }

    @Test func everyQuestionHasItsDayBeforeAnyRepeats() {
        let count = 1_056
        let picks = (0..<count).compactMap { DailyOmenSchedule.index(forDay: $0, count: count) }
        #expect(Set(picks).count == count)
        #expect(DailyOmenSchedule.index(forDay: count, count: count) == picks[0])
    }

    @Test func neighbouringDaysAreFarApart() {
        let count = 1_056
        for day in 0..<60 {
            let today = DailyOmenSchedule.index(forDay: day, count: count)!
            let tomorrow = DailyOmenSchedule.index(forDay: day + 1, count: count)!
            #expect(abs(today - tomorrow) > 6)
        }
    }

    @Test func emptyBankHasNoQuestion() {
        #expect(DailyOmenSchedule.index(forDay: 3, count: 0) == nil)
        #expect(DailyOmenSchedule.index(forDay: -4, count: 10).map { (0..<10).contains($0) } == true)
    }
}
