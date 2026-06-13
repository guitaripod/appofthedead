import XCTest
@testable import aotd

final class ProfileViewModelJourneyTests: XCTestCase {

    private var viewModel: ProfileViewModel!
    private var databaseManager: DatabaseManager!
    private var testUser: User!

    private static let displayNameKey = "profileDisplayName"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: Self.displayNameKey)

        databaseManager = DatabaseManager(inMemory: true)
        databaseManager.setContentLoader(ContentLoader())

        do {
            testUser = try databaseManager.createAnonymousUser()
        } catch {
            XCTFail("Failed to create test user: \(error)")
        }

        viewModel = ProfileViewModel(databaseManager: databaseManager)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Self.displayNameKey)
        viewModel = nil
        databaseManager = nil
        testUser = nil
        super.tearDown()
    }

    private func reload() {
        viewModel.loadData()
    }

    private func setTotalXP(_ total: Int) {
        guard let user = databaseManager.fetchUser() else { return XCTFail("No user") }
        try? databaseManager.addXPToUser(user, xp: total - user.totalXP)
    }

    private func setStreak(_ days: Int) {
        guard var user = databaseManager.fetchUser() else { return XCTFail("No user") }
        user.streakDays = days
        try? databaseManager.updateUser(user)
    }

    func testRankTitleBands() {
        reload()
        XCTAssertEqual(viewModel.rankTitle, "First Step")

        setTotalXP(200)
        reload()
        XCTAssertEqual(viewModel.rankTitle, "Seeker")

        setTotalXP(900)
        reload()
        XCTAssertEqual(viewModel.rankTitle, "Cosmic Explorer")

        setTotalXP(4100)
        reload()
        XCTAssertEqual(viewModel.rankTitle, "Approaching The Eternal")
    }

    func testStreakMultiplierTiers() {
        setStreak(0); reload()
        XCTAssertEqual(viewModel.streakMultiplier, 1.0)

        setStreak(3); reload()
        XCTAssertEqual(viewModel.streakMultiplier, 1.1)

        setStreak(7); reload()
        XCTAssertEqual(viewModel.streakMultiplier, 1.25)

        setStreak(14); reload()
        XCTAssertEqual(viewModel.streakMultiplier, 1.5)

        setStreak(30); reload()
        XCTAssertEqual(viewModel.streakMultiplier, 2.0)
    }

    func testAccuracyAndStudyTime() {
        reload()
        XCTAssertNil(viewModel.accuracy, "Accuracy should be nil with no answers")
        XCTAssertEqual(viewModel.totalAnswers, 0)
        XCTAssertEqual(viewModel.totalStudyTime, 0)

        let answers = [
            UserAnswer(userId: testUser.id, questionId: "q1", userAnswer: "a", isCorrect: true, beliefSystemId: "judaism", timeSpent: 10),
            UserAnswer(userId: testUser.id, questionId: "q2", userAnswer: "a", isCorrect: true, beliefSystemId: "judaism", timeSpent: 20),
            UserAnswer(userId: testUser.id, questionId: "q3", userAnswer: "a", isCorrect: true, beliefSystemId: "judaism", timeSpent: 30),
            UserAnswer(userId: testUser.id, questionId: "q4", userAnswer: "a", isCorrect: false, beliefSystemId: "judaism", timeSpent: 40)
        ]
        answers.forEach { try? databaseManager.saveUserAnswer($0) }

        reload()
        XCTAssertEqual(viewModel.totalAnswers, 4)
        XCTAssertEqual(viewModel.totalStudyTime, 100)
        XCTAssertEqual(viewModel.accuracy ?? 0, 0.75, accuracy: 0.0001)
    }

    func testPathJourneyExcludesLessonAndNotStartedRows() {
        try? databaseManager.createOrUpdateProgress(userId: testUser.id, beliefSystemId: "judaism", status: .inProgress)
        try? databaseManager.addXPToProgress(userId: testUser.id, beliefSystemId: "judaism", xp: 350)
        try? databaseManager.createOrUpdateProgress(userId: testUser.id, beliefSystemId: "judaism", lessonId: "judaism-lesson-1", status: .completed)
        try? databaseManager.createOrUpdateProgress(userId: testUser.id, beliefSystemId: "norse", status: .notStarted)

        reload()

        XCTAssertEqual(viewModel.pathJourney.count, 1, "Only started path-level rows should appear")
        let item = viewModel.pathJourney.first
        XCTAssertEqual(item?.id, "judaism")
        XCTAssertEqual(item?.status, .inProgress)
        XCTAssertEqual(item?.earnedXP, 350)
        XCTAssertGreaterThan(item?.totalXP ?? 0, 0)
        XCTAssertLessThanOrEqual(item?.progressFraction ?? 1, 1.0)
    }

    func testMasteredPathsCountCountsOnlyMasteredPathLevelRows() {
        try? databaseManager.createOrUpdateProgress(userId: testUser.id, beliefSystemId: "judaism", status: .mastered)
        try? databaseManager.createOrUpdateProgress(userId: testUser.id, beliefSystemId: "buddhism", status: .completed)
        try? databaseManager.createOrUpdateProgress(userId: testUser.id, beliefSystemId: "norse", lessonId: "norse-lesson-1", status: .mastered)

        reload()

        XCTAssertEqual(viewModel.masteredPathsCount, 1)
        XCTAssertEqual(viewModel.journeySummary.mastered, 1)
        XCTAssertEqual(viewModel.pathJourney.count, 2, "Mastered + completed path-level rows")
        XCTAssertEqual(viewModel.pathJourney.first?.status, .mastered, "Mastered should sort first")
    }

    func testDisplayNameDefaultAndPersistence() {
        reload()
        XCTAssertEqual(viewModel.displayName, ProfileViewModel.defaultDisplayName)

        var didFire = false
        viewModel.onDataUpdate = { didFire = true }
        viewModel.updateDisplayName("  Ra  ")

        XCTAssertTrue(didFire, "updateDisplayName should fire onDataUpdate")
        XCTAssertEqual(viewModel.displayName, "Ra", "Name should be trimmed and persisted")

        let freshViewModel = ProfileViewModel(databaseManager: databaseManager)
        XCTAssertEqual(freshViewModel.displayName, "Ra", "Name should persist across instances")
    }

    func testUpdateDisplayNameIgnoresEmptyInput() {
        viewModel.updateDisplayName("Osiris")
        viewModel.updateDisplayName("   ")
        XCTAssertEqual(viewModel.displayName, "Osiris", "Whitespace-only names are rejected")
    }

    func testSortedUserAchievementsOrdersCompletedThenProgress() {
        reload()
        let ids = viewModel.achievements.map { $0.id }
        guard ids.count >= 3 else { return XCTFail("Need at least 3 achievements") }

        try? databaseManager.unlockAchievement(userId: testUser.id, achievementId: ids[0], progress: 1.0)
        try? databaseManager.unlockAchievement(userId: testUser.id, achievementId: ids[1], progress: 0.5)
        try? databaseManager.unlockAchievement(userId: testUser.id, achievementId: ids[2], progress: 0.8)

        reload()
        let sorted = viewModel.sortedUserAchievements

        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].achievementId, ids[0], "Completed achievement first")
        XCTAssertTrue(sorted[0].isCompleted)
        XCTAssertEqual(sorted[1].achievementId, ids[2], "Higher progress before lower among incomplete")
        XCTAssertEqual(sorted[2].achievementId, ids[1])
    }
}
