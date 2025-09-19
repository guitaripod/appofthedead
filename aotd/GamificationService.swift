import Foundation

protocol GamificationServiceDelegate: AnyObject {
    func gamificationService(_ service: GamificationService, didUnlockAchievement achievementId: String)
}

final class GamificationService {
    
    static let shared = GamificationService()
    
    weak var delegate: GamificationServiceDelegate?
    
    private let databaseManager = DatabaseManager.shared
    private let contentLoader = ContentLoader()
    
    private init() {}
    
    // MARK: - Achievement Checking
    
    func checkAchievements(for userId: String) {
        guard let user = try? databaseManager.getUser(by: userId) else { return }
        
        let achievements = contentLoader.loadAchievements()
        
        for achievement in achievements {
            checkIndividualAchievement(achievement, for: user)
        }
    }
    
    private func checkIndividualAchievement(_ achievement: Achievement, for user: User) {
        do {
            let userAchievements = try databaseManager.getUserAchievements(userId: user.id)
            let existingAchievement = userAchievements.first { $0.achievementId == achievement.id }
            
            // Skip if already completed
            if existingAchievement?.isCompleted == true {
                return
            }
            
            let progress = calculateAchievementProgress(achievement, for: user)
            
            // Update or create achievement progress
            if progress > (existingAchievement?.progress ?? 0) {
                try databaseManager.unlockAchievement(
                    userId: user.id,
                    achievementId: achievement.id,
                    progress: progress
                )
                
                // Notify if newly completed
                if progress >= 1.0 && existingAchievement?.isCompleted != true {
                    delegate?.gamificationService(self, didUnlockAchievement: achievement.id)
                }
            }
            
        } catch {
            AppLogger.logError(error, context: "Checking achievement \(achievement.id)", logger: AppLogger.gamification)
        }
    }
    
    private func calculateAchievementProgress(_ achievement: Achievement, for user: User) -> Double {
        switch achievement.criteria.type {
        case .totalXP:
            guard case .int(let targetXP) = achievement.criteria.value else { return 0.0 }
            return min(1.0, Double(user.totalXP) / Double(targetXP))
            
        case .correctQuestions:
            guard case .int(let targetCount) = achievement.criteria.value else { return 0.0 }
            do {
                let correctCount = try databaseManager.getCorrectAnswersCount(userId: user.id)
                return min(1.0, Double(correctCount) / Double(targetCount))
            } catch {
                return 0.0
            }
            
        case .completePath:
            return calculatePathCompletionProgress(achievement, for: user)
            
        case .completeMultiplePaths, .completeAllPaths:
            return calculateMultiplePathProgress(achievement, for: user)
            
        case .perfectMasteryTest:
            return calculatePerfectMasteryProgress(achievement, for: user)
            
        case .completeLesson:
            return calculateLessonCompletionProgress(achievement, for: user)
        }
    }
    
    private func calculatePathCompletionProgress(_ achievement: Achievement, for user: User) -> Double {
        // Check if specific belief system is completed
        guard case .string(let beliefSystemId) = achievement.criteria.value,
              let beliefSystem = databaseManager.getBeliefSystem(by: beliefSystemId) else {
            return 0.0
        }
        
        do {
            let progress = try databaseManager.getProgress(userId: user.id, beliefSystemId: beliefSystemId)
            let currentXP = progress?.currentXP ?? 0
            return min(1.0, Double(currentXP) / Double(beliefSystem.totalXP))
        } catch {
            return 0.0
        }
    }
    
    private func calculateMultiplePathProgress(_ achievement: Achievement, for user: User) -> Double {
        let beliefSystems = databaseManager.loadBeliefSystems()
        var completedPaths = 0
        
        for beliefSystem in beliefSystems {
            do {
                let progress = try databaseManager.getProgress(userId: user.id, beliefSystemId: beliefSystem.id)
                let currentXP = progress?.currentXP ?? 0
                if currentXP >= beliefSystem.totalXP {
                    completedPaths += 1
                }
            } catch {
                continue
            }
        }
        
        // For "completeAllPaths", check against total count
        if achievement.criteria.type == .completeAllPaths {
            return min(1.0, Double(completedPaths) / Double(beliefSystems.count))
        }
        
        // For "completeMultiplePaths", check against specified target
        guard case .int(let targetPaths) = achievement.criteria.value else { return 0.0 }
        return min(1.0, Double(completedPaths) / Double(targetPaths))
    }
    
    private func calculatePerfectMasteryProgress(_ achievement: Achievement, for user: User) -> Double {
        // This would require tracking mastery test scores
        // For now, return 0.0 as this feature isn't fully implemented
        return 0.0
    }
    
    private func calculateLessonCompletionProgress(_ achievement: Achievement, for user: User) -> Double {
        // Count completed lessons across all belief systems
        guard case .int(let targetLessons) = achievement.criteria.value else { return 0.0 }
        
        do {
            let allProgress = try databaseManager.getUserProgress(userId: user.id)
            let completedLessons = allProgress.filter { $0.status == .completed && $0.lessonId != nil }
            return min(1.0, Double(completedLessons.count) / Double(targetLessons))
        } catch {
            return 0.0
        }
    }
    
    // MARK: - Streak Management
    
    func updateStreakIfNeeded(for userId: String) {
        guard var user = try? databaseManager.getUser(by: userId) else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        if let lastActiveDate = user.lastActiveDate {
            let daysBetween = calendar.dateComponents([.day], from: lastActiveDate, to: today).day ?? 0
            
            switch daysBetween {
            case 0:
                // Same day, no change
                break
            case 1:
                // Consecutive day, increment streak
                user.streakDays += 1
                user.lastActiveDate = today
            default:
                // Missed day(s), reset streak
                user.streakDays = 1
                user.lastActiveDate = today
            }
        } else {
            // First time user
            user.streakDays = 1
            user.lastActiveDate = today
        }
        
        do {
            try databaseManager.updateUser(user)
        } catch {
            AppLogger.logError(error, context: "Updating user streak", logger: AppLogger.gamification)
        }
    }
    
    // MARK: - XP Award with Achievement Check
    
    func awardXP(to userId: String, amount: Int, reason: String, beliefSystemId: String? = nil) {
        do {
            // Update streak first
            updateStreakIfNeeded(for: userId)

            // Fetch user and award XP to user total
            guard let user = try databaseManager.getUser(by: userId) else {
                AppLogger.gamification.error("Failed to find user for XP award", metadata: ["userId": userId])
                return
            }
            try databaseManager.addXPToUser(user, xp: amount)
            
            // If belief system is specified, also update belief-system-specific XP
            if let beliefSystemId = beliefSystemId {
                try databaseManager.addXPToProgress(userId: userId, beliefSystemId: beliefSystemId, xp: amount)
            }
            
            // Debug logging
            AppLogger.gamification.info("XP Awarded", metadata: ["amount": amount, "userId": userId, "reason": reason])
            if let beliefSystemId = beliefSystemId {
                AppLogger.gamification.debug("XP also awarded to belief system", metadata: ["beliefSystemId": beliefSystemId])
            }
            
            // Check for newly unlocked achievements
            checkAchievements(for: userId)
            
            // Notify UI about data changes
            NotificationCenter.default.post(name: Notification.Name("UserDataDidUpdate"), object: nil)
            
        } catch {
            AppLogger.logError(error, context: "Awarding XP for \(reason)", logger: AppLogger.gamification)
        }
    }
}