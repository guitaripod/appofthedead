import XCTest
import GRDB
@testable import aotd
import AppOfTheDeadCore

@MainActor final class HomeViewModelTests: XCTestCase {
    
    var sut: HomeViewModel!
    var mockDatabaseManager: DatabaseManager!
    var mockContentLoader: ContentLoader!
    
    override func setUp() async throws {
        try await super.setUp()
        mockDatabaseManager = DatabaseManager(inMemory: true)
        mockContentLoader = ContentLoader()
        mockDatabaseManager.setContentLoader(mockContentLoader)
        sut = HomeViewModel(databaseManager: mockDatabaseManager, contentLoader: mockContentLoader)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockDatabaseManager = nil
        mockContentLoader = nil
        try await super.tearDown()
    }
    
    func testLoadDataPopulatesPathItems() {
        
        let expectation = XCTestExpectation(description: "Data loaded")
        sut.onDataUpdate = {
            expectation.fulfill()
        }
        
        
        sut.loadData()
        
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.pathItems.isEmpty)
        XCTAssertEqual(sut.pathItems.count, 22) 
    }
    
    func testOnlyJudaismIsUnlockedByDefault() {
        
        sut.loadData()
        
        
        let expectedUnlocked = FreePathExpectation.unlockedIds()
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        XCTAssertNotNil(judaismPath)
        XCTAssertTrue(judaismPath!.isUnlocked, "Judaism should be unlocked")
        XCTAssertEqual(Set(sut.pathItems.filter { $0.isUnlocked }.map { $0.id }), expectedUnlocked)
        XCTAssertEqual(Set(sut.pathItems.prefix(expectedUnlocked.count).map { $0.id }), expectedUnlocked, "Unlocked paths should come first")
        
        
        let christianityPath = sut.pathItems.first { $0.id == "christianity" }
        let islamPath = sut.pathItems.first { $0.id == "islam" }
        
        XCTAssertNotNil(christianityPath)
        XCTAssertNotNil(islamPath)
        
        XCTAssertFalse(christianityPath!.isUnlocked, "Christianity should be locked by default")
        XCTAssertFalse(islamPath!.isUnlocked, "Islam should be locked by default")
    }
    
    func testOtherPathsAreLockedInitially() {
        
        sut.loadData()
        
        
        let hinduismPath = sut.pathItems.first { $0.id == "hinduism" }
        let buddhismPath = sut.pathItems.first { $0.id == "buddhism" }
        
        XCTAssertNotNil(hinduismPath)
        XCTAssertNotNil(buddhismPath)
        
        XCTAssertFalse(hinduismPath!.isUnlocked)
        XCTAssertFalse(buddhismPath!.isUnlocked)
    }
    
    func testPathItemsHaveCorrectProperties() {
        
        sut.loadData()
        
        
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        
        XCTAssertNotNil(judaismPath)
        XCTAssertEqual(judaismPath!.name, "Judaism")
        XCTAssertEqual(judaismPath!.icon, "star_of_david")
        XCTAssertEqual(judaismPath!.totalXP, 700)
        XCTAssertEqual(judaismPath!.currentXP, 0) 
        XCTAssertEqual(judaismPath!.progress, 0.0)
    }
    
    func testSelectPathTriggersCallback() {
        
        sut.loadData()
        let expectation = XCTestExpectation(description: "Path selected")
        var selectedBeliefSystem: BeliefSystem?
        
        sut.onPathSelected = { beliefSystem in
            selectedBeliefSystem = beliefSystem
            expectation.fulfill()
        }
        
        let pathItem = sut.pathItems.first!
        
        
        sut.selectPath(pathItem)
        
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(selectedBeliefSystem)
        XCTAssertEqual(selectedBeliefSystem!.id, pathItem.id)
    }
    
    func testUserDataUpdateTriggersCallback() {
        
        let expectation = XCTestExpectation(description: "User data updated")
        var receivedUser: User?
        
        sut.onUserDataUpdate = { user in
            receivedUser = user
            expectation.fulfill()
        }
        
        
        sut.loadData()
        
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedUser)
        XCTAssertFalse(receivedUser!.id.isEmpty)
        XCTAssertEqual(receivedUser!.totalXP, 0)
    }
    
    func testProgressUpdatesPathItemXP() throws {
        
        sut.loadData()
        let user = mockDatabaseManager.fetchUser()!
        
        
        try mockDatabaseManager.addXPToProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            xp: 50
        )
        
        
        sut.loadData()
        
        
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        XCTAssertNotNil(judaismPath)
        XCTAssertTrue(judaismPath!.isUnlocked, "Judaism should stay unlocked")
        XCTAssertEqual(judaismPath!.currentXP, 50)
        XCTAssertEqual(judaismPath!.progress, 50.0 / 700)
    }
    
    func testCompletingPathDoesNotAutomaticallyUnlockOthers() throws {
        
        sut.loadData()
        let user = mockDatabaseManager.fetchUser()!
        
        
        try mockDatabaseManager.addXPToProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            xp: 450
        )
        try mockDatabaseManager.createOrUpdateProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            status: .completed,
            score: 450
        )
        
        
        sut.loadData()
        
        
        let hinduismPath = sut.pathItems.first { $0.id == "hinduism" }
        let buddhismPath = sut.pathItems.first { $0.id == "buddhism" }
        
        XCTAssertNotNil(hinduismPath)
        XCTAssertNotNil(buddhismPath)
        
        XCTAssertFalse(hinduismPath!.isUnlocked, "Hinduism should still be locked without purchase")
        XCTAssertFalse(buddhismPath!.isUnlocked, "Buddhism should still be locked without purchase")
        
        
        let expectedUnlocked = FreePathExpectation.unlockedIds()
        XCTAssertEqual(Set(sut.pathItems.prefix(expectedUnlocked.count).map { $0.id }), expectedUnlocked, "Only the free paths should stay first")
    }
    
    func testPathItemColorsAreCorrect() {
        
        sut.loadData()
        
        
        let judaismPath = sut.pathItems.first { $0.id == "judaism" }
        let christianityPath = sut.pathItems.first { $0.id == "christianity" }
        
        XCTAssertNotNil(judaismPath)
        XCTAssertNotNil(christianityPath)
        
        
        XCTAssertNotEqual(judaismPath!.color, UIColor.systemGray)
        XCTAssertNotEqual(christianityPath!.color, UIColor.systemGray)
    }
}
