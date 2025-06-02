import XCTest
import GRDB
@testable import aotd

final class ProgressTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    var testUser: User!
    
    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try User.createTable(db)
            try Progress.createTable(db)
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
    
    func testProgressCreation() throws {
        let progress = Progress(userId: "user123", beliefSystemId: "judaism", lessonId: "lesson1")
        
        XCTAssertFalse(progress.id.isEmpty)
        XCTAssertEqual(progress.userId, "user123")
        XCTAssertEqual(progress.beliefSystemId, "judaism")
        XCTAssertEqual(progress.lessonId, "lesson1")
        XCTAssertEqual(progress.status, .notStarted)
        XCTAssertNil(progress.score)
        XCTAssertEqual(progress.totalAttempts, 0)
        XCTAssertNil(progress.completedAt)
    }
    
    func testProgressPersistence() throws {
        var progress = Progress(userId: testUser.id, beliefSystemId: "judaism", lessonId: "lesson1")
        
        try dbQueue.write { db in
            try progress.insert(db)
        }
        
        let retrievedProgress = try dbQueue.read { db in
            try Progress.fetchOne(db, key: progress.id)
        }
        
        XCTAssertNotNil(retrievedProgress)
        XCTAssertEqual(retrievedProgress?.userId, testUser.id)
        XCTAssertEqual(retrievedProgress?.beliefSystemId, "judaism")
        XCTAssertEqual(retrievedProgress?.lessonId, "lesson1")
    }
    
    func testMarkCompleted() throws {
        var progress = Progress(userId: "user123", beliefSystemId: "judaism", lessonId: "lesson1")
        
        progress.markCompleted(score: 85)
        
        XCTAssertEqual(progress.status, .completed)
        XCTAssertEqual(progress.score, 85)
        XCTAssertNotNil(progress.completedAt)
        XCTAssertNotNil(progress.updatedAt)
    }
    
    func testIncrementAttempts() throws {
        var progress = Progress(userId: "user123", beliefSystemId: "judaism", lessonId: "lesson1")
        
        XCTAssertEqual(progress.totalAttempts, 0)
        
        progress.incrementAttempts()
        XCTAssertEqual(progress.totalAttempts, 1)
        
        progress.incrementAttempts()
        XCTAssertEqual(progress.totalAttempts, 2)
    }
    
    func testProgressStatusEnum() throws {
        XCTAssertEqual(Progress.ProgressStatus.notStarted.rawValue, "not_started")
        XCTAssertEqual(Progress.ProgressStatus.inProgress.rawValue, "in_progress")
        XCTAssertEqual(Progress.ProgressStatus.completed.rawValue, "completed")
        XCTAssertEqual(Progress.ProgressStatus.mastered.rawValue, "mastered")
    }
    
    func testUniqueConstraint() throws {
        // Test with both lessonId and questionId to match the unique constraint
        var progress1 = Progress(userId: testUser.id, beliefSystemId: "judaism", lessonId: "lesson1", questionId: "q1")
        var progress2 = Progress(userId: testUser.id, beliefSystemId: "judaism", lessonId: "lesson1", questionId: "q1")
        
        try dbQueue.write { db in
            try progress1.insert(db)
        }
        
        XCTAssertThrowsError(try dbQueue.write { db in
            try progress2.insert(db)
        }) { error in
            // Verify it's a database error (unique constraint violation)
            XCTAssertTrue(error is DatabaseError)
        }
    }
    
    func testProgressUpdate() throws {
        var progress = Progress(userId: testUser.id, beliefSystemId: "judaism", lessonId: "lesson1")
        
        try dbQueue.write { db in
            try progress.insert(db)
        }
        
        progress.status = .inProgress
        progress.incrementAttempts()
        
        try dbQueue.write { db in
            try progress.update(db)
        }
        
        let retrievedProgress = try dbQueue.read { db in
            try Progress.fetchOne(db, key: progress.id)
        }
        
        XCTAssertEqual(retrievedProgress?.status, .inProgress)
        XCTAssertEqual(retrievedProgress?.totalAttempts, 1)
    }
    
    func testProgressWithoutLesson() throws {
        var progress = Progress(userId: testUser.id, beliefSystemId: "judaism")
        
        XCTAssertNil(progress.lessonId)
        XCTAssertNil(progress.questionId)
        
        try dbQueue.write { db in
            try progress.insert(db)
        }
        
        let retrievedProgress = try dbQueue.read { db in
            try Progress.fetchOne(db, key: progress.id)
        }
        
        XCTAssertNotNil(retrievedProgress)
        XCTAssertNil(retrievedProgress?.lessonId)
    }
}