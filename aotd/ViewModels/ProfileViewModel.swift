import Foundation

final class ProfileViewModel {
    
    private let databaseManager: DatabaseManager
    
    var onDataUpdate: (() -> Void)?
    
    private(set) var user: User?
    private(set) var userStats: UserStatistics?
    private(set) var userAchievements: [UserAchievement] = []
    private(set) var achievements: [Achievement] = []
    
    init(databaseManager: DatabaseManager = DatabaseManager.shared) {
        self.databaseManager = databaseManager
    }
    
    func loadData() {
        loadUser()
        loadUserStats()
        loadAchievements()
        loadUserAchievements()
        onDataUpdate?()
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
}