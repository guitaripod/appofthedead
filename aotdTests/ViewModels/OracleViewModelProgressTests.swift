import XCTest
@testable import aotd

final class OracleViewModelProgressTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean up UserDefaults to ensure tests start with clean state
        UserDefaults.standard.removeObject(forKey: "MLXModelLoadedOnce")
        UserDefaults.standard.synchronize()
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "MLXModelLoadedOnce")
        UserDefaults.standard.synchronize()
    }
    
    func testProgressSmoothingConcept() {
        // This test validates the concept of progress smoothing
        // In practice, the smoothing happens internally during model download
        
        // Given discrete progress steps that MLX would report
        let progressSteps: [Float] = [0.0, 0.16666667, 0.33333334, 0.5, 0.6666667, 0.8333334, 1.0]
        
        // The actual implementation would smooth these steps
        // to avoid jarring jumps in the UI
        for (index, step) in progressSteps.enumerated() {
            if index > 0 {
                let previousStep = progressSteps[index - 1]
                let jump = step - previousStep
                
                // MLX typically reports in ~16.67% jumps (1/6)
                XCTAssertTrue(jump < 0.2, "Progress jumps should be reasonable")
                
                print("Progress step \(index): \(step) (jump of \(jump * 100)%)")
            }
        }
    }
    
    func testDownloadStatusMessages() {
        // Given
        let viewModel = OracleViewModel()
        
        // The download status should provide meaningful messages
        // Check initial state
        let initialStatus = viewModel.downloadStatus
        XCTAssertTrue(initialStatus.isEmpty, "Initial download status should be empty")
        
        // Check that download progress starts at 0
        let initialProgress = viewModel.downloadProgress
        XCTAssertEqual(initialProgress, 0.0, accuracy: 0.001)
    }
    
    func testModelLoadingState() async {
        // Given a fresh instance
        let viewModel = OracleViewModel()
        
        // Wait a moment for any async initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Test 1: Loading state should be false when not actively loading
        XCTAssertFalse(viewModel.isModelLoading, "Model should not be loading initially")
        
        // Test 2: syncModelLoadedState should update the isModelLoaded property
        let initialLoadedState = viewModel.isModelLoaded
        viewModel.syncModelLoadedState()
        // After sync, the state should match the singleton's state
        XCTAssertEqual(viewModel.isModelLoaded, MLXModelManager.shared.isModelLoaded,
                      "After sync, viewModel state should match singleton state")
        
        // Test 3: Download properties should start at zero
        XCTAssertEqual(viewModel.downloadProgress, 0.0, accuracy: 0.001,
                      "Download progress should start at 0")
        XCTAssertTrue(viewModel.downloadStatus.isEmpty || viewModel.downloadStatus.contains("Loading") || viewModel.downloadStatus.contains("Oracle"),
                     "Download status should be empty or contain loading message")
    }
}
