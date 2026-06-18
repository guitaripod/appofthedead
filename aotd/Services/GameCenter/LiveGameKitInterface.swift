import GameKit
import UIKit

final class LiveGameKitInterface: GameKitInterface {

    var isAuthenticated: Bool {
        GKLocalPlayer.local.isAuthenticated
    }

    func authenticate(_ handler: @escaping (GameCenterAuthEvent) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController {
                handler(.requiresPresentation(viewController))
                return
            }
            if GKLocalPlayer.local.isAuthenticated {
                handler(.authenticated)
                return
            }
            handler(.failed(error))
        }
    }

    func submitScore(_ score: Int, leaderboardID: String, completion: @escaping (Error?) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else {
            Self.onMain { completion(GameKitUnavailableError.notAuthenticated) }
            return
        }
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            Self.onMain { completion(error) }
        }
    }

    func reportAchievements(_ reports: [GameCenterAchievementReport], completion: @escaping (Error?) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else {
            Self.onMain { completion(GameKitUnavailableError.notAuthenticated) }
            return
        }
        guard !reports.isEmpty else {
            Self.onMain { completion(nil) }
            return
        }
        let achievements = reports.map { report -> GKAchievement in
            let achievement = GKAchievement(identifier: report.id)
            achievement.percentComplete = report.percentComplete
            achievement.showsCompletionBanner = false
            return achievement
        }
        GKAchievement.report(achievements) { error in
            Self.onMain { completion(error) }
        }
    }

    private static func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

enum GameKitUnavailableError: Error {
    case notAuthenticated
}
