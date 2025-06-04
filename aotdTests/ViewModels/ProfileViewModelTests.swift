import XCTest
@testable import aotd

final class ProfileViewModelTests: XCTestCase {
    
    var viewModel: ProfileViewModel!
    var databaseManager: DatabaseManager!
    var testUser: User!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory database for testing
        databaseManager = DatabaseManager(inMemory: true)
        
        // Set up content loader
        let contentLoader = ContentLoader()
        databaseManager.setContentLoader(contentLoader)
        
        // Create test user
        do {
            testUser = try databaseManager.createUser(name: "Test User", email: "test@profile.com")
        } catch {
            XCTFail("Failed to create test user: \(error)")
        }
        
        viewModel = ProfileViewModel(databaseManager: databaseManager)
    }
    
    override func tearDown() {
        testUser = nil
        viewModel = nil
        databaseManager = nil
        super.tearDown()
    }
    
    func testLoadData() {
        // Given
        var dataUpdateCalled = false
        viewModel.onDataUpdate = {
            dataUpdateCalled = true
        }
        
        // When
        viewModel.loadData()
        
        // Then
        XCTAssertTrue(dataUpdateCalled)
        XCTAssertNotNil(viewModel.user)
        XCTAssertNotNil(viewModel.userStats)
        XCTAssertNotNil(viewModel.achievements)
        XCTAssertNotNil(viewModel.userAchievements)
    }
    
    func testUserStatsCalculation() {
        // Given - Add some XP to the user
        do {
            try databaseManager.addXPToUser(userId: testUser.id, xp: 150)
        } catch {
            XCTFail("Failed to add XP: \(error)")
        }
        
        // When
        viewModel.loadData()
        
        // Then
        XCTAssertNotNil(viewModel.userStats)
        XCTAssertEqual(viewModel.userStats?.totalXP, 150)
        XCTAssertEqual(viewModel.userStats?.currentLevel, 2) // 150 XP = level 2
    }
    
    func testAchievementsLoading() {
        // When
        viewModel.loadData()
        
        // Then
        XCTAssertTrue(viewModel.achievements.count > 0, "Should load achievements from JSON")
        XCTAssertEqual(viewModel.userAchievements.count, 0, "New user should have no achievement progress")
    }
}