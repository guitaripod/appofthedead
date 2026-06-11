import XCTest
@testable import aotd

final class MatchingQuestionViewModelTests: XCTestCase {

    private var question: Question!
    private var beliefSystem: BeliefSystem!

    override func setUp() {
        super.setUp()

        question = Question(
            id: "q-match",
            type: .matching,
            question: "Match the ceremonial practice with its purpose:",
            options: nil,
            pairs: [
                Question.MatchingPair(left: "Smoking ceremonies", right: "Guide spirits safely"),
                Question.MatchingPair(left: "Avoidance taboos", right: "Respect for the deceased"),
                Question.MatchingPair(left: "Resolution rituals", right: "Allow full integration")
            ],
            correctAnswer: CorrectAnswer(value: .array([
                "Smoking ceremonies", "Guide spirits safely",
                "Avoidance taboos", "Respect for the deceased",
                "Resolution rituals", "Allow full integration"
            ])),
            explanation: "These elements work together."
        )

        beliefSystem = BeliefSystem(
            id: "aboriginal-dreamtime",
            name: "Aboriginal Dreamtime",
            description: "Test description",
            icon: "boomerang",
            color: "#D2691E",
            totalXP: 700,
            lessons: [],
            masteryTest: MasteryTest(id: "test1", title: "Test", requiredScore: 80, xpReward: 100, questions: [])
        )
    }

    override func tearDown() {
        question = nil
        beliefSystem = nil
        super.tearDown()
    }

    private func makeViewModel(shuffler: @escaping ([String]) -> [String] = { $0.shuffled() }) -> MatchingQuestionViewModel {
        MatchingQuestionViewModel(
            question: question,
            beliefSystem: beliefSystem,
            currentQuestionIndex: 0,
            totalQuestions: 5,
            shuffler: shuffler
        )
    }

    func testLeftItemsPreservePairOrder() {
        let sut = makeViewModel()
        XCTAssertEqual(sut.leftItems, ["Smoking ceremonies", "Avoidance taboos", "Resolution rituals"])
    }

    func testRightItemsContainAllRightValues() {
        let sut = makeViewModel()
        XCTAssertEqual(
            Set(sut.rightItems),
            Set(["Guide spirits safely", "Respect for the deceased", "Allow full integration"])
        )
    }

    func testRightItemsNeverPresentedInSolvedOrder() {
        let sut = makeViewModel(shuffler: { $0 })
        XCTAssertNotEqual(sut.rightItems, ["Guide spirits safely", "Respect for the deceased", "Allow full integration"])
        XCTAssertEqual(
            Set(sut.rightItems),
            Set(["Guide spirits safely", "Respect for the deceased", "Allow full integration"])
        )
    }

    func testIsMatchCorrect() {
        let sut = makeViewModel()
        XCTAssertTrue(sut.isMatchCorrect(.init(left: "Smoking ceremonies", right: "Guide spirits safely")))
        XCTAssertFalse(sut.isMatchCorrect(.init(left: "Smoking ceremonies", right: "Respect for the deceased")))
        XCTAssertFalse(sut.isMatchCorrect(.init(left: "Unknown", right: "Guide spirits safely")))
    }

    func testCheckMatchesAllCorrect() {
        let sut = makeViewModel()
        let result = sut.checkMatches([
            .init(left: "Smoking ceremonies", right: "Guide spirits safely"),
            .init(left: "Avoidance taboos", right: "Respect for the deceased"),
            .init(left: "Resolution rituals", right: "Allow full integration")
        ])
        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.explanation, "These elements work together.")
    }

    func testCheckMatchesWithOneWrongPairFails() {
        let sut = makeViewModel()
        let result = sut.checkMatches([
            .init(left: "Smoking ceremonies", right: "Respect for the deceased"),
            .init(left: "Avoidance taboos", right: "Guide spirits safely"),
            .init(left: "Resolution rituals", right: "Allow full integration")
        ])
        XCTAssertFalse(result.isCorrect)
    }

    func testCheckMatchesIncompleteFails() {
        let sut = makeViewModel()
        let result = sut.checkMatches([
            .init(left: "Smoking ceremonies", right: "Guide spirits safely")
        ])
        XCTAssertFalse(result.isCorrect)
    }

    func testSinglePairQuestionKeepsOnlyOrdering() {
        question = Question(
            id: "q-single",
            type: .matching,
            question: "Match:",
            options: nil,
            pairs: [Question.MatchingPair(left: "A", right: "B")],
            correctAnswer: CorrectAnswer(value: .array(["A", "B"])),
            explanation: "Test"
        )
        let sut = makeViewModel(shuffler: { $0 })
        XCTAssertEqual(sut.rightItems, ["B"])
        XCTAssertTrue(sut.checkMatches([.init(left: "A", right: "B")]).isCorrect)
    }

    func testQuestionWithoutPairsProducesEmptyColumns() {
        question = Question(
            id: "q-empty",
            type: .matching,
            question: "Match:",
            options: nil,
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .array([])),
            explanation: "Test"
        )
        let sut = makeViewModel()
        XCTAssertTrue(sut.leftItems.isEmpty)
        XCTAssertTrue(sut.rightItems.isEmpty)
    }
}
