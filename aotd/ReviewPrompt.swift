import StoreKit
import UIKit

/// Asks for an App Store rating after the user has gotten value from the app twice, and again
/// later if the first ask didn't lead anywhere.
///
/// A completed lesson is this app's core value moment. The prompt never fires on a launch, a
/// tap, a preview, or a lesson the user only replayed, and it never interrupts a paywall, alert
/// or other UI already on screen.
@MainActor
enum ReviewPrompt {
    private static let successCountKey = "aotd.review.successCount"
    private static let askDatesKey = "aotd.review.askDates"
    private static let successCountAtLastAskKey = "aotd.review.successCountAtLastAsk"
    private static let legacyPromptedVersionKey = "aotd.review.promptedVersion"

    static let firstAskThreshold = 2
    static let minimumNewSuccessesForReask = 3
    static let minimumDaysBetweenAsks = 14
    static let maximumAsksPerRollingYear = 3

    private static let rollingYear: TimeInterval = 365 * 24 * 60 * 60
    private static let minimumAskInterval: TimeInterval = TimeInterval(minimumDaysBetweenAsks) * 24 * 60 * 60
    private static let promptDelay: TimeInterval = 1.5

    /// Call when a lesson (or its quiz) has been marked complete outside a preview or a replay.
    static func recordSuccess(in scene: UIWindowScene?) {
        migrateLegacyStateIfNeeded()

        let defaults = UserDefaults.standard
        let successCount = defaults.integer(forKey: successCountKey) + 1
        defaults.set(successCount, forKey: successCountKey)

        let askDates = storedAskDates()
        let successCountAtLastAsk = defaults.integer(forKey: successCountAtLastAskKey)
        let now = Date()

        guard shouldAsk(
            successCount: successCount,
            askDates: askDates,
            successCountAtLastAsk: successCountAtLastAsk,
            now: now
        ) else {
            AppLogger.learning.info("Review prompt skipped | reason: not eligible, successCount: \(successCount), priorAsks: \(askDates.count)")
            return
        }
        guard let scene else {
            AppLogger.learning.info("Review prompt skipped | reason: no window scene, successCount: \(successCount)")
            return
        }

        let updatedAskDates = askDates + [now]
        defaults.set(updatedAskDates, forKey: askDatesKey)
        defaults.set(successCount, forKey: successCountAtLastAskKey)

        let askNumber = updatedAskDates.count
        AppLogger.learning.info("Review prompt asked (#\(askNumber)) | successCount: \(successCount)")

        DispatchQueue.main.asyncAfter(deadline: .now() + promptDelay) {
            guard scene.activationState == .foregroundActive,
                  scene.keyWindow?.rootViewController?.presentedViewController == nil else {
                AppLogger.learning.info("Review prompt (#\(askNumber)) dropped | reason: scene not eligible at fire time")
                return
            }
            AppStore.requestReview(in: scene)
        }
    }

    /// Pure eligibility check: the first ask fires the moment `successCount` reaches
    /// `firstAskThreshold`. Every later ask needs both `minimumNewSuccessesForReask` fresh
    /// successes and `minimumDaysBetweenAsks` since the previous ask, and no ask may push the
    /// trailing-365-day count past `maximumAsksPerRollingYear`.
    nonisolated static func shouldAsk(
        successCount: Int,
        askDates: [Date],
        successCountAtLastAsk: Int,
        now: Date
    ) -> Bool {
        let asksInRollingYear = askDates.filter { now.timeIntervalSince($0) < rollingYear }.count
        guard asksInRollingYear < maximumAsksPerRollingYear else { return false }

        guard let lastAskDate = askDates.max() else {
            return successCount >= firstAskThreshold
        }

        guard successCount - successCountAtLastAsk >= minimumNewSuccessesForReask else { return false }
        return now.timeIntervalSince(lastAskDate) >= minimumAskInterval
    }

    private static func storedAskDates() -> [Date] {
        (UserDefaults.standard.array(forKey: askDatesKey) as? [Date]) ?? []
    }

    /// The old mechanism only remembered whether the current build had already prompted once.
    /// That tells us an ask happened, never when, so it is folded in as an ask dated now: the
    /// conservative reading that still counts toward the 365-day cap without inventing a date.
    private static func migrateLegacyStateIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: legacyPromptedVersionKey) != nil else { return }
        if defaults.array(forKey: askDatesKey) == nil {
            defaults.set([Date()], forKey: askDatesKey)
        }
        defaults.removeObject(forKey: legacyPromptedVersionKey)
    }
}
