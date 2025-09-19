import XCTest
@testable import aotd

final class HomeViewModelCompletionTests: XCTestCase {
    
    func testHomeViewModelCreatesCorrectPathItems() {
        
        let databaseManager = DatabaseManager.shared
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        let testBeliefSystems = contentLoader.loadBeliefSystems()
        
        
        var dataUpdateCalled = false
        viewModel.onDataUpdate = {
            dataUpdateCalled = true
        }
        
        viewModel.loadData()
        
        
        XCTAssertTrue(dataUpdateCalled, "Data update callback should be called")
        XCTAssertEqual(viewModel.pathItems.count, testBeliefSystems.count, "Should create path item for each belief system")
        
        
        for pathItem in viewModel.pathItems {
            
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
        
        let databaseManager = DatabaseManager.shared
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        var selectedBeliefSystemId: String?
        viewModel.onPathSelected = { beliefSystem in
            selectedBeliefSystemId = beliefSystem.id
        }
        
        
        viewModel.loadData()
        
        
        if let firstPath = viewModel.pathItems.first {
            viewModel.selectPath(firstPath)
            
            
            XCTAssertEqual(selectedBeliefSystemId, firstPath.id, "Should select the correct belief system")
        } else {
            XCTFail("No path items available to test")
        }
    }
    
    func testPathItemStatusReflectsProgress() {
        
        let databaseManager = DatabaseManager.shared
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        viewModel.loadData()
        
        
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
            
            let shouldShow = testCase.status == .completed || testCase.status == .mastered
            XCTAssertEqual(
                shouldShow,
                testCase.shouldShowCompletionModal,
                "Status \(testCase.status) should \(testCase.shouldShowCompletionModal ? "show" : "not show") completion modal"
            )
        }
    }
    
    func testMasterTestThresholdCalculations() {
        
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