import StoreKit
import UIKit

/// Asks for an App Store rating after a lesson the user did well in, at most once per app version.
///
/// Rating count is both an App Store ranking input and the strongest conversion signal on a
/// product page. A completed lesson is the unit of value here — the prompt never fires on a
/// launch, a tap, or a lesson the user abandoned.
@MainActor
enum ReviewPrompt {
    nonisolated static let minimumScore = 80
    private static let versionKey = "aotd.review.promptedVersion"

    /// Call when a lesson has been recorded as completed, with its percentage score.
    static func recordCompletedLesson(score: Int, in scene: UIWindowScene?) {
        let defaults = UserDefaults.standard
        guard shouldAsk(score: score, promptedVersion: defaults.string(forKey: versionKey), currentVersion: currentVersion),
              let scene else { return }
        defaults.set(currentVersion, forKey: versionKey)
        AppLogger.learning.info("Review prompt requested after a lesson scored \(score)%")
        AppStore.requestReview(in: scene)
    }

    /// Most new users never reach a third lesson, so the first lesson scoring at least
    /// `minimumScore` qualifies: a satisfied moment, early enough that the user is still here.
    nonisolated static func shouldAsk(score: Int, promptedVersion: String?, currentVersion: String) -> Bool {
        score >= minimumScore && promptedVersion != currentVersion
    }

    private static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
}
