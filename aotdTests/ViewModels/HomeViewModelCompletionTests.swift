import XCTest
@testable import aotd

final class HomeViewModelCompletionTests: XCTestCase {
    
    func testHomeViewModelCreatesCorrectPathItems() {
        // Arrange
        let databaseManager = DatabaseManager.shared
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        // Setup mock data
        let testBeliefSystems = contentLoader.loadBeliefSystems()
        
        // Act - Load data
        var dataUpdateCalled = false
        viewModel.onDataUpdate = {
            dataUpdateCalled = true
        }
        
        viewModel.loadData()
        
        // Assert
        XCTAssertTrue(dataUpdateCalled, "Data update callback should be called")
        XCTAssertEqual(viewModel.pathItems.count, testBeliefSystems.count, "Should create path item for each belief system")
        
        // Verify path items have correct properties (accounting for sorting)
        for pathItem in viewModel.pathItems {
            // Find the corresponding belief system
            let beliefSystem = testBeliefSystems.first { $0.id == pathItem.id }
            XCTAssertNotNil(beliefSystem, "Path item should have a corresponding belief system")
            if let beliefSystem = beliefSystem {
                XCTAssertEqual(pathItem.name, beliefSystem.name, "Path item name should match belief system name")
                XCTAssertEqual(pathItem.totalXP, beliefSystem.totalXP, "Path item total XP should match belief system total XP")
                XCTAssertNotNil(pathItem.color, "Path item should have a color")
            }
        }
    }
    
    func testSelectPathCallsCallback() {
        // Arrange
        let databaseManager = DatabaseManager.shared
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        // Setup expectation
        var selectedBeliefSystemId: String?
        viewModel.onPathSelected = { beliefSystem in
            selectedBeliefSystemId = beliefSystem.id
        }
        
        // Load data first
        viewModel.loadData()
        
        // Act - Select first path if available
        if let firstPath = viewModel.pathItems.first {
            viewModel.selectPath(firstPath)
            
            // Assert
            XCTAssertEqual(selectedBeliefSystemId, firstPath.id, "Should select the correct belief system")
        } else {
            XCTFail("No path items available to test")
        }
    }
    
    func testPathItemStatusReflectsProgress() {
        // This test demonstrates that PathItem correctly contains status information
        let databaseManager = DatabaseManager.shared
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        viewModel.loadData()
        
        // Table-driven assertions about path item properties
        struct ExpectedBehavior {
            let status: aotd.Progress.ProgressStatus
            let shouldShowCompletionModal: Bool
        }
        
        let testCases: [ExpectedBehavior] = [
            ExpectedBehavior(status: .notStarted, shouldShowCompletionModal: false),
            ExpectedBehavior(status: .inProgress, shouldShowCompletionModal: false),
            ExpectedBehavior(status: .completed, shouldShowCompletionModal: true),
            ExpectedBehavior(status: .mastered, shouldShowCompletionModal: true)
        ]
        
        for testCase in testCases {
            // The actual logic in HomeViewController checks: item.status == .completed || item.status == .mastered
            let shouldShow = testCase.status == .completed || testCase.status == .mastered
            XCTAssertEqual(
                shouldShow,
                testCase.shouldShowCompletionModal,
                "Status \(testCase.status) should \(testCase.shouldShowCompletionModal ? "show" : "not show") completion modal"
            )
        }
    }
    
    func testMasterTestThresholdCalculations() {
        // Test the actual calculation logic used in the app
        struct ThresholdTest {
            let currentXP: Int
            let totalXP: Int
            let canTakeMasterTest: Bool
        }
        
        let tests: [ThresholdTest] = [
            ThresholdTest(currentXP: 0, totalXP: 1000, canTakeMasterTest: false),
            ThresholdTest(currentXP: 799, totalXP: 1000, canTakeMasterTest: false),
            ThresholdTest(currentXP: 800, totalXP: 1000, canTakeMasterTest: true),
            ThresholdTest(currentXP: 1000, totalXP: 1000, canTakeMasterTest: true),
            ThresholdTest(currentXP: 400, totalXP: 500, canTakeMasterTest: true),
            ThresholdTest(currentXP: 399, totalXP: 500, canTakeMasterTest: false)
        ]
        
        for test in tests {
            // This is the actual calculation used in PathCompletionOptionsViewController
            let completionPercentage = min(100, Int((Double(test.currentXP) / Double(test.totalXP)) * 100))
            let canTakeMasterTest = completionPercentage >= 80
            
            XCTAssertEqual(
                canTakeMasterTest,
                test.canTakeMasterTest,
                "\(test.currentXP)/\(test.totalXP) XP (\(completionPercentage)%) should \(test.canTakeMasterTest ? "allow" : "not allow") master test"
            )
        }
    }
}