import XCTest
import GRDB
@testable import aotd

final class DatabaseManagerTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var testUser: User!
    
    override func setUpWithError() throws {
        // Create a test database manager with in-memory database
        databaseManager = DatabaseManager(inMemory: true)
        
        // Create a test user
        testUser = try databaseManager.createUser(name: "Test User", email: "test@example.com")
    }
    
    override func tearDownWithError() throws {
        // Clean up
        testUser = nil
        databaseManager = nil
    }
    
    func testCreateUser() throws {
        let user = try databaseManager.createUser(name: "John Doe", email: "john@example.com")
        
        XCTAssertFalse(user.id.isEmpty)
        XCTAssertEqual(user.name, "John Doe")
        XCTAssertEqual(user.email, "john@example.com")
        XCTAssertEqual(user.totalXP, 0)
        XCTAssertEqual(user.currentLevel, 1)
    }
    
    func testGetUserById() throws {
        let retrievedUser = try databaseManager.getUser(by: testUser.id)
        
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.id, testUser.id)
        XCTAssertEqual(retrievedUser?.name, testUser.name)
        XCTAssertEqual(retrievedUser?.email, testUser.email)
    }
    
    func testGetUserByEmail() throws {
        let retrievedUser = try databaseManager.getUserByEmail(testUser.email)
        
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.id, testUser.id)
        XCTAssertEqual(retrievedUser?.email, testUser.email)
    }
    
    func testUpdateUser() throws {
        var updatedUser = testUser!
        updatedUser.name = "Updated Name"
        updatedUser.addXP(100)
        
        try databaseManager.updateUser(updatedUser)
        
        let retrievedUser = try databaseManager.getUser(by: testUser.id)
        XCTAssertEqual(retrievedUser?.name, "Updated Name")
        XCTAssertEqual(retrievedUser?.totalXP, 100)
        XCTAssertEqual(retrievedUser?.currentLevel, 2)
    }
    
    func testAddXPToUser() throws {
        try databaseManager.addXPToUser(userId: testUser.id, xp: 150)
        
        let retrievedUser = try databaseManager.getUser(by: testUser.id)
        XCTAssertEqual(retrievedUser?.totalXP, 150)
        XCTAssertEqual(retrievedUser?.currentLevel, 2)
    }
    
    func testCreateOrUpdateProgress() throws {
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1",
            status: .inProgress
        )
        
        let progress = try databaseManager.getProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1"
        )
        
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.status, .inProgress)
        XCTAssertEqual(progress?.beliefSystemId, "judaism")
        XCTAssertEqual(progress?.lessonId, "lesson1")
    }
    
    func testUpdateExistingProgress() throws {
        // First create progress
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1",
            status: .inProgress
        )
        
        // Then update it
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1",
            status: .completed,
            score: 85
        )
        
        let progress = try databaseManager.getProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1"
        )
        
        XCTAssertEqual(progress?.status, .completed)
        XCTAssertEqual(progress?.score, 85)
        XCTAssertNotNil(progress?.completedAt)
    }
    
    func testGetUserProgress() throws {
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1",
            status: .completed
        )
        
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "christianity",
            lessonId: "lesson1",
            status: .inProgress
        )
        
        let userProgress = try databaseManager.getUserProgress(userId: testUser.id)
        XCTAssertEqual(userProgress.count, 2)
    }
    
    func testSaveUserAnswer() throws {
        let userAnswer = UserAnswer(
            userId: testUser.id,
            questionId: "q1",
            userAnswer: "A",
            isCorrect: true,
            beliefSystemId: "judaism",
            lessonId: "lesson1"
        )
        
        try databaseManager.saveUserAnswer(userAnswer)
        
        let answers = try databaseManager.getUserAnswers(userId: testUser.id, questionId: "q1")
        XCTAssertEqual(answers.count, 1)
        XCTAssertEqual(answers.first?.userAnswer, "A")
        XCTAssertTrue(answers.first?.isCorrect ?? false)
    }
    
    func testGetCorrectAnswersCount() throws {
        let answer1 = UserAnswer(userId: testUser.id, questionId: "q1", userAnswer: "A", isCorrect: true, beliefSystemId: "judaism")
        let answer2 = UserAnswer(userId: testUser.id, questionId: "q2", userAnswer: "B", isCorrect: false, beliefSystemId: "judaism")
        let answer3 = UserAnswer(userId: testUser.id, questionId: "q3", userAnswer: "C", isCorrect: true, beliefSystemId: "judaism")
        
        try databaseManager.saveUserAnswer(answer1)
        try databaseManager.saveUserAnswer(answer2)
        try databaseManager.saveUserAnswer(answer3)
        
        let correctCount = try databaseManager.getCorrectAnswersCount(userId: testUser.id)
        XCTAssertEqual(correctCount, 2)
    }
    
    func testUnlockAchievement() throws {
        try databaseManager.unlockAchievement(userId: testUser.id, achievementId: "first_step", progress: 1.0)
        
        let achievements = try databaseManager.getUserAchievements(userId: testUser.id)
        XCTAssertEqual(achievements.count, 1)
        XCTAssertEqual(achievements.first?.achievementId, "first_step")
        XCTAssertTrue(achievements.first?.isCompleted ?? false)
    }
    
    func testUpdateAchievementProgress() throws {
        try databaseManager.unlockAchievement(userId: testUser.id, achievementId: "quiz_whiz", progress: 0.5)
        
        try databaseManager.updateAchievementProgress(userId: testUser.id, achievementId: "quiz_whiz", progress: 0.8)
        
        let achievements = try databaseManager.getUserAchievements(userId: testUser.id)
        let quizWhizAchievement = achievements.first { $0.achievementId == "quiz_whiz" }
        
        XCTAssertNotNil(quizWhizAchievement)
        XCTAssertEqual(quizWhizAchievement?.progress, 0.8)
        XCTAssertFalse(quizWhizAchievement?.isCompleted ?? true)
    }
    
    func testLoadBeliefSystems() throws {
        let beliefSystems = databaseManager.loadBeliefSystems()
        XCTAssertGreaterThan(beliefSystems.count, 0)
        
        // Check if we can find Judaism
        let judaism = beliefSystems.first { $0.id == "judaism" }
        XCTAssertNotNil(judaism)
        XCTAssertEqual(judaism?.name, "Judaism")
    }
    
    func testLoadAchievements() throws {
        let achievements = databaseManager.loadAchievements()
        XCTAssertGreaterThan(achievements.count, 0)
        
        // Check if we can find first_step achievement
        let firstStep = achievements.first { $0.id == "first_step" }
        XCTAssertNotNil(firstStep)
        XCTAssertEqual(firstStep?.name, "First Step")
    }
    
    func testGetBeliefSystemById() throws {
        let judaism = databaseManager.getBeliefSystem(by: "judaism")
        XCTAssertNotNil(judaism)
        XCTAssertEqual(judaism?.name, "Judaism")
        XCTAssertGreaterThan(judaism?.lessons.count ?? 0, 0)
    }
    
    func testGetUserStatistics() throws {
        // Add some test data
        try databaseManager.addXPToUser(userId: testUser.id, xp: 250)
        
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: "lesson1",
            status: .completed
        )
        
        let answer = UserAnswer(userId: testUser.id, questionId: "q1", userAnswer: "A", isCorrect: true, beliefSystemId: "judaism")
        try databaseManager.saveUserAnswer(answer)
        
        try databaseManager.unlockAchievement(userId: testUser.id, achievementId: "first_step", progress: 1.0)
        
        let stats = try databaseManager.getUserStatistics(userId: testUser.id)
        
        XCTAssertEqual(stats.totalXP, 250)
        XCTAssertEqual(stats.currentLevel, 3)
        XCTAssertEqual(stats.totalLessonsStarted, 1)
        XCTAssertEqual(stats.totalLessonsCompleted, 1)
        XCTAssertEqual(stats.totalAchievements, 1)
        XCTAssertEqual(stats.correctAnswers, 1)
    }
    
    func testProgressWithoutLesson() throws {
        try databaseManager.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            status: .inProgress
        )
        
        let progress = try databaseManager.getProgress(
            userId: testUser.id,
            beliefSystemId: "judaism"
        )
        
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.status, .inProgress)
        XCTAssertNil(progress?.lessonId)
    }
}