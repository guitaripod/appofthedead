import XCTest
@testable import aotd

final class FreePathsTests: XCTestCase {

    private final class InMemoryClaims: PathGiftClaimStore {
        private(set) var keys: Set<String> = []
        func hasClaimed(_ key: String) -> Bool { keys.contains(key) }
        func recordClaim(_ key: String) { keys.insert(key) }
    }

    private var claims: InMemoryClaims!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        claims = InMemoryClaims()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Mexico_City")!
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func freePaths(at date: Date) -> FreePaths {
        FreePaths(claims: claims, calendar: calendar, now: { date })
    }

    func testJudaismIsAlwaysOpen() {
        XCTAssertTrue(freePaths(at: date(2026, 1, 1)).isOpen("judaism"))
        XCTAssertTrue(freePaths(at: date(2030, 6, 1)).isOpen("judaism"))
    }

    func testPaidPathWithoutAnEventStaysClosed() {
        XCTAssertFalse(freePaths(at: date(2026, 10, 28)).isOpen("norse"))
    }

    private func zoneCalendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private func isOpen(in zone: String, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Bool {
        let local = zoneCalendar(zone)
        let date = local.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        return FreePaths(claims: claims, calendar: local, now: { date }).isOpen("aztec-mictlan")
    }

    func testOpensAtLocalMidnightInZonesAheadOfUTC() {
        XCTAssertFalse(isOpen(in: "Asia/Tokyo", 10, 23, 23, 59))
        XCTAssertTrue(isOpen(in: "Asia/Tokyo", 10, 24, 0, 0))
    }

    func testOpensWhenTheUTCDayBeginsInZonesBehindUTC() {
        XCTAssertFalse(isOpen(in: "America/Mexico_City", 10, 23, 17, 59))
        XCTAssertTrue(isOpen(in: "America/Mexico_City", 10, 23, 18, 0))
    }

    func testStaysOpenThroughTheLastLocalDayBehindUTC() {
        XCTAssertTrue(isOpen(in: "America/Mexico_City", 11, 2, 23, 59))
        XCTAssertFalse(isOpen(in: "America/Mexico_City", 11, 3, 0, 0))
    }

    func testStaysOpenThroughTheLastUTCDayAheadOfUTC() {
        XCTAssertTrue(isOpen(in: "Asia/Tokyo", 11, 3, 8, 59))
        XCTAssertFalse(isOpen(in: "Asia/Tokyo", 11, 3, 9, 0))
    }

    func testStartingALessonDuringTheEventKeepsThePathAfterwards() {
        freePaths(at: date(2026, 10, 30)).recordLessonStarted(in: "aztec-mictlan")

        XCTAssertTrue(freePaths(at: date(2026, 12, 15)).isOpen("aztec-mictlan"))
        XCTAssertTrue(freePaths(at: date(2027, 11, 1)).isOpen("aztec-mictlan"))
    }

    func testStartingALessonOutsideTheEventClaimsNothing() {
        freePaths(at: date(2026, 10, 20)).recordLessonStarted(in: "aztec-mictlan")
        freePaths(at: date(2026, 11, 5)).recordLessonStarted(in: "aztec-mictlan")

        XCTAssertTrue(claims.keys.isEmpty)
        XCTAssertFalse(freePaths(at: date(2026, 11, 5)).isOpen("aztec-mictlan"))
    }

    func testStartingAnotherPathDuringTheEventClaimsNothing() {
        freePaths(at: date(2026, 10, 30)).recordLessonStarted(in: "norse")

        XCTAssertTrue(claims.keys.isEmpty)
    }

    func testClaimKeyIsScopedToTheEventYear() {
        XCTAssertEqual(PathGiftEvent.diaDeLosMuertos2026.claimKey, "aotd.pathGift.aztec-mictlan.2026")
    }
}
