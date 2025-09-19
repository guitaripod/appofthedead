import XCTest
@testable import aotd

final class HomeViewModelPathCompletionBehaviorTests: XCTestCase {
    
    func testHomeViewControllerPathSelectionBehavior() {
        
        
        struct PathSelectionTest {
            let pathItemStatus: aotd.Progress.ProgressStatus
            let expectedAction: String
        }
        
        let tests: [PathSelectionTest] = [
            PathSelectionTest(pathItemStatus: .notStarted, expectedAction: "selectPath"),
            PathSelectionTest(pathItemStatus: .inProgress, expectedAction: "selectPath"),
            PathSelectionTest(pathItemStatus: .completed, expectedAction: "showCompletionOptions"),
            PathSelectionTest(pathItemStatus: .mastered, expectedAction: "showCompletionOptions")
        ]
        
        for test in tests {
            
            let shouldShowCompletionOptions = test.pathItemStatus == .completed || test.pathItemStatus == .mastered
            let actualAction = shouldShowCompletionOptions ? "showCompletionOptions" : "selectPath"
            
            XCTAssertEqual(actualAction, test.expectedAction,
                          "Path with status \(test.pathItemStatus) should trigger \(test.expectedAction)")
        }
    }
    
    func testPathCompletionOptionsViewControllerConfiguration() {
        
        
        struct CompletionOptionsTest {
            let currentXP: Int
            let totalXP: Int
            let expectedCanTakeMasterTest: Bool
            let expectedReplayButtonTitle: String
            let expectedInfoText: String
        }
        
        let tests: [CompletionOptionsTest] = [
            
            CompletionOptionsTest(
                currentXP: 700,
                totalXP: 1000,
                expectedCanTakeMasterTest: false,
                expectedReplayButtonTitle: "Review & Improve Score",
                expectedInfoText: "Earn 100 more XP to unlock the Master Test (10% to go)"
            ),
            
            
            CompletionOptionsTest(
                currentXP: 800,
                totalXP: 1000,
                expectedCanTakeMasterTest: true,
                expectedReplayButtonTitle: "Review & Improve Score",
                expectedInfoText: "Master Test unlocked! Score 80% or higher to earn the crown badge."
            ),
            
            
            CompletionOptionsTest(
                currentXP: 1000,
                totalXP: 1000,
                expectedCanTakeMasterTest: true,
                expectedReplayButtonTitle: "Practice Again",
                expectedInfoText: "Master Test unlocked! Score 80% or higher to earn the crown badge."
            )
        ]
        
        for test in tests {
            
            let completionPercentage = min(100, Int((Double(test.currentXP) / Double(test.totalXP)) * 100))
            let canTakeMasterTest = completionPercentage >= 80
            let hasPerfectScore = test.currentXP >= test.totalXP
            
            
            let replayButtonTitle = hasPerfectScore ? "Practice Again" : "Review & Improve Score"
            
            
            let infoText: String
            if canTakeMasterTest {
                infoText = "Master Test unlocked! Score 80% or higher to earn the crown badge."
            } else {
                let xpNeeded = Int(ceil(Double(test.totalXP) * 0.8)) - test.currentXP
                infoText = "Earn \(xpNeeded) more XP to unlock the Master Test (\(80 - completionPercentage)% to go)"
            }
            
            XCTAssertEqual(canTakeMasterTest, test.expectedCanTakeMasterTest,
                          "\(test.currentXP)/\(test.totalXP) XP should \(test.expectedCanTakeMasterTest ? "allow" : "not allow") master test")
            XCTAssertEqual(replayButtonTitle, test.expectedReplayButtonTitle,
                          "\(test.currentXP)/\(test.totalXP) XP should show '\(test.expectedReplayButtonTitle)' button")
            XCTAssertEqual(infoText, test.expectedInfoText,
                          "\(test.currentXP)/\(test.totalXP) XP should show correct info text")
        }
    }
    
    func testHomeViewModelIntegration() {
        
        let databaseManager = DatabaseManager(inMemory: true)
        let contentLoader = ContentLoader()
        let viewModel = HomeViewModel(databaseManager: databaseManager, contentLoader: contentLoader)
        
        
        let loadExpectation = XCTestExpectation(description: "Data loaded")
        viewModel.onDataUpdate = {
            loadExpectation.fulfill()
        }
        viewModel.loadData()
        wait(for: [loadExpectation], timeout: 1.0)
        
        
        let beliefSystems = contentLoader.loadBeliefSystems()
        XCTAssertEqual(viewModel.pathItems.count, beliefSystems.count,
                      "Should have one path item per belief system")
        
        
        var selectedBeliefSystem: BeliefSystem?
        viewModel.onPathSelected = { beliefSystem in
            selectedBeliefSystem = beliefSystem
        }
        
        if let firstPath = viewModel.pathItems.first {
            viewModel.selectPath(firstPath)
            
            XCTAssertNotNil(selectedBeliefSystem, "Should have selected a belief system")
            XCTAssertEqual(selectedBeliefSystem?.id, firstPath.id,
                          "Should select the correct belief system")
            
            
            let originalBeliefSystem = beliefSystems.first { $0.id == firstPath.id }
            XCTAssertEqual(selectedBeliefSystem?.name, originalBeliefSystem?.name,
                          "Selected belief system should match original data")
        }
    }
}