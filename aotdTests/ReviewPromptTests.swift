import XCTest
@testable import aotd

final class ReviewPromptTests: XCTestCase {

    private let now = Date()

    private func daysAgo(_ days: Int, from reference: Date? = nil) -> Date {
        (reference ?? now).addingTimeInterval(-Double(days) * 24 * 60 * 60)
    }

    func testNoAskAtFirstSuccess() {
        XCTAssertFalse(ReviewPrompt.shouldAsk(successCount: 1, askDates: [], successCountAtLastAsk: 0, now: now))
    }

    func testAsksAtSecondSuccess() {
        XCTAssertTrue(ReviewPrompt.shouldAsk(successCount: 2, askDates: [], successCountAtLastAsk: 0, now: now))
    }

    func testNoReaskBeforeFourteenDaysEvenWithEnoughNewSuccesses() {
        let lastAsk = daysAgo(13)
        XCTAssertFalse(ReviewPrompt.shouldAsk(
            successCount: 5,
            askDates: [lastAsk],
            successCountAtLastAsk: 2,
            now: now
        ))
    }

    func testNoReaskBeforeThreeNewSuccessesEvenAfterFourteenDays() {
        let lastAsk = daysAgo(20)
        XCTAssertFalse(ReviewPrompt.shouldAsk(
            successCount: 4,
            askDates: [lastAsk],
            successCountAtLastAsk: 2,
            now: now
        ))
    }

    func testReasksAfterBothFourteenDaysAndThreeNewSuccesses() {
        let lastAsk = daysAgo(14)
        XCTAssertTrue(ReviewPrompt.shouldAsk(
            successCount: 5,
            askDates: [lastAsk],
            successCountAtLastAsk: 2,
            now: now
        ))
    }

    func testNeverAFourthAskWithinARollingYear() {
        let askDates = [daysAgo(300), daysAgo(60), daysAgo(15)]
        XCTAssertFalse(ReviewPrompt.shouldAsk(
            successCount: 20,
            askDates: askDates,
            successCountAtLastAsk: 10,
            now: now
        ))
    }

    func testAFourthAskIsAllowedOnceTheOldestAgesOutOfTheRollingYear() {
        let askDates = [daysAgo(370), daysAgo(60), daysAgo(15)]
        XCTAssertTrue(ReviewPrompt.shouldAsk(
            successCount: 20,
            askDates: askDates,
            successCountAtLastAsk: 10,
            now: now
        ))
    }
}
