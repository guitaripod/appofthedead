import Foundation

struct DatabaseGameCenterStatsProvider: GameCenterStatsProviding {

    private let databaseManager: DatabaseManager

    init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
    }

    func currentSnapshot() -> GameCenterSnapshot? {
        guard let user = databaseManager.fetchUser() else { return nil }

        do {
            let correctAnswers = try databaseManager.getCorrectAnswersCount(userId: user.id)
            let achievements = try databaseManager.getUserAchievements(userId: user.id)

            let pathProgress = try databaseManager.getUserProgress(userId: user.id).filter {
                $0.lessonId == nil && $0.questionId == nil && $0.status != .notStarted
            }
            let pathsMastered = pathProgress.filter { $0.status == .mastered }.count
            let pathsCompleted = pathProgress.filter { $0.status == .completed || $0.status == .mastered }.count

            return GameCenterSnapshot.make(
                totalXP: user.totalXP,
                currentStreak: user.streakDays,
                pathsMastered: pathsMastered,
                pathsCompleted: pathsCompleted,
                correctAnswers: correctAnswers,
                achievements: achievements
            )
        } catch {
            AppLogger.logError(error, context: "Building Game Center snapshot", logger: AppLogger.gameCenter)
            return nil
        }
    }
}
