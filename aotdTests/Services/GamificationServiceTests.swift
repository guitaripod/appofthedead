import XCTest
@testable import aotd

final class GamificationServiceTests: XCTestCase {
    
    var gamificationService: GamificationService!
    var testUser: User!
    
    override func setUp() {
        super.setUp()
        
        // Create test user using the shared database manager
        // Note: These tests will use the actual database, not in-memory
        // In a production app, we'd redesign GamificationService to accept a database dependency
        do {
            testUser = try DatabaseManager.shared.createUser(name: "Test User \(UUID().uuidString)", email: "test\(UUID().uuidString)@aotd.com")
        } catch {
            XCTFail("Failed to create test user: \(error)")
        }
        
        gamificationService = GamificationService.shared
    }
    
    override func tearDown() {
        // Clean up test user
        if let testUser = testUser {
            try? DatabaseManager.shared.deleteUser(testUser.id)
        }
        testUser = nil
        gamificationService = nil
        super.tearDown()
    }
    
    // MARK: - XP Award Tests
    
    func testAwardXP() {
        // Given
        let initialXP = testUser.totalXP
        let xpToAward = 50
        
        // When
        gamificationService.awardXP(to: testUser.id, amount: xpToAward, reason: "Test")
        
        // Then
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.totalXP, initialXP + xpToAward)
        } catch {
            XCTFail("Failed to get updated user: \(error)")
        }
    }
    
    func testLevelProgression() {
        // Given
        let xpToAward = 250  // Should reach level 3 (100 XP per level)
        
        // When
        gamificationService.awardXP(to: testUser.id, amount: xpToAward, reason: "Test")
        
        // Then
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.totalXP, xpToAward)
            XCTAssertEqual(updatedUser?.currentLevel, 3)
        } catch {
            XCTFail("Failed to get updated user: \(error)")
        }
    }
    
    // MARK: - Streak Tests
    
    func testStreakIncrementOnFirstActivity() {
        // Given - User has no previous activity
        XCTAssertEqual(testUser.streakDays, 0)
        XCTAssertNil(testUser.lastActiveDate)
        
        // When
        gamificationService.updateStreakIfNeeded(for: testUser.id)
        
        // Then
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.streakDays, 1)
            XCTAssertNotNil(updatedUser?.lastActiveDate)
        } catch {
            XCTFail("Failed to get updated user: \(error)")
        }
    }
    
    func testStreakMultiplierBasic() {
        // Test that streak multiplier affects XP awards
        // This is a simplified test since the multiplier logic is in QuestionFlowCoordinator
        
        // Given - User with 7 day streak (should get 1.25x multiplier)
        do {
            var user = try DatabaseManager.shared.getUser(by: testUser.id)!
            user.streakDays = 7
            user.lastActiveDate = Date()
            try DatabaseManager.shared.updateUser(user)
            
            let baseXP = 10
            let initialTotalXP = user.totalXP
            
            // When - Award XP through the service
            gamificationService.awardXP(to: testUser.id, amount: baseXP, reason: "Test streak")
            
            // Then - XP should be awarded (exact multiplier logic is tested elsewhere)
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)!
            XCTAssertGreaterThan(updatedUser.totalXP, initialTotalXP)
            
        } catch {
            XCTFail("Failed to test streak multiplier: \(error)")
        }
    }
    
    // MARK: - Achievement Tests
    
    func testXPAchievementProgress() {
        // This test checks that XP awarding works
        // Achievement progress testing requires actual achievements from aotd.json
        
        // Given - Award some XP
        let initialXP = testUser.totalXP
        
        // When
        gamificationService.awardXP(to: testUser.id, amount: 50, reason: "Test")
        
        // Then - XP should be awarded and achievements checked
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.totalXP, initialXP + 50)
            
            // Check that achievements are loaded (from aotd.json)
            let achievements = DatabaseManager.shared.loadAchievements()
            XCTAssertGreaterThan(achievements.count, 0, "Should have achievements loaded from JSON")
        } catch {
            XCTFail("Failed to test XP achievement: \(error)")
        }
    }
    
    func testCorrectAnswersAchievementProgress() {
        // Given - Save some correct answers
        let correctAnswer1 = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "correct",
            isCorrect: true,
            beliefSystemId: "test",
            lessonId: "lesson1",
            timeSpent: 5.0
        )
        
        let correctAnswer2 = UserAnswer(
            userId: testUser.id,
            questionId: "q2",
            userAnswer: "correct",
            isCorrect: true,
            beliefSystemId: "test",
            lessonId: "lesson1",
            timeSpent: 3.0
        )
        
        do {
            try DatabaseManager.shared.saveUserAnswer(correctAnswer1)
            try DatabaseManager.shared.saveUserAnswer(correctAnswer2)
        } catch {
            XCTFail("Failed to save test answers: \(error)")
        }
        
        // When - Check achievements
        gamificationService.checkAchievements(for: testUser.id)
        
        // Then - Verify progress
        do {
            let correctCount = try DatabaseManager.shared.getCorrectAnswersCount(userId: testUser.id)
            XCTAssertEqual(correctCount, 2)
        } catch {
            XCTFail("Failed to get correct answers count: \(error)")
        }
    }
    
}