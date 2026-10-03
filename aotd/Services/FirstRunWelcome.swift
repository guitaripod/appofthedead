import Foundation

/// Decides whether the one-time welcome screen is shown. Only a brand-new install qualifies:
/// anyone who already has progress is treated as returning and marked as done, so a later
/// progress reset never greets them as a stranger.
struct FirstRunWelcome {
    static let completedKey = "aotd.didCompleteWelcome"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isCompleted: Bool {
        defaults.bool(forKey: Self.completedKey)
    }

    func shouldPresent(hasExistingProgress: Bool) -> Bool {
        guard !isCompleted else { return false }
        if hasExistingProgress {
            markCompleted()
            return false
        }
        return true
    }

    func markCompleted() {
        defaults.set(true, forKey: Self.completedKey)
    }
}
