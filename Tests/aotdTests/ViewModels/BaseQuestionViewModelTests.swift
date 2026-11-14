import XCTest
@testable import aotd
import AppOfTheDeadCore

@MainActor final class BaseQuestionViewModelTests: XCTestCase {
    
    private var sut: BaseQuestionViewModel!
    private var mockDelegate: MockQuestionViewModelDelegate!
    private var question: Question!
    private var beliefSystem: BeliefSystem!
    
    override func setUp() async throws {
        try await super.setUp()
        
        question = Question(
            id: "q1",
            type: .multipleChoice,
            question: "What is the capital of France?",
            options: ["London", "Paris", "Berlin", "Madrid"],
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .string("Paris")),
            explanation: "Paris is the capital of France"
        )
        
        let masteryTest = MasteryTest(
            id: "test1",
            title: "Test",
            requiredScore: 80,
            xpReward: 100,
            questions: []
        )
        
        beliefSystem = BeliefSystem(
            id: "judaism",
            name: "Judaism",
            description: "Test description",
            icon: "star",
            color: "#003F7F",
            totalXP: 100,
            lessons: [],
            masteryTest: masteryTest
        )
        
        sut = BaseQuestionViewModel(
            question: question,
            beliefSystem: beliefSystem,
            currentQuestionIndex: 2,
            totalQuestions: 10
        )
        
        mockDelegate = MockQuestionViewModelDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() async throws {
        sut = nil
        mockDelegate = nil
        question = nil
        beliefSystem = nil
        try await super.tearDown()
    }
    
    func testQuestionText() {
        XCTAssertEqual(sut.questionText, "What is the capital of France?")
    }
    
    func testProgress() {
        XCTAssertEqual(sut.progress, 0.3) 
    }
    
    func testBeliefSystemColor() {
        XCTAssertNotNil(sut.beliefSystemColor)
    }
    
    func testXPReward() {
        XCTAssertEqual(sut.xpReward, 10)
    }
    
    func testCheckAnswerCorrect() {
        let (isCorrect, explanation) = sut.checkAnswer("Paris")
        XCTAssertTrue(isCorrect)
        XCTAssertEqual(explanation, "Paris is the capital of France")
    }
    
    func testCheckAnswerIncorrect() {
        let (isCorrect, explanation) = sut.checkAnswer("London")
        XCTAssertFalse(isCorrect)
        XCTAssertEqual(explanation, "Paris is the capital of France")
    }
    
    func testCheckAnswerWithArrayCorrectAnswer() {
        let multiAnswerQuestion = Question(
            id: "q2",
            type: .multipleChoice,
            question: "Which are primary colors?",
            options: ["Red", "Green", "Blue", "Yellow"],
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .array(["Red", "Blue", "Yellow"])),
            explanation: "Primary colors are red, blue, and yellow"
        )
        
        let viewModel = BaseQuestionViewModel(
            question: multiAnswerQuestion,
            beliefSystem: beliefSystem,
            currentQuestionIndex: 0,
            totalQuestions: 1
        )
        
        let (isCorrect1, _) = viewModel.checkAnswer("Red")
        XCTAssertTrue(isCorrect1)
        
        let (isCorrect2, _) = viewModel.checkAnswer("Green")
        XCTAssertFalse(isCorrect2)
    }

    func testOutcomeRecordsTheGivenAndTheRightAnswer() {
        let outcome = sut.outcome(for: "London")
        XCTAssertFalse(outcome.isCorrect)
        XCTAssertEqual(outcome.givenAnswer, "London")
        XCTAssertEqual(outcome.correctAnswer, "Paris")
        XCTAssertEqual(outcome.explanation, "Paris is the capital of France")
        XCTAssertEqual(sut.submittedAnswer, "London")
    }

    func testSubmittedAnswerTextIsEmptyBeforeACheck() {
        XCTAssertNil(sut.submittedAnswer)
        XCTAssertEqual(sut.submittedAnswerText, "")
    }

    func testTrueFalseAnswersReadAsWords() {
        let statement = Question(
            id: "q3",
            type: .trueFalse,
            question: "Paris is in France.",
            options: nil,
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .string("true")),
            explanation: "It is."
        )
        let viewModel = BaseQuestionViewModel(question: statement, beliefSystem: beliefSystem, currentQuestionIndex: 0, totalQuestions: 1)
        let outcome = viewModel.outcome(for: "false")
        XCTAssertFalse(outcome.isCorrect)
        XCTAssertEqual(outcome.givenAnswer, String(localized: "False"))
        XCTAssertEqual(outcome.correctAnswer, String(localized: "True"))
    }

    func testPositionTextCountsFromOne() {
        XCTAssertEqual(sut.positionText, String(localized: "Question \(3) of \(10)"))
    }
}

private class MockQuestionViewModelDelegate: QuestionViewModelDelegate {
    var didAnswerCorrectlyCalled = false
    var wasCorrect: Bool?
    var didRequestExitCalled = false
    
    func questionViewModel(_ viewModel: BaseQuestionViewModel, didAnswerCorrectly: Bool) {
        didAnswerCorrectlyCalled = true
        wasCorrect = didAnswerCorrectly
    }
    
    func questionViewModelDidRequestExit(_ viewModel: BaseQuestionViewModel) {
        didRequestExitCalled = true
    }
}