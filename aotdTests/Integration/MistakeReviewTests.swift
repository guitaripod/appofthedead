import XCTest
@testable import aotd

final class MistakeReviewTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var user: User!
    
    override func setUp() {
        super.setUp()
        
        
        databaseManager = DatabaseManager(inMemory: true)
        
        
        user = try! databaseManager.createAnonymousUser()
    }
    
    override func tearDown() {
        databaseManager = nil
        user = nil
        super.tearDown()
    }
    
    func testSaveMistake() throws {
        
        let beliefSystemId = "judaism"
        let questionId = "q1"
        let incorrectAnswer = "Wrong"
        let correctAnswer = "Right"
        
        
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: incorrectAnswer,
            correctAnswer: correctAnswer
        )
        
        
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(mistakes.count, 1)
        XCTAssertEqual(mistakes[0].questionId, questionId)
        XCTAssertEqual(mistakes[0].incorrectAnswer, incorrectAnswer)
        XCTAssertEqual(mistakes[0].correctAnswer, correctAnswer)
        XCTAssertFalse(mistakes[0].mastered)
    }
    
    func testMistakeCountDecreasesWhenMastered() throws {
        
        let beliefSystemId = "judaism"
        let questionId = "q1"
        
        
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: "Wrong",
            correctAnswer: "Right"
        )
        
        
        var count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 1)
        
        
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        let mistake = mistakes[0]
        
        
        for _ in 0..<5 {
            try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: true)
        }
        
        
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 0)
    }
    
    func testMistakeReviewResetsOnIncorrect() throws {
        
        let beliefSystemId = "judaism"
        let questionId = "q1"
        
        
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
        
        
        for _ in 0..<3 {
            try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: true)
        }
        
        
        try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: false)
        
        
        let count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 1)
    }
    
    func testMistakeSession() throws {
        
        let beliefSystemId = "judaism"
        
        
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
        
        
        let session = try databaseManager.startMistakeSession(userId: user.id, beliefSystemId: beliefSystemId)
        
        
        XCTAssertEqual(session.mistakeCount, 3)
        XCTAssertNil(session.completedAt)
        
        
        try databaseManager.completeMistakeSession(sessionId: session.id, correctCount: 2, xpEarned: 10)
        
        
        
    }
    
    func testMistakeDisappearsFromCountAfterCorrectReview() throws {
        
        let beliefSystemId = "judaism"
        let questionId = "q1"
        
        
        try databaseManager.saveMistake(
            userId: user.id,
            beliefSystemId: beliefSystemId,
            lessonId: nil,
            questionId: questionId,
            incorrectAnswer: "Wrong",
            correctAnswer: "Right"
        )
        
        
        var count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 1)
        
        
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystemId)
        let mistake = mistakes[0]
        try databaseManager.updateMistakeReview(mistakeId: mistake.id, wasCorrect: true)
        
        
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystemId)
        XCTAssertEqual(count, 0)
    }
}