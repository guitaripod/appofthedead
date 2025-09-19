import XCTest
@testable import aotd

final class OracleViewModelProgressTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        UserDefaults.standard.removeObject(forKey: "MLXModelLoadedOnce")
        UserDefaults.standard.synchronize()
    }
    
    override func tearDown() {
        super.tearDown()
        
        UserDefaults.standard.removeObject(forKey: "MLXModelLoadedOnce")
        UserDefaults.standard.synchronize()
    }
    
    func testProgressSmoothingConcept() {
        
        
        
        
        let progressSteps: [Float] = [0.0, 0.16666667, 0.33333334, 0.5, 0.6666667, 0.8333334, 1.0]
        
        
        
        for (index, step) in progressSteps.enumerated() {
            if index > 0 {
                let previousStep = progressSteps[index - 1]
                let jump = step - previousStep
                
                
                XCTAssertTrue(jump < 0.2, "Progress jumps should be reasonable")
                
                print("Progress step \(index): \(step) (jump of \(jump * 100)%)")
            }
        }
    }
    
    func testDownloadStatusMessages() {
        
        let viewModel = OracleViewModel()
        
        
        
        let initialStatus = viewModel.downloadStatus
        XCTAssertTrue(initialStatus.isEmpty, "Initial download status should be empty")
        
        
        let initialProgress = viewModel.downloadProgress
        XCTAssertEqual(initialProgress, 0.0, accuracy: 0.001)
    }
    
    func testModelLoadingState() async {
        
        let viewModel = OracleViewModel()
        
        
        try? await Task.sleep(nanoseconds: 100_000_000) 
        
        
        XCTAssertFalse(viewModel.isModelLoading, "Model should not be loading initially")
        
        
        let initialLoadedState = viewModel.isModelLoaded
        viewModel.syncModelLoadedState()
        
        XCTAssertEqual(viewModel.isModelLoaded, MLXModelManager.shared.isModelLoaded,
                      "After sync, viewModel state should match singleton state")
        
        
        XCTAssertEqual(viewModel.downloadProgress, 0.0, accuracy: 0.001,
                      "Download progress should start at 0")
        XCTAssertTrue(viewModel.downloadStatus.isEmpty || viewModel.downloadStatus.contains("Loading") || viewModel.downloadStatus.contains("Oracle"),
                     "Download status should be empty or contain loading message")
    }
}
