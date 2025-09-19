import XCTest
@testable import aotd

final class HomeViewModelSortingTests: XCTestCase {
    
    func testUnlockedPathsAppearFirst() {
        
        let databaseManager = DatabaseManager(inMemory: true)
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        viewModel.loadData()
        
        
        XCTAssertGreaterThan(viewModel.pathItems.count, 3, "Should have multiple paths")
        
        let firstPath = viewModel.pathItems.first
        XCTAssertNotNil(firstPath)
        XCTAssertEqual(firstPath?.id, "judaism", "Judaism should be first as it's the only free path")
        XCTAssertTrue(firstPath?.isUnlocked ?? false, "Judaism should be unlocked")
        
        
        var foundLockedPath = false
        var foundUnlockedAfterLocked = false
        
        for (index, path) in viewModel.pathItems.enumerated() {
            if !path.isUnlocked {
                foundLockedPath = true
            } else if foundLockedPath {
                foundUnlockedAfterLocked = true
                break
            }
        }
        
        XCTAssertTrue(foundLockedPath, "Should have at least one locked path")
        XCTAssertFalse(foundUnlockedAfterLocked, "No unlocked paths should appear after locked ones")
    }
    
    func testPathOrderingWithinUnlockedAndLockedGroups() {
        
        let databaseManager = DatabaseManager(inMemory: true)
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        viewModel.loadData()
        
        
        let originalBeliefSystems = contentLoader.loadBeliefSystems()
        
        
        let unlockedPaths = viewModel.pathItems.filter { $0.isUnlocked }
        let lockedPaths = viewModel.pathItems.filter { !$0.isUnlocked }
        
        
        var lastUnlockedIndex = -1
        for path in unlockedPaths {
            let originalIndex = originalBeliefSystems.firstIndex { $0.id == path.id } ?? -1
            XCTAssertGreaterThan(originalIndex, lastUnlockedIndex, 
                                "Unlocked paths should maintain original order: \(path.name)")
            lastUnlockedIndex = originalIndex
        }
        
        
        var lastLockedIndex = -1
        for path in lockedPaths {
            let originalIndex = originalBeliefSystems.firstIndex { $0.id == path.id } ?? -1
            XCTAssertGreaterThan(originalIndex, lastLockedIndex, 
                                "Locked paths should maintain original order: \(path.name)")
            lastLockedIndex = originalIndex
        }
    }
    
    func testSpecificPathOrder() {
        
        let databaseManager = DatabaseManager(inMemory: true)
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        viewModel.loadData()
        
        
        let unlockedPaths = viewModel.pathItems.filter { $0.isUnlocked }
        XCTAssertEqual(unlockedPaths.count, 1, "Only one path should be unlocked by default")
        XCTAssertEqual(unlockedPaths.first?.id, "judaism", "Judaism should be the only unlocked path")
        
        
        let pathIds = viewModel.pathItems.map { $0.id }
        let judaismIndex = pathIds.firstIndex(of: "judaism") ?? -1
        let christianityIndex = pathIds.firstIndex(of: "christianity") ?? -1
        let islamIndex = pathIds.firstIndex(of: "islam") ?? -1
        
        XCTAssertEqual(judaismIndex, 0, "Judaism should be first")
        XCTAssertGreaterThan(christianityIndex, judaismIndex, "Christianity should come after Judaism")
        XCTAssertGreaterThan(islamIndex, christianityIndex, "Islam should come after Christianity")
    }
    
    func testSortingAfterProgressUpdate() throws {
        
        let databaseManager = DatabaseManager(inMemory: true)
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        viewModel.loadData()
        let user = databaseManager.fetchUser()!
        
        
        let initialOrder = viewModel.pathItems.map { $0.id }
        
        
        try databaseManager.createOrUpdateProgress(
            userId: user.id,
            beliefSystemId: "judaism",
            status: .completed,
            score: 160
        )
        
        
        viewModel.loadData()
        
        
        let unlockedCount = viewModel.pathItems.filter { $0.isUnlocked }.count
        XCTAssertEqual(unlockedCount, 1, "In-memory database doesn't persist purchases, so only Judaism remains unlocked")
        
        
        let firstLockedIndex = viewModel.pathItems.firstIndex { !$0.isUnlocked } ?? viewModel.pathItems.count
        let unlockedPaths = Array(viewModel.pathItems.prefix(firstLockedIndex))
        
        for path in unlockedPaths {
            XCTAssertTrue(path.isUnlocked, "All paths before first locked path should be unlocked")
        }
    }
}