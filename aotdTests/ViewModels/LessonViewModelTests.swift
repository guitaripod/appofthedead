import XCTest
@testable import aotd

final class LessonViewModelTests: XCTestCase {
    
    private var sut: LessonViewModel!
    private var mockDelegate: MockLessonViewModelDelegate!
    private var beliefSystem: BeliefSystem!
    private var lesson: Lesson!
    
    override func setUp() {
        super.setUp()
        
        let question = Question(
            id: "q1",
            type: .multipleChoice,
            question: "Test question?",
            options: ["A", "B", "C", "D"],
            pairs: nil,
            correctAnswer: CorrectAnswer(value: .string("A")),
            explanation: "A is correct"
        )
        
        lesson = Lesson(
            id: "lesson1",
            title: "Test Lesson",
            order: 1,
            content: "This is test content",
            keyTerms: ["Term1", "Term2", "Term3"],
            xpReward: 15,
            questions: [question]
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
            lessons: [lesson],
            masteryTest: masteryTest
        )
        
        sut = LessonViewModel(
            lesson: lesson,
            beliefSystem: beliefSystem,
            currentLessonIndex: 0,
            totalLessons: 5
        )
        
        mockDelegate = MockLessonViewModelDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        beliefSystem = nil
        lesson = nil
        super.tearDown()
    }
    
    func testLessonTitle() {
        XCTAssertEqual(sut.lessonTitle, "Test Lesson")
    }
    
    func testLessonContent() {
        XCTAssertEqual(sut.lessonContent, "This is test content")
    }
    
    func testKeyTerms() {
        XCTAssertEqual(sut.keyTerms, ["Term1", "Term2", "Term3"])
    }
    
    func testProgress() {
        XCTAssertEqual(sut.progress, 0.0)
        
        let sut2 = LessonViewModel(
            lesson: lesson,
            beliefSystem: beliefSystem,
            currentLessonIndex: 2,
            totalLessons: 5
        )
        XCTAssertEqual(sut2.progress, 0.4)
    }
    
    func testBeliefSystemColor() {
        XCTAssertNotNil(sut.beliefSystemColor)
    }
    
    func testContinueToQuiz() {
        sut.continueToQuiz()
        
        XCTAssertTrue(mockDelegate.didRequestQuizCalled)
        XCTAssertEqual(mockDelegate.passedQuestions?.count, 1)
        XCTAssertEqual(mockDelegate.passedQuestions?.first?.id, "q1")
    }
}

private class MockLessonViewModelDelegate: LessonViewModelDelegate {
    var didRequestQuizCalled = false
    var passedQuestions: [Question]?
    var didRequestExitCalled = false
    
    func lessonViewModelDidRequestQuiz(_ viewModel: LessonViewModel, questions: [Question]) {
        didRequestQuizCalled = true
        passedQuestions = questions
    }
    
    func lessonViewModelDidRequestExit(_ viewModel: LessonViewModel) {
        didRequestExitCalled = true
    }
}