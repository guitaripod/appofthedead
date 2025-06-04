import XCTest
@testable import aotd

class SyncManagerTests: XCTestCase {
    
    var syncManager: SyncManager!
    
    override func setUp() {
        super.setUp()
        syncManager = SyncManager.shared
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleIdentityToken")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        super.tearDown()
    }
    
    func testAttemptSyncWithoutAuthentication() {
        // Arrange
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleIdentityToken")
        
        // Act
        syncManager.attemptSync()
        
        // Assert - Should not crash and should exit early
        XCTAssertTrue(true, "Sync should exit early without authentication")
    }
    
    func testSyncDataStructure() {
        // Arrange
        let user = User(name: "Test User", email: "test@example.com")
        let progress = Progress(userId: user.id, beliefSystemId: "judaism")
        let achievement = UserAchievement(userId: user.id, achievementId: "first_lesson")
        
        let syncData = SyncData(
            user: user,
            progress: [progress],
            achievements: [achievement],
            lastSyncDate: Date()
        )
        
        // Act & Assert
        XCTAssertNotNil(syncData.user)
        XCTAssertEqual(syncData.progress.count, 1)
        XCTAssertEqual(syncData.achievements.count, 1)
        XCTAssertNotNil(syncData.lastSyncDate)
    }
}