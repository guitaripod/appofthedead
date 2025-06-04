import XCTest
import GRDB
@testable import aotd

final class HomeViewModelTests: XCTestCase {
    
    var sut: HomeViewModel!
    var mockDatabaseManager: DatabaseManager!
    var mockContentLoader: ContentLoader!
    
    override func setUp() {
        super.setUp()
        mockDatabaseManager = DatabaseManager(inMemory: true)
        mockContentLoader = ContentLoader()
        mockDatabaseManager.setContentLoader(mockContentLoader)
        sut = HomeViewModel(databaseManager: mockDatabaseManager, contentLoader: mockContentLoader)
    }
    
    override func tearDown() {
        sut = nil
        mockDatabaseManager = nil
        mockContentLoader = nil
        super.tearDown()
    }
    
    func testLoadDataPopulatesPathItems() {
        // Given
        let expectation = XCTestExpectation(description: "Data loaded")
        sut.onDataUpdate = {
            expectation.fulfill()
        }
        
        // When
        sut.loadData()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.pathItems.isEmpty)
        XCTAssertEqual(sut.pathItems.count, 21) // Based on the belief systems in aotd.json
    }
    
    func testFirstThreePathsAreUnlocked() {
        // When
        sut.loadData()
        
        // Then
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        let christianityPath = sut.pathItems.first { $0.id == "christianity" }
        let islamPath = sut.pathItems.first { $0.id == "islam" }
        
        XCTAssertNotNil(judaismPath)
        XCTAssertNotNil(christianityPath)
        XCTAssertNotNil(islamPath)
        
        XCTAssertTrue(judaismPath!.isUnlocked)
        XCTAssertTrue(christianityPath!.isUnlocked)
        XCTAssertTrue(islamPath!.isUnlocked)
    }
    
    func testOtherPathsAreLockedInitially() {
        // When
        sut.loadData()
        
        // Then
        let hinduismPath = sut.pathItems.first { $0.id == "hinduism" }
        let buddhismPath = sut.pathItems.first { $0.id == "buddhism" }
        
        XCTAssertNotNil(hinduismPath)
        XCTAssertNotNil(buddhismPath)
        
        XCTAssertFalse(hinduismPath!.isUnlocked)
        XCTAssertFalse(buddhismPath!.isUnlocked)
    }
    
    func testPathItemsHaveCorrectProperties() {
        // When
        sut.loadData()
        
        // Then
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        
        XCTAssertNotNil(judaismPath)
        XCTAssertEqual(judaismPath!.name, "Judaism")
        XCTAssertEqual(judaismPath!.icon, "star_of_david")
        XCTAssertEqual(judaismPath!.totalXP, 160)
        XCTAssertEqual(judaismPath!.currentXP, 0) // No progress initially
        XCTAssertEqual(judaismPath!.progress, 0.0)
    }
    
    func testSelectPathTriggersCallback() {
        // Given
        sut.loadData()
        let expectation = XCTestExpectation(description: "Path selected")
        var selectedBeliefSystem: BeliefSystem?
        
        sut.onPathSelected = { beliefSystem in
            selectedBeliefSystem = beliefSystem
            expectation.fulfill()
        }
        
        let pathItem = sut.pathItems.first!
        
        // When
        sut.selectPath(pathItem)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(selectedBeliefSystem)
        XCTAssertEqual(selectedBeliefSystem!.id, pathItem.id)
    }
    
    func testUserDataUpdateTriggersCallback() {
        // Given
        let expectation = XCTestExpectation(description: "User data updated")
        var receivedUser: User?
        
        sut.onUserDataUpdate = { user in
            receivedUser = user
            expectation.fulfill()
        }
        
        // When
        sut.loadData()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedUser)
        XCTAssertEqual(receivedUser!.name, "Learner")
        XCTAssertEqual(receivedUser!.email, "learner@aotd.com")
    }
    
    func testProgressUpdatesPathItemXP() throws {
        // Given
        sut.loadData()
        let user = mockDatabaseManager.fetchUser()!
        
        // When - Add XP for Judaism
        try mockDatabaseManager.addXPToProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            xp: 50
        )
        
        // Reload data
        sut.loadData()
        
        // Then
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        XCTAssertNotNil(judaismPath)
        XCTAssertEqual(judaismPath!.currentXP, 50)
        XCTAssertEqual(judaismPath!.progress, 50.0 / 160.0)
    }
    
    func testCompletingPathUnlocksOthers() throws {
        // Given
        sut.loadData()
        let user = mockDatabaseManager.fetchUser()!
        
        // When - Complete Judaism path with full XP
        try mockDatabaseManager.addXPToProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            xp: 160
        )
        try mockDatabaseManager.createOrUpdateProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            status: .completed,
            score: 160
        )
        
        // Reload data
        sut.loadData()
        
        // Then - Other paths should now be unlocked
        let hinduismPath = sut.pathItems.first { $0.id == "hinduism" }
        let buddhismPath = sut.pathItems.first { $0.id == "buddhism" }
        
        XCTAssertNotNil(hinduismPath)
        XCTAssertNotNil(buddhismPath)
        
        XCTAssertTrue(hinduismPath!.isUnlocked)
        XCTAssertTrue(buddhismPath!.isUnlocked)
    }
    
    func testPathItemColorsAreCorrect() {
        // When
        sut.loadData()
        
        // Then
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        let christianityPath = sut.pathItems.first { $0.id == "christianity" }
        
        XCTAssertNotNil(judaismPath)
        XCTAssertNotNil(christianityPath)
        
        // Check that colors are properly converted from hex
        XCTAssertNotEqual(judaismPath!.color, UIColor.systemGray)
        XCTAssertNotEqual(christianityPath!.color, UIColor.systemGray)
    }
}