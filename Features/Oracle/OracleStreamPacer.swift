import Foundation

/// How much of a reply that is still being written to show at each frame. The model delivers text in bursts; the pacer
/// turns them into a steady flow that never trails the model by much: it reveals at least `minimumRate` characters a
/// second and speeds up so whatever is waiting appears within `catchUpWindow`, faster still once the reply is whole.
struct OracleStreamPacer {
    static let minimumRate: Double = 55
    static let catchUpWindow: TimeInterval = 0.35
    static let finishingWindow: TimeInterval = 0.18
    static let longestStep: TimeInterval = 0.1

    private(set) var targetLength = 0
    private(set) var isComplete = false
    private var revealed: Double = 0

    var visibleLength: Int {
        min(Int(revealed), targetLength)
    }

    var isCaughtUp: Bool {
        visibleLength >= targetLength
    }

    var isFinished: Bool {
        isComplete && isCaughtUp
    }

    /// The reply now has `length` characters; `isComplete` once the model has finished writing it.
    mutating func setTarget(length: Int, isComplete: Bool) {
        targetLength = max(0, length)
        self.isComplete = isComplete
        revealed = min(revealed, Double(targetLength))
    }

    /// Moves the reveal on by `elapsed` seconds and answers whether more characters became visible. A long pause
    /// (the app in the background, a dropped frame) counts as one short step, so text never lurches forward.
    @discardableResult
    mutating func advance(by elapsed: TimeInterval) -> Bool {
        let before = visibleLength
        let backlog = Double(targetLength) - revealed
        guard backlog > 0, elapsed > 0 else { return false }
        let window = isComplete ? Self.finishingWindow : Self.catchUpWindow
        let rate = max(Self.minimumRate, backlog / window)
        revealed = min(Double(targetLength), revealed + rate * min(elapsed, Self.longestStep))
        return visibleLength != before
    }

    /// Shows everything at once, for an answer that should not be animated.
    mutating func revealAll() {
        revealed = Double(targetLength)
    }
}
