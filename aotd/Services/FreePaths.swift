import Foundation

protocol PathGiftClaimStore {
    func hasClaimed(_ key: String) -> Bool
    func recordClaim(_ key: String)
}

/// Keeps event claims in `UserDefaults` and mirrors them to iCloud key-value storage, so a
/// reinstall on the same Apple Account keeps a path the user claimed during an event.
struct UbiquitousPathGiftClaimStore: PathGiftClaimStore {
    func hasClaimed(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key) || NSUbiquitousKeyValueStore.default.bool(forKey: key)
    }

    func recordClaim(_ key: String) {
        UserDefaults.standard.set(true, forKey: key)
        NSUbiquitousKeyValueStore.default.set(true, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}

/// A paid path opened to everyone for the days of an App Store in-app event.
struct PathGiftEvent: Equatable {
    let beliefSystemId: String
    let firstDay: DateComponents
    let lastDay: DateComponents

    var claimKey: String {
        "aotd.pathGift.\(beliefSystemId).\(firstDay.year ?? 0)"
    }

    /// Days are resolved in the given calendar's time zone, so the event opens at local midnight
    /// wherever the user is and stays open through the whole of its last day.
    func isRunning(at date: Date, calendar: Calendar) -> Bool {
        guard let start = calendar.date(from: firstDay),
              let lastDayStart = calendar.date(from: lastDay),
              let end = calendar.date(byAdding: .day, value: 1, to: lastDayStart) else { return false }
        return date >= start && date < end
    }
}

extension PathGiftEvent {
    static let diaDeLosMuertos2026 = PathGiftEvent(
        beliefSystemId: "aztec-mictlan",
        firstDay: DateComponents(year: 2026, month: 10, day: 24),
        lastDay: DateComponents(year: 2026, month: 11, day: 2)
    )
}

/// Decides which paths open without a purchase: Judaism always, plus any path an event is gifting
/// right now or that the user claimed by starting it while its event ran.
struct FreePaths {
    static let shared = FreePaths()

    private let alwaysFree: Set<String>
    private let events: [PathGiftEvent]
    private let claims: PathGiftClaimStore
    private let calendar: Calendar
    private let now: () -> Date

    init(
        alwaysFree: Set<String> = ["judaism"],
        events: [PathGiftEvent] = [.diaDeLosMuertos2026],
        claims: PathGiftClaimStore = UbiquitousPathGiftClaimStore(),
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init
    ) {
        self.alwaysFree = alwaysFree
        self.events = events
        self.claims = claims
        self.calendar = calendar
        self.now = now
    }

    func isOpen(_ beliefSystemId: String) -> Bool {
        if alwaysFree.contains(beliefSystemId) { return true }
        let date = now()
        return events.contains { event in
            event.beliefSystemId == beliefSystemId
                && (isRunning(event, at: date) || claims.hasClaimed(event.claimKey))
        }
    }

    /// Starting a lesson while an event runs keeps its path open after the event ends.
    func recordLessonStarted(in beliefSystemId: String) {
        let date = now()
        for event in events where event.beliefSystemId == beliefSystemId
            && isRunning(event, at: date)
            && !claims.hasClaimed(event.claimKey) {
            claims.recordClaim(event.claimKey)
            AppLogger.purchases.info("Claimed event path \(beliefSystemId, privacy: .public)")
        }
    }

    /// The App Store schedules the event card on UTC days while users live on local ones, so the
    /// path is open whenever either day falls inside the event. Nobody who taps the card finds it
    /// locked, and nobody loses the last evening of the event to a time-zone offset.
    private func isRunning(_ event: PathGiftEvent, at date: Date) -> Bool {
        event.isRunning(at: date, calendar: calendar) || event.isRunning(at: date, calendar: Self.utcCalendar)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
