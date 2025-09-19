import XCTest
import GRDB
@testable import aotd

final class AchievementTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    var testUser: User!
    
    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try User.createTable(db)
            try UserAchievement.createTable(db)
        }
        
        
        testUser = User(name: "Test User", email: "test@example.com")
        try dbQueue.write { db in
            try testUser.insert(db)
        }
    }
    
    override func tearDownWithError() throws {
        dbQueue = nil
    }
    
    func testUserAchievementCreation() throws {
        let achievement = UserAchievement(userId: "user123", achievementId: "first_step")
        
        XCTAssertFalse(achievement.id.isEmpty)
        XCTAssertEqual(achievement.userId, "user123")
        XCTAssertEqual(achievement.achievementId, "first_step")
        XCTAssertEqual(achievement.progress, 0.0)
        XCTAssertFalse(achievement.isCompleted)
        XCTAssertNotNil(achievement.unlockedAt)
    }
    
    func testUserAchievementPersistence() throws {
        var achievement = UserAchievement(userId: testUser.id, achievementId: "first_step", progress: 0.5)
        
        try dbQueue.write { db in
            try achievement.insert(db)
        }
        
        let retrievedAchievement = try dbQueue.read { db in
            try UserAchievement.fetchOne(db, key: achievement.id)
        }
        
        XCTAssertNotNil(retrievedAchievement)
        XCTAssertEqual(retrievedAchievement?.userId, testUser.id)
        XCTAssertEqual(retrievedAchievement?.achievementId, "first_step")
        XCTAssertEqual(retrievedAchievement?.progress, 0.5)
    }
    
    func testUpdateProgress() throws {
        var achievement = UserAchievement(userId: "user123", achievementId: "first_step")
        
        achievement.updateProgress(0.5)
        XCTAssertEqual(achievement.progress, 0.5)
        XCTAssertFalse(achievement.isCompleted)
        
        achievement.updateProgress(1.0)
        XCTAssertEqual(achievement.progress, 1.0)
        XCTAssertTrue(achievement.isCompleted)
        
        achievement.updateProgress(1.5)
        XCTAssertEqual(achievement.progress, 1.0)
        XCTAssertTrue(achievement.isCompleted)
        
        achievement.updateProgress(-0.5)
        XCTAssertEqual(achievement.progress, 0.0)
        XCTAssertFalse(achievement.isCompleted)
    }
    
    func testAchievementCriteriaDecoding() throws {
        let jsonString = """
        {
            "id": "first_step",
            "name": "First Step",
            "description": "Complete your first lesson.",
            "icon": "footsteps",
            "criteria": {
                "type": "completeLesson",
                "value": 1
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let achievement = try JSONDecoder().decode(Achievement.self, from: data)
        
        XCTAssertEqual(achievement.id, "first_step")
        XCTAssertEqual(achievement.name, "First Step")
        XCTAssertEqual(achievement.criteria.type, .completeLesson)
        
        if case .int(let value) = achievement.criteria.value {
            XCTAssertEqual(value, 1)
        } else {
            XCTFail("Expected int value")
        }
    }
    
    func testAchievementCriteriaStringValue() throws {
        let jsonString = """
        {
            "id": "scholar_of_sheol",
            "name": "Scholar of Sheol",
            "description": "Complete the Judaism path.",
            "icon": "book",
            "criteria": {
                "type": "completePath",
                "value": "judaism"
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let achievement = try JSONDecoder().decode(Achievement.self, from: data)
        
        XCTAssertEqual(achievement.criteria.type, .completePath)
        
        if case .string(let value) = achievement.criteria.value {
            XCTAssertEqual(value, "judaism")
        } else {
            XCTFail("Expected string value")
        }
    }
    
    func testAchievementCriteriaBoolValue() throws {
        let jsonString = """
        {
            "id": "afterlife_master",
            "name": "Afterlife Master",
            "description": "Complete all belief system paths.",
            "icon": "crown",
            "criteria": {
                "type": "completeAllPaths",
                "value": true
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let achievement = try JSONDecoder().decode(Achievement.self, from: data)
        
        XCTAssertEqual(achievement.criteria.type, .completeAllPaths)
        
        if case .bool(let value) = achievement.criteria.value {
            XCTAssertTrue(value)
        } else {
            XCTFail("Expected bool value")
        }
    }
    
    func testUniqueUserAchievementConstraint() throws {
        var achievement1 = UserAchievement(userId: testUser.id, achievementId: "first_step")
        var achievement2 = UserAchievement(userId: testUser.id, achievementId: "first_step")
        
        try dbQueue.write { db in
            try achievement1.insert(db)
        }
        
        XCTAssertThrowsError(try dbQueue.write { db in
            try achievement2.insert(db)
        })
    }
    
    func testAchievementCompletion() throws {
        var achievement = UserAchievement(userId: testUser.id, achievementId: "first_step", progress: 1.0)
        
        XCTAssertTrue(achievement.isCompleted)
        
        try dbQueue.write { db in
            try achievement.insert(db)
        }
        
        let retrievedAchievement = try dbQueue.read { db in
            try UserAchievement.fetchOne(db, key: achievement.id)
        }
        
        XCTAssertNotNil(retrievedAchievement)
        XCTAssertTrue(retrievedAchievement?.isCompleted ?? false)
    }
}