import XCTest
@testable import aotd

final class ReminderOfferTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "ReminderOfferTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testOfferedOnTheFirstCompletion() {
        XCTAssertTrue(ReminderOffer(defaults: defaults).shouldPresent(priorSuccesses: 0, reminderEnabled: false))
    }

    func testNeverOfferedOnACompletionWhereTheRatingPromptFires() {
        let offer = ReminderOffer(defaults: defaults)

        XCTAssertFalse(offer.shouldPresent(priorSuccesses: ReviewPrompt.firstAskThreshold - 1, reminderEnabled: false))
        XCTAssertFalse(offer.shouldPresent(priorSuccesses: ReviewPrompt.firstAskThreshold, reminderEnabled: false))
    }

    func testOfferedOnlyOnce() {
        let offer = ReminderOffer(defaults: defaults)
        offer.markShown()

        XCTAssertFalse(offer.shouldPresent(priorSuccesses: 0, reminderEnabled: false))
    }

    func testNotOfferedWhenReminderIsAlreadyOn() {
        XCTAssertFalse(ReminderOffer(defaults: defaults).shouldPresent(priorSuccesses: 0, reminderEnabled: true))
    }
}
