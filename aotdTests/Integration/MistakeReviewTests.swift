import XCTest
@testable import aotd

final class MistakeReviewTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var user: User!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory database
        databaseManager = DatabaseManager(inMemory: true)
        
        // Create test user
        user = try! databaseManager.createUser(name: "Test User", email: "test@example.com")
    }
    
    override func tearDown() {
        databaseManager = nil
        user = nil
        super.tearDown()
    }
    
    func testSaveMistake() throws {
        // Given
        let beliefSystemId = "judaism"
        let questionId = "q1"
        let incorrectAnswer = "Wrong"
        let correctAnswer = "Right"
        
        // When
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: incorrectAnswer,
            correctAnswer: correctAnswer
        )
        
        // Then
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(mistakes.count, 1)
        XCTAssertEqual(mistakes[0].questionId, questionId)
        XCTAssertEqual(mistakes[0].incorrectAnswer, incorrectAnswer)
        XCTAssertEqual(mistakes[0].correctAnswer, correctAnswer)
        XCTAssertFalse(mistakes[0].mastered)
    }
    
    func testMistakeCountDecreasesWhenMastered() throws {
        // Given
        let beliefSystemId = "judaism"
        let questionId = "q1"
        
        // Save a mistake
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: "Wrong",
            correctAnswer: "Right"
        )
        
        // Verify initial count
        var count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 1)
        
        // When - Get the mistake and mark it as reviewed correctly 5 times
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        let mistake = mistakes[0]
        
        // Review correctly 5 times to master it
        for _ in 0..<5 {
            try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: true)
        }
        
        // Then - Count should be 0 because mistake is mastered
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 0)
    }
    
    func testMistakeReviewResetsOnIncorrect() throws {
        // Given
        let beliefSystemId = "judaism"
        let questionId = "q1"
        
        // Save a mistake and review it correctly 3 times
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: "Wrong",
            correctAnswer: "Right"
        )
        
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        let mistake = mistakes[0]
        
        // Review correctly 3 times
        for _ in 0..<3 {
            try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: true)
        }
        
        // When - Review incorrectly
        try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: false)
        
        // Then - Mistake should still appear in count (not mastered)
        let count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 1)
    }
    
    func testMistakeSession() throws {
        // Given
        let beliefSystemId = "judaism"
        
        // Save some mistakes
        for i in 1...3 {
            try databaseManager.saveMistake(
                userId: user.id,
                beliefSystemId: beliefSystemId,
                lessonId: nil,
                questionId: "q\(i)",
                incorrectAnswer: "Wrong\(i)",
                correctAnswer: "Right\(i)"
            )
        }
        
        // When - Start a session
        let session = try databaseManager.startMistakeSession(userId: user.id, beliefSystemId: beliefSystemId)
        
        // Then
        XCTAssertEqual(session.mistakeCount, 3)
        XCTAssertNil(session.completedAt)
        
        // When - Complete the session
        try databaseManager.completeMistakeSession(sessionId: session.id, correctCount: 2, xpEarned: 10)
        
        // Then - Session should be marked as completed
        // Note: We would need to add a method to fetch the session to verify this
    }
    
    func testMistakeDisappearsFromCountAfterCorrectReview() throws {
        // Given
        let beliefSystemId = "judaism"
        let questionId = "q1"
        
        // Save a mistake
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: "Wrong",
            correctAnswer: "Right"
        )
        
        // Verify initial count
        var count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 1)
        
        // When - Review the mistake correctly
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        let mistake = mistakes[0]
        try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: true)
        
        // Then - Count should be 0 because mistake is scheduled for future review
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 0)
    }
}