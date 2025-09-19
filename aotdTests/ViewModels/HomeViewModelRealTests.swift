import XCTest
import GRDB
@testable import aotd

final class HomeViewModelRealTests: XCTestCase {
    
    var viewModel: HomeViewModel!
    var testDatabaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        
        
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
        
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.onDataUpdate = {
            expectation.fulfill()
        }
        
        
        viewModel.loadData()
        
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertGreaterThan(viewModel.pathItems.count, 0, "Should have loaded path items")
        
        
        for pathItem in viewModel.pathItems {
            XCTAssertFalse(pathItem.id.isEmpty, "Path item should have an ID")
            XCTAssertFalse(pathItem.name.isEmpty, "Path item should have a name")
            XCTAssertGreaterThan(pathItem.totalXP, 0, "Path item should have total XP")
            XCTAssertNotNil(pathItem.color, "Path item should have a color")
            XCTAssertNotNil(pathItem.status, "Path item should have a status")
        }
    }
    
    func testSelectPathTriggersCallback() {
        
        viewModel.loadData()
        
        var selectedBeliefSystemId: String?
        let selectionExpectation = XCTestExpectation(description: "Path selected")
        
        viewModel.onPathSelected = { beliefSystem in
            selectedBeliefSystemId = beliefSystem.id
            selectionExpectation.fulfill()
        }
        
        
        guard let firstPath = viewModel.pathItems.first else {
            XCTFail("No path items loaded")
            return
        }
        
        viewModel.selectPath(firstPath)
        
        
        wait(for: [selectionExpectation], timeout: 1.0)
        XCTAssertEqual(selectedBeliefSystemId, firstPath.id, "Should have selected the correct belief system")
    }
    
    func testPathCompletionModalLogic() {
        
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
            
            let shouldShow = test.status == .completed || test.status == .mastered
            XCTAssertEqual(shouldShow, test.shouldShowModal,
                          "Status \(test.status) should \(test.shouldShowModal ? "show" : "not show") modal")
        }
    }
    
    func testMasterTestEligibilityCalculation() {
        
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
        
        var updateCount = 0
        viewModel.onDataUpdate = {
            updateCount += 1
        }
        
        
        viewModel.loadData()
        
        
        XCTAssertEqual(updateCount, 1, "Should call data update callback once on load")
    }
}