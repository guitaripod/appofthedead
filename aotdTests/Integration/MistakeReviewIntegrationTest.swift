import XCTest
@testable import aotd

final class MistakeReviewIntegrationTest: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var contentLoader: ContentLoader!
    var user: User!
    var beliefSystem: BeliefSystem!
    
    override func setUp() {
        super.setUp()
        
        
        databaseManager = DatabaseManager(inMemory: true)
        contentLoader = ContentLoader()
        databaseManager.setContentLoader(contentLoader)
        
        
        user = try! databaseManager.createUser(name: "Test User", email: "test@example.com")
        
        
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
        
        
        var count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 3)
        
        
        let mistakes = try databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(mistakes.count, 3)
        
        
        try databaseManager.updateMistakeReview(mistakeId: mistakes[0].id, wasCorrect: true)
        
        
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 2)
        
        
        try databaseManager.updateMistakeReview(mistakeId: mistakes[1].id, wasCorrect: false)
        
        
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 2)
        
        
        try databaseManager.updateMistakeReview(mistakeId: mistakes[2].id, wasCorrect: true)
        
        
        count = try databaseManager.getMistakeCount(userId: user.id, beliefSystemId: beliefSystem.id)
        XCTAssertEqual(count, 1)
    }
}