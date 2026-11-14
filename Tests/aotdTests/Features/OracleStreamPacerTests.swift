import XCTest
@testable import aotd

@MainActor final class OracleStreamPacerTests: XCTestCase {
    private let frame: TimeInterval = 1.0 / 60

    private func run(_ pacer: inout OracleStreamPacer, seconds: TimeInterval) {
        for _ in 0..<Int((seconds / frame).rounded()) {
            pacer.advance(by: frame)
        }
    }

    func testABurstIsMostlyOnScreenWithinASecond() {
        var pacer = OracleStreamPacer()
        pacer.setTarget(length: 1000, isComplete: false)
        run(&pacer, seconds: 1)
        XCTAssertGreaterThan(pacer.visibleLength, 930)
        XCTAssertLessThanOrEqual(pacer.visibleLength, 1000)
    }

    func testRevealIsGradualNotAJump() {
        var pacer = OracleStreamPacer()
        pacer.setTarget(length: 400, isComplete: false)
        pacer.advance(by: frame)
        XCTAssertGreaterThan(pacer.visibleLength, 0)
        XCTAssertLessThan(pacer.visibleLength, 40)
    }

    func testASteadyStreamIsFollowedClosely() {
        var pacer = OracleStreamPacer()
        var received = 0
        for _ in 0..<180 {
            received += 2
            pacer.setTarget(length: received, isComplete: false)
            pacer.advance(by: frame)
        }
        XCTAssertLessThan(received - pacer.visibleLength, 60)
        XCTAssertGreaterThan(pacer.visibleLength, 0)
    }

    func testASlowTrickleStillFlowsAtTheMinimumRate() {
        var pacer = OracleStreamPacer()
        pacer.setTarget(length: 3, isComplete: false)
        run(&pacer, seconds: 0.1)
        XCTAssertEqual(pacer.visibleLength, 3)
        XCTAssertTrue(pacer.isCaughtUp)
        XCTAssertFalse(pacer.isFinished)
    }

    func testACompleteReplyFinishesQuickly() {
        var pacer = OracleStreamPacer()
        pacer.setTarget(length: 300, isComplete: true)
        run(&pacer, seconds: 1.2)
        XCTAssertTrue(pacer.isFinished)
    }

    func testALongPauseCountsAsOneShortStep() {
        var pacer = OracleStreamPacer()
        pacer.setTarget(length: 10_000, isComplete: false)
        pacer.advance(by: 5)
        let stepped = OracleStreamPacer.longestStep * (10_000 / OracleStreamPacer.catchUpWindow)
        XCTAssertLessThanOrEqual(Double(pacer.visibleLength), stepped + 1)
    }

    func testShrinkingTextNeverShowsMoreThanThereIs() {
        var pacer = OracleStreamPacer()
        pacer.setTarget(length: 50, isComplete: false)
        run(&pacer, seconds: 1)
        pacer.setTarget(length: 46, isComplete: false)
        XCTAssertEqual(pacer.visibleLength, 46)
    }

    func testCharacterBoundariesCountGraphemesNotCodeUnits() {
        let boundaries = OracleStreamReveal.characterBoundaries(of: "a☥𓂀é")
        XCTAssertEqual(boundaries.count, 4)
        XCTAssertEqual(boundaries.last, ("a☥𓂀é" as NSString).length)
    }
}
