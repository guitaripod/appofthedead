import Foundation

final class ProfileViewModel {

    private let databaseManager: DatabaseManager

    var onDataUpdate: (() -> Void)?

    private(set) var user: User?
    private(set) var userStats: UserStatistics?
    private(set) var userAchievements: [UserAchievement] = []
    private(set) var achievements: [Achievement] = []

    private(set) var pathJourney: [PathJourneyItem] = []
    private(set) var totalAnswers: Int = 0
    private(set) var totalStudyTime: TimeInterval = 0
    private(set) var accuracy: Double?
    private(set) var masteredPathsCount: Int = 0
    private(set) var totalBeliefSystems: Int = 0

    private static let displayNameKey = "profileDisplayName"
    static let defaultDisplayName = "Anonymous Seeker"

    init(databaseManager: DatabaseManager = DatabaseManager.shared) {
        self.databaseManager = databaseManager
    }

    func loadData() {
        loadUser()
        loadUserStats()
        loadAchievements()
        loadUserAchievements()
        loadJourneyMetrics()
        onDataUpdate?()
    }

    var displayName: String {
        UserDefaults.standard.string(forKey: Self.displayNameKey) ?? Self.defaultDisplayName
    }

    func updateDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: Self.displayNameKey)
        onDataUpdate?()
    }

    var rankTitle: String {
        switch user?.currentLevel ?? 1 {
        case ..<2: return "First Step"
        case 2...3: return "Seeker"
        case 4...6: return "Wisdom Seeker"
        case 7...9: return "Eternal Student"
        case 10...14: return "Cosmic Explorer"
        case 15...24: return "Enlightened One"
        case 25...39: return "Afterlife Master"
        default: return "Approaching The Eternal"
        }
    }

    var streakMultiplier: Double {
        switch user?.streakDays ?? 0 {
        case ..<3: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.25
        case 14...29: return 1.5
        default: return 2.0
        }
    }

    var sortedUserAchievements: [UserAchievement] {
        userAchievements.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return lhs.isCompleted && !rhs.isCompleted
            }
            return lhs.progress > rhs.progress
        }
    }

    var journeySummary: (gatesWalked: Int, gatesTotal: Int, mastered: Int) {
        (pathJourney.count, totalBeliefSystems, masteredPathsCount)
    }

    private func loadUser() {
        user = databaseManager.fetchUser()
    }

    private func loadUserStats() {
        guard let userId = user?.id else { return }
        do {
            userStats = try databaseManager.getUserStatistics(userId: userId)
        } catch {
            AppLogger.logError(error, context: "Loading user statistics", logger: AppLogger.viewModel)
        }
    }

    private func loadAchievements() {
        achievements = databaseManager.loadAchievements()
    }

    private func loadUserAchievements() {
        guard let userId = user?.id else { return }
        do {
            userAchievements = try databaseManager.getUserAchievements(userId: userId)
        } catch {
            AppLogger.logError(error, context: "Loading user achievements", logger: AppLogger.viewModel)
        }
    }

    private func loadJourneyMetrics() {
        guard let userId = user?.id else { return }
        do {
            let answers = try databaseManager.getUserAnswers(userId: userId)
            totalAnswers = answers.count
            totalStudyTime = answers.reduce(0) { $0 + $1.timeSpent }
            let correct = answers.filter { $0.isCorrect }.count
            accuracy = answers.isEmpty ? nil : Double(correct) / Double(answers.count)

            let beliefSystems = databaseManager.loadBeliefSystems()
            totalBeliefSystems = beliefSystems.count
            let beliefById = Dictionary(beliefSystems.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

            let pathProgress = try databaseManager.getUserProgress(userId: userId).filter {
                $0.lessonId == nil && $0.questionId == nil && $0.status != .notStarted
            }
            masteredPathsCount = pathProgress.filter { $0.status == .mastered }.count

            pathJourney = pathProgress.compactMap { progress -> PathJourneyItem? in
                guard let system = beliefById[progress.beliefSystemId] else { return nil }
                return PathJourneyItem(
                    id: system.id,
                    name: system.name,
                    iconName: system.icon,
                    colorHex: system.color,
                    status: progress.status,
                    earnedXP: progress.earnedXP,
                    totalXP: system.totalXP,
                    totalAttempts: progress.totalAttempts,
                    completedAt: progress.completedAt
                )
            }.sorted(by: Self.journeyOrder)
        } catch {
            AppLogger.logError(error, context: "Loading profile journey metrics", logger: AppLogger.viewModel)
        }
    }

    private static func journeyOrder(_ lhs: PathJourneyItem, _ rhs: PathJourneyItem) -> Bool {
        let lhsRank = statusRank(lhs.status)
        let rhsRank = statusRank(rhs.status)
        if lhsRank != rhsRank { return lhsRank < rhsRank }
        return lhs.earnedXP > rhs.earnedXP
    }

    private static func statusRank(_ status: Progress.ProgressStatus) -> Int {
        switch status {
        case .mastered: return 0
        case .inProgress: return 1
        case .completed: return 2
        case .notStarted: return 3
        }
    }
}
