import Foundation

struct GameCenterAchievementReport: Equatable {
    let id: String
    let percentComplete: Double
}

struct GameCenterSnapshot: Equatable {
    let leaderboardScores: [GameCenterLeaderboard: Int]
    let achievementPercentages: [String: Double]

    var achievementReports: [GameCenterAchievementReport] {
        achievementPercentages
            .sorted { $0.key < $1.key }
            .map { GameCenterAchievementReport(id: $0.key, percentComplete: $0.value) }
    }

    static func make(
        totalXP: Int,
        currentStreak: Int,
        pathsMastered: Int,
        pathsCompleted: Int,
        correctAnswers: Int,
        achievements: [UserAchievement]
    ) -> GameCenterSnapshot {
        let scores: [GameCenterLeaderboard: Int] = [
            .totalXP: max(0, totalXP),
            .currentStreak: max(0, currentStreak),
            .pathsMastered: max(0, pathsMastered),
            .pathsCompleted: max(0, pathsCompleted),
            .correctAnswers: max(0, correctAnswers)
        ]

        var percentages: [String: Double] = [:]
        for achievement in achievements {
            let percent = (min(1.0, max(0.0, achievement.progress)) * 100).rounded()
            guard percent > 0 else { continue }
            percentages[achievement.achievementId] = max(percentages[achievement.achievementId] ?? 0, percent)
        }

        return GameCenterSnapshot(leaderboardScores: scores, achievementPercentages: percentages)
    }
}
