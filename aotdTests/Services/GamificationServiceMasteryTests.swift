import XCTest
@testable import aotd

final class GamificationServiceMasteryTests: XCTestCase {

    private var testUser: User!

    override func setUp() {
        super.setUp()
        do {
            testUser = try DatabaseManager.shared.createAnonymousUser()
        } catch {
            XCTFail("Failed to create test user: \(error)")
        }
    }

    override func tearDown() {
        if let testUser = testUser {
            try? DatabaseManager.shared.deleteUser(testUser.id)
        }
        testUser = nil
        super.tearDown()
    }

    func testPerfectMasteryUnlocksPerfectUnderstanding() throws {
        try DatabaseManager.shared.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: nil,
            status: .mastered,
            score: 100
        )

        GamificationService.shared.checkAchievements(for: testUser.id)

        let userAchievements = try DatabaseManager.shared.getUserAchievements(userId: testUser.id)
        let perfectUnderstanding = userAchievements.first { $0.achievementId == "perfect_understanding" }
        XCTAssertNotNil(perfectUnderstanding)
        XCTAssertTrue(perfectUnderstanding?.isCompleted ?? false)
    }

    func testImperfectMasteryDoesNotUnlockPerfectUnderstanding() throws {
        try DatabaseManager.shared.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: nil,
            status: .mastered,
            score: 90
        )

        GamificationService.shared.checkAchievements(for: testUser.id)

        let userAchievements = try DatabaseManager.shared.getUserAchievements(userId: testUser.id)
        let perfectUnderstanding = userAchievements.first { $0.achievementId == "perfect_understanding" }
        XCTAssertNotEqual(perfectUnderstanding?.isCompleted, true)
    }

    func testMasteredPathIsNeverDowngradedByCompletedWrite() throws {
        try DatabaseManager.shared.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: nil,
            status: .mastered,
            score: 100
        )

        try DatabaseManager.shared.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: nil,
            status: .completed,
            score: nil
        )

        let progress = try DatabaseManager.shared.getProgress(userId: testUser.id, beliefSystemId: "judaism")
        XCTAssertEqual(progress?.status, .mastered)
        XCTAssertEqual(progress?.score, 100)
    }

    func testCompletedStatusCountsTowardPathAchievements() throws {
        try DatabaseManager.shared.createOrUpdateProgress(
            userId: testUser.id,
            beliefSystemId: "judaism",
            lessonId: nil,
            status: .completed,
            score: nil
        )

        GamificationService.shared.checkAchievements(for: testUser.id)

        let userAchievements = try DatabaseManager.shared.getUserAchievements(userId: testUser.id)
        let scholarOfSheol = userAchievements.first { $0.achievementId == "scholar_of_sheol" }
        XCTAssertNotNil(scholarOfSheol)
        XCTAssertTrue(scholarOfSheol?.isCompleted ?? false)
    }

    func testStreakIncrementsAcrossCalendarDayBoundary() throws {
        var user = try XCTUnwrap(try DatabaseManager.shared.getUser(by: testUser.id))
        let calendar = Calendar.current
        let lateLastNight = calendar.date(
            byAdding: .minute,
            value: 30,
            to: calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date())!)
        )!
        user.streakDays = 3
        user.lastActiveDate = lateLastNight
        try DatabaseManager.shared.updateUser(user)

        GamificationService.shared.updateStreakIfNeeded(for: testUser.id)

        let updated = try XCTUnwrap(try DatabaseManager.shared.getUser(by: testUser.id))
        XCTAssertEqual(updated.streakDays, 4)
    }

    func testStreakResetsAfterMissedCalendarDay() throws {
        var user = try XCTUnwrap(try DatabaseManager.shared.getUser(by: testUser.id))
        let calendar = Calendar.current
        user.streakDays = 5
        user.lastActiveDate = calendar.date(byAdding: .day, value: -3, to: Date())
        try DatabaseManager.shared.updateUser(user)

        GamificationService.shared.updateStreakIfNeeded(for: testUser.id)

        let updated = try XCTUnwrap(try DatabaseManager.shared.getUser(by: testUser.id))
        XCTAssertEqual(updated.streakDays, 1)
    }

    func testStreakUnchangedWithinSameDay() throws {
        var user = try XCTUnwrap(try DatabaseManager.shared.getUser(by: testUser.id))
        user.streakDays = 2
        user.lastActiveDate = Date()
        try DatabaseManager.shared.updateUser(user)

        GamificationService.shared.updateStreakIfNeeded(for: testUser.id)

        let updated = try XCTUnwrap(try DatabaseManager.shared.getUser(by: testUser.id))
        XCTAssertEqual(updated.streakDays, 2)
    }
}
