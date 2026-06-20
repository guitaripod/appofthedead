import GameKit
import UIKit

final class GameCenterManager: NSObject {

    static let shared = GameCenterManager()

    private let gameKit: GameKitInterface
    private let statsProvider: GameCenterStatsProviding

    private var isObservingUpdates = false
    private var isSyncScheduled = false

    private static let userDataDidUpdateName = Notification.Name("UserDataDidUpdate")

    init(
        gameKit: GameKitInterface = LiveGameKitInterface(),
        statsProvider: GameCenterStatsProviding = DatabaseGameCenterStatsProvider()
    ) {
        self.gameKit = gameKit
        self.statsProvider = statsProvider
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var isAuthenticated: Bool {
        gameKit.isAuthenticated
    }

    func authenticate() {
        gameKit.authenticate { [weak self] event in
            DispatchQueue.main.async {
                self?.handleAuthEvent(event)
            }
        }
    }

    private func handleAuthEvent(_ event: GameCenterAuthEvent) {
        switch event {
        case .requiresPresentation(let viewController):
            AppLogger.gameCenter.info("Presenting Game Center sign-in")
            present(viewController)
        case .authenticated:
            AppLogger.gameCenter.info("Game Center authenticated")
            observeUserDataUpdatesIfNeeded()
            synchronize()
        case .failed(let error):
            if let error {
                AppLogger.logError(error, context: "Game Center authentication", logger: AppLogger.gameCenter)
            } else {
                AppLogger.gameCenter.info("Game Center unavailable; player not signed in")
            }
        }
    }

    func synchronize() {
        guard gameKit.isAuthenticated else {
            AppLogger.gameCenter.debug("Skipping Game Center sync; player not authenticated")
            return
        }
        guard let snapshot = statsProvider.currentSnapshot() else { return }

        for (leaderboard, score) in snapshot.leaderboardScores {
            gameKit.submitScore(score, leaderboardID: leaderboard.id) { error in
                if let error {
                    AppLogger.logError(
                        error,
                        context: "Submitting Game Center score for \(leaderboard.id)",
                        logger: AppLogger.gameCenter
                    )
                }
            }
        }

        let reports = snapshot.achievementReports
        guard !reports.isEmpty else { return }
        gameKit.reportAchievements(reports) { error in
            if let error {
                AppLogger.logError(error, context: "Reporting Game Center achievements", logger: AppLogger.gameCenter)
            }
        }
    }

    private func observeUserDataUpdatesIfNeeded() {
        guard !isObservingUpdates else { return }
        isObservingUpdates = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scheduleSynchronize),
            name: Self.userDataDidUpdateName,
            object: nil
        )
    }

    @objc private func scheduleSynchronize() {
        runOnMain { [weak self] in
            guard let self, !self.isSyncScheduled else { return }
            self.isSyncScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isSyncScheduled = false
                self?.synchronize()
            }
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    func presentDashboard(from presenter: UIViewController) {
        guard gameKit.isAuthenticated else {
            presentUnavailableAlert(from: presenter)
            return
        }
        let dashboard = GKGameCenterViewController(state: .dashboard)
        dashboard.gameCenterDelegate = self
        presenter.present(dashboard, animated: true)
    }

    private func presentUnavailableAlert(from presenter: UIViewController) {
        PapyrusAlert.showSimpleAlert(
            title: "Game Center",
            message: "Sign in to Game Center in the Settings app to climb the leaderboards and earn honors across the realms of the dead.",
            from: presenter
        )
    }

    private func present(_ viewController: UIViewController) {
        guard let top = Self.topViewController() else {
            AppLogger.gameCenter.error("No top view controller to present Game Center sign-in")
            return
        }
        guard top.presentedViewController == nil else { return }
        top.present(viewController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
