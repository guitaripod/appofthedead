import XCTest
@testable import aotd

final class DailyReminderTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "DailyReminderTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToNineInTheMorningAndDisabled() {
        let reminder = DailyReminder(defaults: defaults)

        XCTAssertFalse(reminder.isEnabled)
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        XCTAssertEqual(components.hour, DailyReminder.defaultHour)
        XCTAssertEqual(components.minute, 0)
    }

    func testStateSharedThroughTheSameDefaultsKeysSettingsUses() {
        let reminder = DailyReminder(defaults: defaults)
        let evening = Calendar.current.date(from: DateComponents(hour: 20, minute: 30))!

        reminder.isEnabled = true
        reminder.time = evening

        XCTAssertTrue(defaults.bool(forKey: "DailyReminderEnabled"))
        XCTAssertEqual(defaults.object(forKey: "DailyReminderTime") as? Date, evening)
        XCTAssertEqual(DailyReminder(defaults: defaults).time, evening)
    }
}
