import XCTest
@testable import aotd

final class GameCenterSnapshotTests: XCTestCase {

    private func achievement(_ id: String, progress: Double) -> UserAchievement {
        UserAchievement(userId: "user", achievementId: id, progress: progress)
    }

    func testLeaderboardScoresMapDirectly() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: 1234,
            currentStreak: 9,
            pathsMastered: 3,
            pathsCompleted: 7,
            correctAnswers: 88,
            achievements: []
        )

        XCTAssertEqual(snapshot.leaderboardScores[.totalXP], 1234)
        XCTAssertEqual(snapshot.leaderboardScores[.currentStreak], 9)
        XCTAssertEqual(snapshot.leaderboardScores[.pathsMastered], 3)
        XCTAssertEqual(snapshot.leaderboardScores[.pathsCompleted], 7)
        XCTAssertEqual(snapshot.leaderboardScores[.correctAnswers], 88)
        XCTAssertEqual(snapshot.leaderboardScores.count, GameCenterLeaderboard.allCases.count)
    }

    func testNegativeValuesAreClampedToZero() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: -5,
            currentStreak: -1,
            pathsMastered: -2,
            pathsCompleted: -3,
            correctAnswers: -4,
            achievements: []
        )

        for leaderboard in GameCenterLeaderboard.allCases {
            XCTAssertEqual(snapshot.leaderboardScores[leaderboard], 0)
        }
    }

    func testAchievementPercentagesConvertProgress() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: 0,
            currentStreak: 0,
            pathsMastered: 0,
            pathsCompleted: 0,
            correctAnswers: 0,
            achievements: [
                achievement("first_step", progress: 1.0),
                achievement("wisdom_seeker", progress: 0.5),
                achievement("quiz_whiz", progress: 0.25)
            ]
        )

        XCTAssertEqual(snapshot.achievementPercentages["first_step"], 100)
        XCTAssertEqual(snapshot.achievementPercentages["wisdom_seeker"], 50)
        XCTAssertEqual(snapshot.achievementPercentages["quiz_whiz"], 25)
    }

    func testZeroProgressAchievementsAreExcluded() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: 0,
            currentStreak: 0,
            pathsMastered: 0,
            pathsCompleted: 0,
            correctAnswers: 0,
            achievements: [achievement("first_step", progress: 0.0)]
        )

        XCTAssertTrue(snapshot.achievementPercentages.isEmpty)
    }

    func testProgressIsClampedToOneHundred() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: 0,
            currentStreak: 0,
            pathsMastered: 0,
            pathsCompleted: 0,
            correctAnswers: 0,
            achievements: [achievement("first_step", progress: 1.8)]
        )

        XCTAssertEqual(snapshot.achievementPercentages["first_step"], 100)
    }

    func testDuplicateAchievementIdsKeepHighestProgress() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: 0,
            currentStreak: 0,
            pathsMastered: 0,
            pathsCompleted: 0,
            correctAnswers: 0,
            achievements: [
                achievement("first_step", progress: 0.3),
                achievement("first_step", progress: 0.9)
            ]
        )

        XCTAssertEqual(snapshot.achievementPercentages["first_step"], 90)
    }

    func testAchievementReportsAreStableSortedById() {
        let snapshot = GameCenterSnapshot.make(
            totalXP: 0,
            currentStreak: 0,
            pathsMastered: 0,
            pathsCompleted: 0,
            correctAnswers: 0,
            achievements: [
                achievement("zeta", progress: 0.1),
                achievement("alpha", progress: 0.2)
            ]
        )

        XCTAssertEqual(snapshot.achievementReports.map { $0.id }, ["alpha", "zeta"])
    }

    func testLeaderboardIdsAreUniqueAndNamespaced() {
        let ids = GameCenterLeaderboard.allCases.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count)
        for id in ids {
            XCTAssertTrue(id.hasPrefix("com.marcusziade.aotd.leaderboard."))
        }
    }
}
