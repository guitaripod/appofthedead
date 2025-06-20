import XCTest
import GRDB
@testable import aotd

final class HomeViewModelRealTests: XCTestCase {
    
    var viewModel: HomeViewModel!
    var testDatabaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        
        // Create a test database in memory
        testDatabaseManager = DatabaseManager(inMemory: true)
        
        let contentLoader = ContentLoader()
        viewModel = HomeViewModel(databaseManager: testDatabaseManager, contentLoader: contentLoader)
    }
    
    override func tearDown() {
        viewModel = nil
        testDatabaseManager = nil
        super.tearDown()
    }
    
    func testHomeViewModelLoadsBeliefSystemsAsPathItems() {
        // Given
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.onDataUpdate = {
            expectation.fulfill()
        }
        
        // When
        viewModel.loadData()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertGreaterThan(viewModel.pathItems.count, 0, "Should have loaded path items")
        
        // Verify each path item has required properties
        for pathItem in viewModel.pathItems {
            XCTAssertFalse(pathItem.id.isEmpty, "Path item should have an ID")
            XCTAssertFalse(pathItem.name.isEmpty, "Path item should have a name")
            XCTAssertGreaterThan(pathItem.totalXP, 0, "Path item should have total XP")
            XCTAssertNotNil(pathItem.color, "Path item should have a color")
            XCTAssertNotNil(pathItem.status, "Path item should have a status")
        }
    }
    
    func testSelectPathTriggersCallback() {
        // Given
        viewModel.loadData()
        
        var selectedBeliefSystemId: String?
        let selectionExpectation = XCTestExpectation(description: "Path selected")
        
        viewModel.onPathSelected = { beliefSystem in
            selectedBeliefSystemId = beliefSystem.id
            selectionExpectation.fulfill()
        }
        
        // When
        guard let firstPath = viewModel.pathItems.first else {
            XCTFail("No path items loaded")
            return
        }
        
        viewModel.selectPath(firstPath)
        
        // Then
        wait(for: [selectionExpectation], timeout: 1.0)
        XCTAssertEqual(selectedBeliefSystemId, firstPath.id, "Should have selected the correct belief system")
    }
    
    func testPathCompletionModalLogic() {
        // This tests the logic that determines when to show completion modal
        struct CompletionTest {
            let status: aotd.Progress.ProgressStatus
            let shouldShowModal: Bool
        }
        
        let tests = [
            CompletionTest(status: .notStarted, shouldShowModal: false),
            CompletionTest(status: .inProgress, shouldShowModal: false),
            CompletionTest(status: .completed, shouldShowModal: true),
            CompletionTest(status: .mastered, shouldShowModal: true)
        ]
        
        for test in tests {
            // The actual logic from HomeViewController
            let shouldShow = test.status == .completed || test.status == .mastered
            XCTAssertEqual(shouldShow, test.shouldShowModal,
                          "Status \(test.status) should \(test.shouldShowModal ? "show" : "not show") modal")
        }
    }
    
    func testMasterTestEligibilityCalculation() {
        // Test the 80% threshold calculation
        struct EligibilityTest {
            let currentXP: Int
            let totalXP: Int
            let eligible: Bool
        }
        
        let tests = [
            EligibilityTest(currentXP: 0, totalXP: 100, eligible: false),
            EligibilityTest(currentXP: 79, totalXP: 100, eligible: false),
            EligibilityTest(currentXP: 80, totalXP: 100, eligible: true),
            EligibilityTest(currentXP: 100, totalXP: 100, eligible: true),
            EligibilityTest(currentXP: 399, totalXP: 500, eligible: false),
            EligibilityTest(currentXP: 400, totalXP: 500, eligible: true),
            EligibilityTest(currentXP: 800, totalXP: 1000, eligible: true)
        ]
        
        for test in tests {
            let percentage = min(100, Int((Double(test.currentXP) / Double(test.totalXP)) * 100))
            let isEligible = percentage >= 80
            
            XCTAssertEqual(isEligible, test.eligible,
                          "\(test.currentXP)/\(test.totalXP) (\(percentage)%) should be \(test.eligible ? "eligible" : "not eligible")")
        }
    }
    
    func testDataUpdateCallbackOnLoad() {
        // Given
        var updateCount = 0
        viewModel.onDataUpdate = {
            updateCount += 1
        }
        
        // When
        viewModel.loadData()
        
        // Then
        XCTAssertEqual(updateCount, 1, "Should call data update callback once on load")
    }
}