import Foundation

/// Seven days of everything Premium opens, for a person who has not bought it, once per device, from the Judgment's
/// verdict: the first moment the app has shown them something of value (decisions D26 and D27). Nothing is charged and
/// nothing renews. The calendar is derived from the start date alone, so a relaunch, a reinstall or a clock change all
/// agree.
public enum PremiumWeek {

    public static let length: TimeInterval = 7 * 86_400

    public enum Phase: Equatable, Sendable {
        /// The week has not been given yet.
        case notStarted
        /// Every path and the unlimited Oracle are open until `endsAt`.
        case active(endsAt: Date)
        /// The week ended at `endedAt`.
        case over(endedAt: Date)

        public var isActive: Bool {
            if case .active = self { return true }
            return false
        }
    }

    /// The phase at `now` for a week that started at `start`. A clock wound back before the start reads as the week's
    /// first moment, never as a week that has not begun.
    public static func phase(start: Date?, now: Date) -> Phase {
        guard let start else { return .notStarted }
        let end = start.addingTimeInterval(length)
        if max(start, now) < end { return .active(endsAt: end) }
        return .over(endedAt: end)
    }

    /// Whole days left until `end`, counting a part day as a day, so the last day reads "1 day left" and never "0".
    public static func daysLeft(until end: Date, now: Date) -> Int {
        max(1, Int((end.timeIntervalSince(now) / 86_400).rounded(.up)))
    }
}
