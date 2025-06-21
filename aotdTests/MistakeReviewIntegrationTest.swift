import XCTest
@testable import aotd

final class MistakeReviewIntegrationTest: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var contentLoader: ContentLoader!
    var user: User!
    var beliefSystem: BeliefSystem!
    
    override func setUp() {
        super.setUp()
        
        // Setup database and content
        databaseManager = DatabaseManager(inMemory: true)
        contentLoader = ContentLoader()
        databaseManager.setContentLoader(contentLoader)
        
        // Create test user
        user = try! databaseManager.createUser(name: "Test User", email: "test@example.com")
        
        // Get a belief system
        beliefSystem = contentLoader.loadBeliefSystems().first!
    }
    
    override func tearDown() {
        databaseManager = nil
        contentLoader = nil
        user = nil
        beliefSystem = nil
        super.tearDown()
    }
    
    func testMistakeReviewFlowUpdatesCountProperly() throws {
        // Given - Create 3 mistakes
        let questionIds = ["q1", "q2", "q3"]
        for id in questionIds {
            try databaseManager.saveMistake(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: nil,
                questionId: id,
                incorrectAnswer: "Wrong",
                correctAnswer: "Right"
            )
        }
        
        // Initial count should be 3
        var count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 3)
        
        // When - Start a review session
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(mistakes.count, 3)
        
        // Review first mistake correctly
        try databaseManager.updateMistakeReview(mistakeId: mistakes[0].id, wasCorrect: true)
        
        // Count should drop to 2 (first mistake is scheduled for future review)
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 2)
        
        // Review second mistake incorrectly
        try databaseManager.updateMistakeReview(mistakeId: mistakes[1].id, wasCorrect: false)
        
        // Count should still be 2 (second mistake reset but still available)
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 2)
        
        // Review third mistake correctly
        try databaseManager.updateMistakeReview(mistakeId: mistakes[2].id, wasCorrect: true)
        
        // Count should drop to 1 (only the incorrectly answered one remains)
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 1)
    }
}