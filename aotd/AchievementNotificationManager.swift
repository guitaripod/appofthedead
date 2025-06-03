import UIKit

final class AchievementNotificationManager: GamificationServiceDelegate {
    
    static let shared = AchievementNotificationManager()
    
    private weak var currentViewController: UIViewController?
    private var notificationQueue: [Achievement] = []
    private var isShowingNotification = false
    
    private init() {
        GamificationService.shared.delegate = self
    }
    
    func setCurrentViewController(_ viewController: UIViewController) {
        currentViewController = viewController
    }
    
    // MARK: - GamificationServiceDelegate
    
    func gamificationService(_ service: GamificationService, didUnlockAchievement achievementId: String) {
        let achievements = DatabaseManager.shared.loadAchievements()
        guard let achievement = achievements.first(where: { $0.id == achievementId }) else { return }
        
        notificationQueue.append(achievement)
        showNextNotificationIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func showNextNotificationIfNeeded() {
        guard !isShowingNotification,
              !notificationQueue.isEmpty,
              let viewController = currentViewController else { return }
        
        let achievement = notificationQueue.removeFirst()
        isShowingNotification = true
        
        let notificationView = AchievementNotificationView(achievement: achievement)
        notificationView.showAnimated(in: viewController.view) { [weak self] in
            self?.isShowingNotification = false
            self?.showNextNotificationIfNeeded()
        }
    }
}