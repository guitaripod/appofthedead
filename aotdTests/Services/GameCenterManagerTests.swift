import XCTest
@testable import aotd

private final class MockGameKitInterface: GameKitInterface {
    var isAuthenticated: Bool
    private(set) var submittedScores: [(score: Int, leaderboardID: String)] = []
    private(set) var reportedAchievements: [[GameCenterAchievementReport]] = []

    init(isAuthenticated: Bool) {
        self.isAuthenticated = isAuthenticated
    }

    func authenticate(_ handler: @escaping (GameCenterAuthEvent) -> Void) {
        handler(isAuthenticated ? .authenticated : .failed(nil))
    }

    func submitScore(_ score: Int, leaderboardID: String, completion: @escaping (Error?) -> Void) {
        submittedScores.append((score, leaderboardID))
        completion(nil)
    }

    func reportAchievements(_ reports: [GameCenterAchievementReport], completion: @escaping (Error?) -> Void) {
        reportedAchievements.append(reports)
        completion(nil)
    }
}

private struct StubStatsProvider: GameCenterStatsProviding {
    let snapshot: GameCenterSnapshot?
    func currentSnapshot() -> GameCenterSnapshot? { snapshot }
}

final class GameCenterManagerTests: XCTestCase {

    private func sampleSnapshot() -> GameCenterSnapshot {
        GameCenterSnapshot.make(
            totalXP: 500,
            currentStreak: 4,
            pathsMastered: 2,
            pathsCompleted: 5,
            correctAnswers: 30,
            achievements: [
                UserAchievement(userId: "u", achievementId: "first_step", progress: 1.0),
                UserAchievement(userId: "u", achievementId: "wisdom_seeker", progress: 0.5)
            ]
        )
    }

    func testSynchronizeSubmitsAllLeaderboardsWhenAuthenticated() {
        let gameKit = MockGameKitInterface(isAuthenticated: true)
        let manager = GameCenterManager(gameKit: gameKit, statsProvider: StubStatsProvider(snapshot: sampleSnapshot()))

        manager.synchronize()

        XCTAssertEqual(gameKit.submittedScores.count, GameCenterLeaderboard.allCases.count)
        let byLeaderboard = Dictionary(uniqueKeysWithValues: gameKit.submittedScores.map { ($0.leaderboardID, $0.score) })
        XCTAssertEqual(byLeaderboard[GameCenterLeaderboard.totalXP.id], 500)
        XCTAssertEqual(byLeaderboard[GameCenterLeaderboard.currentStreak.id], 4)
        XCTAssertEqual(byLeaderboard[GameCenterLeaderboard.pathsMastered.id], 2)
        XCTAssertEqual(byLeaderboard[GameCenterLeaderboard.pathsCompleted.id], 5)
        XCTAssertEqual(byLeaderboard[GameCenterLeaderboard.correctAnswers.id], 30)
    }

    func testSynchronizeReportsAchievements() {
        let gameKit = MockGameKitInterface(isAuthenticated: true)
        let manager = GameCenterManager(gameKit: gameKit, statsProvider: StubStatsProvider(snapshot: sampleSnapshot()))

        manager.synchronize()

        XCTAssertEqual(gameKit.reportedAchievements.count, 1)
        let reports = gameKit.reportedAchievements.first ?? []
        let byId = Dictionary(uniqueKeysWithValues: reports.map { ($0.id, $0.percentComplete) })
        XCTAssertEqual(byId["first_step"], 100)
        XCTAssertEqual(byId["wisdom_seeker"], 50)
    }

    func testSynchronizeDoesNothingWhenUnauthenticated() {
        let gameKit = MockGameKitInterface(isAuthenticated: false)
        let manager = GameCenterManager(gameKit: gameKit, statsProvider: StubStatsProvider(snapshot: sampleSnapshot()))

        manager.synchronize()

        XCTAssertTrue(gameKit.submittedScores.isEmpty)
        XCTAssertTrue(gameKit.reportedAchievements.isEmpty)
    }

    func testSynchronizeDoesNothingWithNilSnapshot() {
        let gameKit = MockGameKitInterface(isAuthenticated: true)
        let manager = GameCenterManager(gameKit: gameKit, statsProvider: StubStatsProvider(snapshot: nil))

        manager.synchronize()

        XCTAssertTrue(gameKit.submittedScores.isEmpty)
        XCTAssertTrue(gameKit.reportedAchievements.isEmpty)
    }

    func testSynchronizeSkipsAchievementReportWhenNoneInProgress() {
        let emptyAchievementsSnapshot = GameCenterSnapshot.make(
            totalXP: 10,
            currentStreak: 0,
            pathsMastered: 0,
            pathsCompleted: 0,
            correctAnswers: 0,
            achievements: []
        )
        let gameKit = MockGameKitInterface(isAuthenticated: true)
        let manager = GameCenterManager(gameKit: gameKit, statsProvider: StubStatsProvider(snapshot: emptyAchievementsSnapshot))

        manager.synchronize()

        XCTAssertEqual(gameKit.submittedScores.count, GameCenterLeaderboard.allCases.count)
        XCTAssertTrue(gameKit.reportedAchievements.isEmpty)
    }
}
