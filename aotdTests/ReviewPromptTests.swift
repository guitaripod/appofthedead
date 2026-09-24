import XCTest
@testable import aotd

final class ReviewPromptTests: XCTestCase {

    func testFirstStrongLessonAsks() {
        XCTAssertTrue(ReviewPrompt.shouldAsk(score: 80, promptedVersion: nil, currentVersion: "1.4.7"))
        XCTAssertTrue(ReviewPrompt.shouldAsk(score: 100, promptedVersion: nil, currentVersion: "1.4.7"))
    }

    func testWeakLessonDoesNotAsk() {
        XCTAssertFalse(ReviewPrompt.shouldAsk(score: 79, promptedVersion: nil, currentVersion: "1.4.7"))
        XCTAssertFalse(ReviewPrompt.shouldAsk(score: 0, promptedVersion: nil, currentVersion: "1.4.7"))
    }

    func testAsksAtMostOncePerVersion() {
        XCTAssertFalse(ReviewPrompt.shouldAsk(score: 100, promptedVersion: "1.4.7", currentVersion: "1.4.7"))
    }

    func testNewVersionMayAskAgain() {
        XCTAssertTrue(ReviewPrompt.shouldAsk(score: 90, promptedVersion: "1.4.6", currentVersion: "1.4.7"))
    }
}
