import XCTest
@testable import aotd

@MainActor final class FirstRunWelcomeTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "FirstRunWelcomeTests"

    override func setUp() async throws {
        try await super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    func testBrandNewInstallPresentsWelcome() {
        XCTAssertTrue(FirstRunWelcome(defaults: defaults).shouldPresent(hasExistingProgress: false))
    }

    func testExistingProgressSkipsWelcomeAndRemembersIt() {
        let welcome = FirstRunWelcome(defaults: defaults)

        XCTAssertFalse(welcome.shouldPresent(hasExistingProgress: true))
        XCTAssertTrue(welcome.isCompleted)
        XCTAssertFalse(welcome.shouldPresent(hasExistingProgress: false))
    }

    func testCompletedFlagSkipsWelcomeEvenWithoutProgress() {
        let welcome = FirstRunWelcome(defaults: defaults)
        welcome.markCompleted()

        XCTAssertFalse(welcome.shouldPresent(hasExistingProgress: false))
    }

    func testWelcomeKeepsPresentingUntilCompleted() {
        let welcome = FirstRunWelcome(defaults: defaults)

        XCTAssertTrue(welcome.shouldPresent(hasExistingProgress: false))
        XCTAssertTrue(welcome.shouldPresent(hasExistingProgress: false))
    }
}
