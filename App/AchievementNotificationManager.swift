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
    
    
    
    func gamificationService(_ service: GamificationService, didUnlockAchievement achievementId: String) {
        let achievements = DatabaseManager.shared.loadAchievements()
        guard let achievement = achievements.first(where: { $0.id == achievementId }) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.notificationQueue.append(achievement)
            self.showNextNotificationIfNeeded()
        }
    }



    private func showNextNotificationIfNeeded() {
        guard !isShowingNotification,
              !notificationQueue.isEmpty,
              let hostView = resolveHostView() else { return }

        let achievement = notificationQueue.removeFirst()
        isShowingNotification = true

        let notificationView = AchievementNotificationView(achievement: achievement)
        notificationView.showAnimated(in: hostView) { [weak self] in
            self?.isShowingNotification = false
            self?.showNextNotificationIfNeeded()
        }
    }

    private func resolveHostView() -> UIView? {
        if let view = currentViewController?.viewIfLoaded, view.window != nil {
            return view
        }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}