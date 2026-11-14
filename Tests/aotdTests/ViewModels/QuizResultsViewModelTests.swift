import XCTest
@testable import aotd
import AppOfTheDeadCore

@MainActor final class QuizResultsViewModelTests: XCTestCase {

    private let beliefSystem = BeliefSystem(
        id: "norse",
        name: "Norse",
        description: "Test description",
        icon: "flame",
        color: "#1E3A8A",
        totalXP: 700,
        lessons: [],
        masteryTest: MasteryTest(id: "norse-mt", title: "Mastery", requiredScore: 80, xpReward: 200, questions: [])
    )

    private func question(_ id: String) -> Question {
        Question(
            id: id,
            type: .multipleChoice,
            question: "Question \(id)?",
            options: ["Right", "Wrong"],
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .string("Right")),
            explanation: "Because \(id)."
        )
    }

    private func results(correct: Int, wrong: Int, xpEach: Int = 10) -> [QuestionResult] {
        let rights = (0..<correct).map { index in
            QuestionResult(
                question: question("r\(index)"),
                outcome: QuestionOutcome(isCorrect: true, explanation: "Because r\(index).", givenAnswer: "Right", correctAnswer: "Right"),
                xpEarned: xpEach
            )
        }
        let wrongs = (0..<wrong).map { index in
            QuestionResult(
                question: question("w\(index)"),
                outcome: QuestionOutcome(isCorrect: false, explanation: "Because w\(index).", givenAnswer: "Wrong", correctAnswer: "Right"),
                xpEarned: 0
            )
        }
        return rights + wrongs
    }

    func testScoreRoundsDownAndCountsAnswers() {
        let sut = QuizResultsViewModel(kind: .lesson(title: "Valhalla"), beliefSystem: beliefSystem, results: results(correct: 2, wrong: 1), bonusXP: 0)
        XCTAssertEqual(sut.correctCount, 2)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.mistakeCount, 1)
        XCTAssertEqual(sut.score, 67)
        XCTAssertEqual(sut.scoreText, "67%")
        XCTAssertEqual(sut.correctValue, "2/3")
        XCTAssertEqual(sut.fraction, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testXPAddsEveryAnswerAndTheBonus() {
        let sut = QuizResultsViewModel(kind: .lesson(title: "Valhalla"), beliefSystem: beliefSystem, results: results(correct: 3, wrong: 2, xpEach: 12), bonusXP: 75)
        XCTAssertEqual(sut.xpEarned, 111)
        XCTAssertEqual(sut.xpValue, "+111")
    }

    func testTiersFollowTheScore() {
        func tier(_ correct: Int, of total: Int) -> QuizResultsViewModel.Tier {
            QuizResultsViewModel(kind: .review, beliefSystem: beliefSystem, results: results(correct: correct, wrong: total - correct), bonusXP: 0).tier
        }
        XCTAssertEqual(tier(5, of: 5), .flawless)
        XCTAssertEqual(tier(4, of: 5), .strong)
        XCTAssertEqual(tier(9, of: 10), .strong)
        XCTAssertEqual(tier(3, of: 5), .steady)
        XCTAssertEqual(tier(1, of: 2), .steady)
        XCTAssertEqual(tier(2, of: 5), .struggling)
        XCTAssertEqual(tier(0, of: 4), .struggling)
    }

    func testReviewItemsKeepOrderAnswersAndExplanations() {
        let sut = QuizResultsViewModel(kind: .lesson(title: "Valhalla"), beliefSystem: beliefSystem, results: results(correct: 1, wrong: 1), bonusXP: 0)
        XCTAssertEqual(sut.items, [
            .init(question: "Question r0?", wasCorrect: true, givenAnswer: "Right", correctAnswer: "Right", explanation: "Because r0."),
            .init(question: "Question w0?", wasCorrect: false, givenAnswer: "Wrong", correctAnswer: "Right", explanation: "Because w0.")
        ])
    }

    func testMasteryPassesAtTheRequiredScore() {
        let passed = QuizResultsViewModel(kind: .mastery(requiredScore: 80), beliefSystem: beliefSystem, results: results(correct: 8, wrong: 2), bonusXP: 200)
        XCTAssertEqual(passed.passed, true)
        XCTAssertEqual(passed.title, String(localized: "Mastered"))
        XCTAssertEqual(passed.subtitle, String(localized: "You have mastered \(beliefSystem.name)."))

        let failed = QuizResultsViewModel(kind: .mastery(requiredScore: 80), beliefSystem: beliefSystem, results: results(correct: 7, wrong: 3), bonusXP: 0)
        XCTAssertEqual(failed.passed, false)
        XCTAssertEqual(failed.title, String(localized: "Not yet"))
        XCTAssertEqual(failed.subtitle, String(localized: "Passing takes \(80)%. Review what you missed and try again."))
    }

    func testOnlyAMasteryTestPassesOrFails() {
        XCTAssertNil(QuizResultsViewModel(kind: .lesson(title: "Valhalla"), beliefSystem: beliefSystem, results: results(correct: 1, wrong: 0), bonusXP: 0).passed)
        XCTAssertNil(QuizResultsViewModel(kind: .review, beliefSystem: beliefSystem, results: results(correct: 1, wrong: 0), bonusXP: 0).passed)
    }

    func testLessonResultsNameTheLessonAndTheTier() {
        let sut = QuizResultsViewModel(kind: .lesson(title: "Valhalla"), beliefSystem: beliefSystem, results: results(correct: 4, wrong: 0), bonusXP: 0)
        XCTAssertEqual(sut.eyebrow, String(localized: "Lesson complete"))
        XCTAssertEqual(sut.title, String(localized: "Flawless"))
        XCTAssertEqual(sut.subtitle, "Valhalla")
    }

    func testEmptyQuizCountsAsComplete() {
        let sut = QuizResultsViewModel(kind: .review, beliefSystem: beliefSystem, results: [], bonusXP: 0)
        XCTAssertEqual(sut.score, 100)
        XCTAssertEqual(sut.fraction, 1)
        XCTAssertEqual(sut.subtitle, "Norse")
    }

    func testQuestionResultCarriesTheOutcome() {
        let outcome = QuestionOutcome(isCorrect: false, explanation: "Why.", givenAnswer: "Wrong", correctAnswer: "Right")
        let result = QuestionResult(question: question("q"), outcome: outcome, xpEarned: 0)
        XCTAssertFalse(result.wasCorrect)
        XCTAssertEqual(result.givenAnswer, "Wrong")
        XCTAssertEqual(result.correctAnswer, "Right")
        XCTAssertEqual(result.xpEarned, 0)
    }

    func testStreakRaisesTheXPOfARightAnswer() {
        XCTAssertEqual(QuizXP.perCorrectAnswer(base: 10, streakDays: 0), 10)
        XCTAssertEqual(QuizXP.perCorrectAnswer(base: 10, streakDays: 2), 10)
        XCTAssertEqual(QuizXP.perCorrectAnswer(base: 10, streakDays: 3), 11)
        XCTAssertEqual(QuizXP.perCorrectAnswer(base: 10, streakDays: 7), 12)
        XCTAssertEqual(QuizXP.perCorrectAnswer(base: 10, streakDays: 14), 15)
        XCTAssertEqual(QuizXP.perCorrectAnswer(base: 10, streakDays: 30), 20)
    }
}
