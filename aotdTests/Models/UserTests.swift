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
        let user = User()

        XCTAssertFalse(user.id.isEmpty)
        XCTAssertEqual(user.totalXP, 0)
        XCTAssertEqual(user.currentLevel, 1)
        XCTAssertEqual(user.streakDays, 0)
        XCTAssertNil(user.lastActiveDate)
        XCTAssertNotNil(user.createdAt)
        XCTAssertNotNil(user.updatedAt)
    }
    
    func testUserPersistence() throws {
        var user = User()

        try dbQueue.write { db in
            try user.insert(db)
        }

        let retrievedUser = try dbQueue.read { db in
            try User.fetchOne(db, key: user.id)
        }

        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.id, user.id)
    }
    
    func testAddXP() throws {
        var user = User()

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
        var user = User()


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
    
    func testUniqueIdConstraint() throws {
        var user1 = User()
        var user2 = User()

        try dbQueue.write { db in
            try user1.insert(db)
        }

        var user3 = User()
        user3.id = user1.id // Try to insert with same ID

        XCTAssertThrowsError(try dbQueue.write { db in
            try user3.insert(db)
        })
    }
    
    func testUserUpdate() throws {
        var user = User()

        try dbQueue.write { db in
            try user.insert(db)
        }

        user.addXP(100)

        try dbQueue.write { db in
            try user.update(db)
        }

        let retrievedUser = try dbQueue.read { db in
            try User.fetchOne(db, key: user.id)
        }

        XCTAssertEqual(retrievedUser?.totalXP, 100)
        XCTAssertEqual(retrievedUser?.currentLevel, 2)
    }
}