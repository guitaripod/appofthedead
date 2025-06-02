import XCTest
import GRDB
@testable import aotd

final class UserTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    
    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try User.createTable(db)
        }
    }
    
    override func tearDownWithError() throws {
        dbQueue = nil
    }
    
    func testUserCreation() throws {
        let user = User(name: "Test User", email: "test@example.com")
        
        XCTAssertFalse(user.id.isEmpty)
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.totalXP, 0)
        XCTAssertEqual(user.currentLevel, 1)
        XCTAssertEqual(user.streakDays, 0)
        XCTAssertNil(user.lastActiveDate)
        XCTAssertNotNil(user.createdAt)
        XCTAssertNotNil(user.updatedAt)
    }
    
    func testUserPersistence() throws {
        var user = User(name: "Test User", email: "test@example.com")
        
        try dbQueue.write { db in
            try user.insert(db)
        }
        
        let retrievedUser = try dbQueue.read { db in
            try User.fetchOne(db, key: user.id)
        }
        
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.name, "Test User")
        XCTAssertEqual(retrievedUser?.email, "test@example.com")
    }
    
    func testAddXP() throws {
        var user = User(name: "Test User", email: "test@example.com")
        
        user.addXP(50)
        XCTAssertEqual(user.totalXP, 50)
        XCTAssertEqual(user.currentLevel, 1)
        
        user.addXP(100)
        XCTAssertEqual(user.totalXP, 150)
        XCTAssertEqual(user.currentLevel, 2)
        
        user.addXP(250)
        XCTAssertEqual(user.totalXP, 400)
        XCTAssertEqual(user.currentLevel, 5)
    }
    
    func testLevelCalculation() throws {
        var user = User(name: "Test User", email: "test@example.com")
        
        // Test various XP levels
        user.addXP(0)
        XCTAssertEqual(user.currentLevel, 1)
        
        user.addXP(99)
        XCTAssertEqual(user.currentLevel, 1)
        
        user.addXP(1)
        XCTAssertEqual(user.currentLevel, 2)
        
        user.addXP(100)
        XCTAssertEqual(user.currentLevel, 3)
        
        user.addXP(700)
        XCTAssertEqual(user.currentLevel, 10)
    }
    
    func testUniqueEmailConstraint() throws {
        var user1 = User(name: "User 1", email: "test@example.com")
        var user2 = User(name: "User 2", email: "test@example.com")
        
        try dbQueue.write { db in
            try user1.insert(db)
        }
        
        XCTAssertThrowsError(try dbQueue.write { db in
            try user2.insert(db)
        })
    }
    
    func testUserUpdate() throws {
        var user = User(name: "Original Name", email: "test@example.com")
        
        try dbQueue.write { db in
            try user.insert(db)
        }
        
        user.name = "Updated Name"
        user.addXP(100)
        
        try dbQueue.write { db in
            try user.update(db)
        }
        
        let retrievedUser = try dbQueue.read { db in
            try User.fetchOne(db, key: user.id)
        }
        
        XCTAssertEqual(retrievedUser?.name, "Updated Name")
        XCTAssertEqual(retrievedUser?.totalXP, 100)
        XCTAssertEqual(retrievedUser?.currentLevel, 2)
    }
}