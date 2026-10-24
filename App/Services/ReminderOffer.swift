import Foundation

/// Decides whether the inline "Remind me daily" card appears on the lesson-complete screen. It is
/// offered once, on the first lesson completion, and never on a completion where the rating
/// prompt can fire, so two system dialogs can't compete for the same moment.
struct ReminderOffer {
    static let shownKey = "aotd.reminderOfferShown"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func shouldPresent(priorSuccesses: Int, reminderEnabled: Bool) -> Bool {
        guard !defaults.bool(forKey: Self.shownKey), !reminderEnabled else { return false }
        return priorSuccesses + 1 < ReviewPrompt.firstAskThreshold
    }

    func markShown() {
        defaults.set(true, forKey: Self.shownKey)
    }
}
