import XCTest
import GRDB
@testable import aotd

final class UserAnswerTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    var testUser: User!
    
    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try User.createTable(db)
            try UserAnswer.createTable(db)
        }
        
        // Create a test user
        testUser = User(name: "Test User", email: "test@example.com")
        try dbQueue.write { db in
            try testUser.insert(db)
        }
    }
    
    override func tearDownWithError() throws {
        dbQueue = nil
    }
    
    func testUserAnswerCreation() throws {
        let userAnswer = UserAnswer(
            userId: "user123",
            questionId: "q1",
            userAnswer: "A",
            isCorrect: true,
            beliefSystemId: "judaism",
            lessonId: "lesson1",
            timeSpent: 10.5
        )
        
        XCTAssertFalse(userAnswer.id.isEmpty)
        XCTAssertEqual(userAnswer.userId, "user123")
        XCTAssertEqual(userAnswer.questionId, "q1")
        XCTAssertEqual(userAnswer.userAnswer, "A")
        XCTAssertTrue(userAnswer.isCorrect)
        XCTAssertEqual(userAnswer.beliefSystemId, "judaism")
        XCTAssertEqual(userAnswer.lessonId, "lesson1")
        XCTAssertFalse(userAnswer.isMasteryTest)
        XCTAssertEqual(userAnswer.timeSpent, 10.5)
        XCTAssertNotNil(userAnswer.attemptedAt)
    }
    
    func testUserAnswerPersistence() throws {
        var userAnswer = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "B",
            isCorrect: false,
            beliefSystemId: "judaism",
            lessonId: "lesson1"
        )
        
        try dbQueue.write { db in
            try userAnswer.insert(db)
        }
        
        let retrievedAnswer = try dbQueue.read { db in
            try UserAnswer.fetchOne(db, key: userAnswer.id)
        }
        
        XCTAssertNotNil(retrievedAnswer)
        XCTAssertEqual(retrievedAnswer?.userId, testUser.id)
        XCTAssertEqual(retrievedAnswer?.questionId, "q1")
        XCTAssertEqual(retrievedAnswer?.userAnswer, "B")
        XCTAssertFalse(retrievedAnswer?.isCorrect ?? true)
        XCTAssertEqual(retrievedAnswer?.beliefSystemId, "judaism")
        XCTAssertEqual(retrievedAnswer?.lessonId, "lesson1")
    }
    
    func testMasteryTestAnswer() throws {
        var userAnswer = UserAnswer(
            userId: testUser.id,
            questionId: "mt-q1",
            userAnswer: "C",
            isCorrect: true,
            beliefSystemId: "judaism",
            isMasteryTest: true
        )
        
        XCTAssertTrue(userAnswer.isMasteryTest)
        XCTAssertNil(userAnswer.lessonId)
        
        try dbQueue.write { db in
            try userAnswer.insert(db)
        }
        
        let retrievedAnswer = try dbQueue.read { db in
            try UserAnswer.fetchOne(db, key: userAnswer.id)
        }
        
        XCTAssertNotNil(retrievedAnswer)
        XCTAssertTrue(retrievedAnswer?.isMasteryTest ?? false)
        XCTAssertNil(retrievedAnswer?.lessonId)
    }
    
    func testDefaultValues() throws {
        let userAnswer = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "A",
            isCorrect: true,
            beliefSystemId: "judaism"
        )
        
        XCTAssertNil(userAnswer.lessonId)
        XCTAssertFalse(userAnswer.isMasteryTest)
        XCTAssertEqual(userAnswer.timeSpent, 0.0)
    }
    
    func testMultipleAnswersForSameQuestion() throws {
        var answer1 = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "A",
            isCorrect: false,
            beliefSystemId: "judaism",
            lessonId: "lesson1"
        )
        
        var answer2 = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "B",
            isCorrect: true,
            beliefSystemId: "judaism",
            lessonId: "lesson1"
        )
        
        try dbQueue.write { db in
            try answer1.insert(db)
            try answer2.insert(db)
        }
        
        let allAnswers = try dbQueue.read { db in
            try UserAnswer.filter(Column("userId") == testUser.id && Column("questionId") == "q1").fetchAll(db)
        }
        
        XCTAssertEqual(allAnswers.count, 2)
    }
    
    func testTimeTracking() throws {
        var userAnswer = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "A",
            isCorrect: true,
            beliefSystemId: "judaism",
            timeSpent: 25.75
        )
        
        try dbQueue.write { db in
            try userAnswer.insert(db)
        }
        
        let retrievedAnswer = try dbQueue.read { db in
            try UserAnswer.fetchOne(db, key: userAnswer.id)
        }
        
        XCTAssertEqual(retrievedAnswer?.timeSpent, 25.75)
    }
    
    func testAnswerFiltering() throws {
        var answer1 = UserAnswer(userId: testUser.id, questionId: "q1", userAnswer: "A", isCorrect: true, beliefSystemId: "judaism")
        var answer2 = UserAnswer(userId: testUser.id, questionId: "q2", userAnswer: "B", isCorrect: false, beliefSystemId: "judaism")
        
        // Create another user for filtering test
        var otherUser = User(name: "Other User", email: "other@example.com")
        try dbQueue.write { db in
            try otherUser.insert(db)
        }
        var answer3 = UserAnswer(userId: otherUser.id, questionId: "q1", userAnswer: "C", isCorrect: true, beliefSystemId: "judaism")
        
        try dbQueue.write { db in
            try answer1.insert(db)
            try answer2.insert(db)
            try answer3.insert(db)
        }
        
        let testUserAnswers = try dbQueue.read { db in
            try UserAnswer.filter(Column("userId") == testUser.id).fetchAll(db)
        }
        
        let correctAnswers = try dbQueue.read { db in
            try UserAnswer.filter(Column("isCorrect") == true).fetchAll(db)
        }
        
        XCTAssertEqual(testUserAnswers.count, 2)
        XCTAssertEqual(correctAnswers.count, 2)
    }
}