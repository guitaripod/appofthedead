import XCTest
@testable import aotd

final class GamificationServiceTests: XCTestCase {
    
    var gamificationService: GamificationService!
    var testUser: User!
    
    override func setUp() {
        super.setUp()
        
        
        
        
        do {
            testUser = try DatabaseManager.shared.createUser(name: "Test User \(UUID().uuidString)", email: "test\(UUID().uuidString)@aotd.com")
        } catch {
            XCTFail("Failed to create test user: \(error)")
        }
        
        gamificationService = GamificationService.shared
    }
    
    override func tearDown() {
        
        if let testUser = testUser {
            try? DatabaseManager.shared.deleteUser(testUser.id)
        }
        testUser = nil
        gamificationService = nil
        super.tearDown()
    }
    
    
    
    func testAwardXP() {
        
        let initialXP = testUser.totalXP
        let xpToAward = 50
        
        
        gamificationService.awardXP(to: testUser.id, amount: xpToAward, reason: "Test")
        
        
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.totalXP, initialXP + xpToAward)
        } catch {
            XCTFail("Failed to get updated user: \(error)")
        }
    }
    
    func testLevelProgression() {
        
        let xpToAward = 250  
        
        
        gamificationService.awardXP(to: testUser.id, amount: xpToAward, reason: "Test")
        
        
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.totalXP, xpToAward)
            XCTAssertEqual(updatedUser?.currentLevel, 3)
        } catch {
            XCTFail("Failed to get updated user: \(error)")
        }
    }
    
    
    
    func testStreakIncrementOnFirstActivity() {
        
        XCTAssertEqual(testUser.streakDays, 0)
        XCTAssertNil(testUser.lastActiveDate)
        
        
        gamificationService.updateStreakIfNeeded(for: testUser.id)
        
        
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
        
        
        
        
        do {
            var user = try DatabaseManager.shared.getUser(by: testUser.id)!
            user.streakDays = 7
            user.lastActiveDate = Date()
            try DatabaseManager.shared.updateUser(user)
            
            let baseXP = 10
            let initialTotalXP = user.totalXP
            
            
            gamificationService.awardXP(to: testUser.id, amount: baseXP, reason: "Test streak")
            
            
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)!
            XCTAssertGreaterThan(updatedUser.totalXP, initialTotalXP)
            
        } catch {
            XCTFail("Failed to test streak multiplier: \(error)")
        }
    }
    
    
    
    func testXPAchievementProgress() {
        
        
        
        
        let initialXP = testUser.totalXP
        
        
        gamificationService.awardXP(to: testUser.id, amount: 50, reason: "Test")
        
        
        do {
            let updatedUser = try DatabaseManager.shared.getUser(by: testUser.id)
            XCTAssertNotNil(updatedUser)
            XCTAssertEqual(updatedUser?.totalXP, initialXP + 50)
            
            
            let achievements = DatabaseManager.shared.loadAchievements()
            XCTAssertGreaterThan(achievements.count, 0, "Should have achievements loaded from JSON")
        } catch {
            XCTFail("Failed to test XP achievement: \(error)")
        }
    }
    
    func testCorrectAnswersAchievementProgress() {
        
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
        
        
        gamificationService.checkAchievements(for: testUser.id)
        
        
        do {
            let correctCount = try DatabaseManager.shared.getCorrectAnswersCount(userId: testUser.id)
            XCTAssertEqual(correctCount, 2)
        } catch {
            XCTFail("Failed to get correct answers count: \(error)")
        }
    }
    
}