import MidgarCommerce
import MidgarCore
import StoreKit
import UIKit

/// Asks for an App Store rating after the user has gotten value from the app. A completed lesson is this app's core
/// value moment. `MidgarReviewPolicy` decides whether the ask is due; this type only reports the success and, when
/// the policy says yes, shows Apple's prompt if nothing else is on screen.
///
/// The prompt never fires on a launch, a tap, a preview, or a lesson the user only replayed, never on the very
/// first completed lesson (that screen carries the reminder opt-in, see `ReminderOffer`), and it never interrupts a
/// paywall, alert or other UI already on screen.
@MainActor
enum ReviewPrompt {
    private nonisolated static let successCountKey = "aotd.review.successCount"
    private static let promptDelay: TimeInterval = 1.5

    /// The success count at which the rating prompt may first fire. Earlier completions belong to the reminder offer.
    nonisolated static let firstAskThreshold = 2

    nonisolated static var recordedSuccessCount: Int {
        UserDefaults.standard.integer(forKey: successCountKey)
    }

    nonisolated static let policy: MidgarReviewPolicy = {
        let storage = MidgarReviewFileStorage(appID: AotdMidgar.appID)
        LegacyReviewState.migrate(from: .standard, into: storage)
        return MidgarReviewPolicy(storage: storage)
    }()

    /// Counts one session. Call it once per launch.
    static func beginSession() {
        policy.beginSession()
    }

    /// Reports a purchase that failed, which holds the prompt back for a week.
    nonisolated static func notePurchaseFailure() {
        policy.notePurchaseFailure()
    }

    /// Call when a lesson (or its quiz) has been marked complete outside a preview or a replay.
    static func recordSuccess(in scene: UIWindowScene?) {
        let successCount = recordedSuccessCount + 1
        UserDefaults.standard.set(successCount, forKey: successCountKey)

        let due = policy.noteSuccess()
        guard due, successCount >= firstAskThreshold else {
            MidgarLog.info("Review prompt skipped | due: \(due), successCount: \(successCount)", category: .learning)
            return
        }
        guard let scene else {
            MidgarLog.info("Review prompt skipped | reason: no window scene, successCount: \(successCount)", category: .learning)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + promptDelay) {
            requestReviewIfStillSafe(scene: scene)
        }
    }

    private static func requestReviewIfStillSafe(scene: UIWindowScene) {
        guard scene.activationState == .foregroundActive, !isSomethingPresented(in: scene) else {
            MidgarLog.info("Review prompt dropped | reason: scene not eligible at fire time", category: .learning)
            return
        }
        policy.notePrompted()
        MidgarLog.info("Review prompt asked", category: .learning)
        AppStore.requestReview(in: scene)
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
}

/// The ask history the app kept before `MidgarReviewPolicy`: a list of ask dates, and before that a flag with the app
/// version that had asked. A person who was asked recently must not be asked again the day the policy changes, so
/// the newest ask becomes the policy's last prompt the first time it runs.
enum LegacyReviewState {
    static let askDatesKey = "aotd.review.askDates"
    static let legacyPromptedVersionKey = "aotd.review.promptedVersion"
    static let migratedKey = "aotd.review.migratedToMidgar"

    static func migrate(from defaults: UserDefaults, into storage: any MidgarReviewStorage, now: Date = Date()) {
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.set(true, forKey: migratedKey)
        guard let lastAsk = lastAsk(in: defaults, now: now) else { return }
        var state = storage.load()
        guard state.lastPrompt == nil else { return }
        state.lastPrompt = lastAsk
        state.lastPromptedVersion = defaults.string(forKey: legacyPromptedVersionKey)
        storage.save(state)
    }

    /// The newest recorded ask, or `now` when only the old per-version flag survives, since its date was never kept.
    private static func lastAsk(in defaults: UserDefaults, now: Date) -> Date? {
        let dates = defaults.array(forKey: askDatesKey) as? [Date] ?? []
        if let newest = dates.max() { return newest }
        return defaults.object(forKey: legacyPromptedVersionKey) == nil ? nil : now
    }
}
