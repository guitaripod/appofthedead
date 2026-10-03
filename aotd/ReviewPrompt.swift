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
    private nonisolated static let successCountKey = "aotd.review.successCount"
    private static let askDatesKey = "aotd.review.askDates"
    private static let successCountAtLastAskKey = "aotd.review.successCountAtLastAsk"
    private static let legacyPromptedVersionKey = "aotd.review.promptedVersion"

    nonisolated static let firstAskThreshold = 2
    nonisolated static let minimumNewSuccessesForReask = 3
    nonisolated static let minimumDaysBetweenAsks = 14
    nonisolated static let maximumAsksPerRollingYear = 3

    private nonisolated static let rollingYear: TimeInterval = 365 * 24 * 60 * 60
    private nonisolated static let minimumAskInterval: TimeInterval = TimeInterval(minimumDaysBetweenAsks) * 24 * 60 * 60
    private static let promptDelay: TimeInterval = 1.5

    nonisolated static var recordedSuccessCount: Int {
        UserDefaults.standard.integer(forKey: successCountKey)
    }

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

        let askNumber = askDates.count + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + promptDelay) {
            guard scene.activationState == .foregroundActive,
                  !isSomethingPresented(in: scene) else {
                AppLogger.learning.info("Review prompt (#\(askNumber)) dropped | reason: scene not eligible at fire time")
                return
            }
            defaults.set(askDates + [now], forKey: askDatesKey)
            defaults.set(successCount, forKey: successCountAtLastAskKey)
            AppLogger.learning.info("Review prompt asked (#\(askNumber)) | successCount: \(successCount)")
            AppStore.requestReview(in: scene)
        }
    }

    /// Walks the full presentation chain rather than checking the root alone: a tab's own
    /// navigation controller (not the window's root container) is what actually presents the
    /// paywall and other sheets in this app, so only the root's `presentedViewController` would
    /// miss them.
    private static func isSomethingPresented(in scene: UIWindowScene) -> Bool {
        var top = scene.keyWindow?.rootViewController
        var foundSomething = false
        while let presented = top?.presentedViewController {
            foundSomething = true
            top = presented
        }
        return foundSomething
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
