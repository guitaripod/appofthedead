import XCTest
import AppOfTheDeadCore
@testable import aotd

@MainActor final class PremiumWeekPassTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "PremiumWeekPassTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private final class Clock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    private func makePass(_ clock: Clock) -> PremiumWeekPass {
        PremiumWeekPass(store: .local(defaults: defaults), now: { clock.now }, notifications: NotificationCenter())
    }

    func testStartsOnceAndRunsSevenDays() {
        let clock = Clock()
        let pass = makePass(clock)
        XCTAssertTrue(pass.start(ownsAllAccess: false))
        XCTAssertFalse(pass.start(ownsAllAccess: false))
        XCTAssertEqual(pass.daysLeft, 7)
        clock.now = clock.now.addingTimeInterval(6.5 * 86_400)
        XCTAssertEqual(pass.daysLeft, 1)
        clock.now = clock.now.addingTimeInterval(86_400)
        XCTAssertFalse(pass.isActive)
        XCTAssertNil(pass.daysLeft)
        XCTAssertFalse(pass.start(ownsAllAccess: false), "an ended week never comes back")
    }

    func testNeverStartsForABuyer() {
        let pass = makePass(Clock())
        XCTAssertFalse(pass.start(ownsAllAccess: true))
        XCTAssertEqual(pass.phase, .notStarted)
    }

    func testTheEndIsAnnouncedOnceAndNeverToABuyer() {
        let clock = Clock()
        let pass = makePass(clock)
        pass.start(ownsAllAccess: false)
        XCTAssertFalse(pass.takeEndAnnouncement(ownsAllAccess: false), "nothing to announce while it runs")
        clock.now = clock.now.addingTimeInterval(PremiumWeek.length + 60)
        XCTAssertFalse(pass.takeEndAnnouncement(ownsAllAccess: true))
        XCTAssertTrue(pass.takeEndAnnouncement(ownsAllAccess: false))
        XCTAssertFalse(pass.takeEndAnnouncement(ownsAllAccess: false))
    }

    func testTheWeekOpensEveryPathAndTheOracle() {
        let clock = Clock()
        let pass = makePass(clock)
        let access = StoreAccess(store: nil, cache: EntitlementCache(defaults: defaults), notifications: NotificationCenter(), premiumWeek: pass)
        XCTAssertFalse(access.hasPathAccess("norse"))
        XCTAssertFalse(access.hasUnlimitedOracle)
        pass.start(ownsAllAccess: false)
        XCTAssertTrue(access.hasPathAccess("norse"))
        XCTAssertTrue(access.hasUnlimitedOracle)
        XCTAssertTrue(access.hasEverythingOpen)
        XCTAssertFalse(access.hasAllAccess, "a lent week owns nothing")
    }
}
