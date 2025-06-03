import XCTest
@testable import aotd

final class MultipleChoiceViewModelTests: XCTestCase {
    
    private var sut: MultipleChoiceViewModel!
    private var question: Question!
    private var beliefSystem: BeliefSystem!
    
    override func setUp() {
        super.setUp()
        
        question = Question(
            id: "q1",
            type: .multipleChoice,
            question: "What is 2 + 2?",
            options: ["3", "4", "5", "6"],
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .string("4")),
            explanation: "2 + 2 equals 4"
        )
        
        let masteryTest = MasteryTest(
            id: "test1",
            title: "Test",
            requiredScore: 80,
            xpReward: 100,
            questions: []
        )
        
        beliefSystem = BeliefSystem(
            id: "math",
            name: "Mathematics",
            description: "Test description",
            icon: "function",
            color: "#FF0000",
            totalXP: 100,
            lessons: [],
            masteryTest: masteryTest
        )
        
        sut = MultipleChoiceViewModel(
            question: question,
            beliefSystem: beliefSystem,
            currentQuestionIndex: 0,
            totalQuestions: 5
        )
    }
    
    override func tearDown() {
        sut = nil
        question = nil
        beliefSystem = nil
        super.tearDown()
    }
    
    func testOptions() {
        XCTAssertEqual(sut.options, ["3", "4", "5", "6"])
    }
    
    func testOptionsWhenNil() {
        let questionWithoutOptions = Question(
            id: "q2",
            type: .trueFalse,
            question: "True or false?",
            options: nil,
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .string("true")),
            explanation: "It's true"
        )
        
        let viewModel = MultipleChoiceViewModel(
            question: questionWithoutOptions,
            beliefSystem: beliefSystem,
            currentQuestionIndex: 0,
            totalQuestions: 1
        )
        
        XCTAssertEqual(viewModel.options, [])
    }
    
    func testInheritsFromBaseViewModel() {
        XCTAssertEqual(sut.questionText, "What is 2 + 2?")
        XCTAssertEqual(sut.progress, 0.2) // 1/5
        XCTAssertNotNil(sut.beliefSystemColor)
    }
}