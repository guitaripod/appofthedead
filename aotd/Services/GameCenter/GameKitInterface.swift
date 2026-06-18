import UIKit

enum GameCenterAuthEvent {
    case authenticated
    case requiresPresentation(UIViewController)
    case failed(Error?)
}

/// Abstraction over the GameKit calls used by `GameCenterManager`, so submission logic
/// can be unit-tested without a live Game Center session. All completion handlers and
/// auth events are delivered on the main thread.
protocol GameKitInterface: AnyObject {
    var isAuthenticated: Bool { get }
    func authenticate(_ handler: @escaping (GameCenterAuthEvent) -> Void)
    func submitScore(_ score: Int, leaderboardID: String, completion: @escaping (Error?) -> Void)
    func reportAchievements(_ reports: [GameCenterAchievementReport], completion: @escaping (Error?) -> Void)
}

protocol GameCenterStatsProviding {
    func currentSnapshot() -> GameCenterSnapshot?
}
