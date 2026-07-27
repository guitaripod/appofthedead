import StoreKit
import UIKit

/// Asks for an App Store rating once the user has finished a few lessons, and at most once per
/// app version.
///
/// Rating count is both an App Store ranking input and the strongest conversion signal on a
/// product page, and this app shipped with no way to request one. A completed lesson is the unit
/// of value here — the prompt never fires on a launch, a tap, or a lesson the user abandoned.
@MainActor
enum ReviewPrompt {
    private static let lessonsBeforeAsking = 3
    private static let countKey = "aotd.review.completedLessons"
    private static let versionKey = "aotd.review.promptedVersion"

    /// Call when a lesson has been recorded as completed.
    static func recordCompletedLesson(in scene: UIWindowScene?) {
        let defaults = UserDefaults.standard
        let completed = defaults.integer(forKey: countKey) + 1
        defaults.set(completed, forKey: countKey)

        guard completed >= lessonsBeforeAsking else { return }
        guard defaults.string(forKey: versionKey) != currentVersion, let scene else { return }
        defaults.set(currentVersion, forKey: versionKey)
        AppLogger.learning.info("Review prompt requested after \(completed) lessons")
        AppStore.requestReview(in: scene)
    }

    private static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
}
