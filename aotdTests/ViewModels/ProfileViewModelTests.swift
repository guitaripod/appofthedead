import XCTest
@testable import aotd

final class ProfileViewModelTests: XCTestCase {
    
    var viewModel: ProfileViewModel!
    var databaseManager: DatabaseManager!
    var testUser: User!
    
    override func setUp() {
        super.setUp()
        
        
        databaseManager = DatabaseManager(inMemory: true)
        
        
        let contentLoader = ContentLoader()
        databaseManager.setContentLoader(contentLoader)
        
        
        do {
            testUser = try databaseManager.createAnonymousUser()
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
        
        var dataUpdateCalled = false
        viewModel.onDataUpdate = {
            dataUpdateCalled = true
        }
        
        
        viewModel.loadData()
        
        
        XCTAssertTrue(dataUpdateCalled)
        XCTAssertNotNil(viewModel.user)
        XCTAssertNotNil(viewModel.userStats)
        XCTAssertNotNil(viewModel.achievements)
        XCTAssertNotNil(viewModel.userAchievements)
    }
    
    func testUserStatsCalculation() {
        
        do {
            try databaseManager.addXPToUser(testUser, xp: 150)
        } catch {
            XCTFail("Failed to add XP: \(error)")
        }
        
        
        viewModel.loadData()
        
        
        XCTAssertNotNil(viewModel.userStats)
        XCTAssertEqual(viewModel.userStats?.totalXP, 150)
        XCTAssertEqual(viewModel.userStats?.currentLevel, 2) 
    }
    
    func testAchievementsLoading() {
        
        viewModel.loadData()
        
        
        XCTAssertTrue(viewModel.achievements.count > 0, "Should load achievements from JSON")
        XCTAssertEqual(viewModel.userAchievements.count, 0, "New user should have no achievement progress")
    }
}