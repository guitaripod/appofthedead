import Foundation
import MidgarCommerce
import Testing

@testable import aotd

/// Every read and write of the state happens under one lock.
private final class MemoryReviewStorage: MidgarReviewStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var state: MidgarReviewState

    init(_ state: MidgarReviewState = MidgarReviewState()) {
        self.state = state
    }

    func load() -> MidgarReviewState {
        lock.lock(); defer { lock.unlock() }
        return state
    }

    @discardableResult
    func save(_ state: MidgarReviewState) -> Bool {
        lock.lock(); defer { lock.unlock() }
        self.state = state
        return true
    }
}

struct ReviewPromptTests {
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "aotd.review.\(UUID().uuidString)")!
    }

    @Test func theNewestOldAskBecomesTheLastPrompt() {
        let defaults = defaults()
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_750_000_000)
        defaults.set([older, newer], forKey: LegacyReviewState.askDatesKey)
        let storage = MemoryReviewStorage()

        LegacyReviewState.migrate(from: defaults, into: storage)

        #expect(storage.load().lastPrompt == newer)
    }

    @Test func theOldPerVersionFlagCountsAsAnAskNow() {
        let defaults = defaults()
        defaults.set("1.4.7", forKey: LegacyReviewState.legacyPromptedVersionKey)
        let storage = MemoryReviewStorage()
        let now = Date(timeIntervalSince1970: 1_760_000_000)

        LegacyReviewState.migrate(from: defaults, into: storage, now: now)

        #expect(storage.load().lastPrompt == now)
        #expect(storage.load().lastPromptedVersion == "1.4.7")
    }

    @Test func someoneNeverAskedStaysUntouched() {
        let storage = MemoryReviewStorage()
        LegacyReviewState.migrate(from: defaults(), into: storage)
        #expect(storage.load() == MidgarReviewState())
    }

    @Test func migrationRunsOnceAndNeverOverwritesAPolicyPrompt() {
        let defaults = defaults()
        let prompted = Date(timeIntervalSince1970: 1_770_000_000)
        defaults.set([Date(timeIntervalSince1970: 1_700_000_000)], forKey: LegacyReviewState.askDatesKey)
        let storage = MemoryReviewStorage(MidgarReviewState(lastPrompt: prompted))

        LegacyReviewState.migrate(from: defaults, into: storage)
        #expect(storage.load().lastPrompt == prompted)

        defaults.set([Date(timeIntervalSince1970: 1_800_000_000)], forKey: LegacyReviewState.askDatesKey)
        storage.save(MidgarReviewState())
        LegacyReviewState.migrate(from: defaults, into: storage)
        #expect(storage.load().lastPrompt == nil)
    }

    @Test func aMigratedAskHoldsTheMidgarPolicyBack() {
        let defaults = defaults()
        let clock = Date(timeIntervalSince1970: 1_800_000_000)
        defaults.set([clock.addingTimeInterval(-86_400 * 10)], forKey: LegacyReviewState.askDatesKey)
        let storage = MemoryReviewStorage(MidgarReviewState(firstLaunch: clock.addingTimeInterval(-86_400 * 200), sessions: 20))

        LegacyReviewState.migrate(from: defaults, into: storage, now: clock)
        let policy = MidgarReviewPolicy(storage: storage, appVersion: "2.0", clock: { clock })
        policy.noteSuccess()

        #expect(policy.evaluate() == .hold(.promptedRecently))
    }

    @Test func theRatingPromptWaitsForTheSecondCompletedLesson() {
        #expect(ReviewPrompt.firstAskThreshold == 2)
        #expect(ReminderOffer(defaults: defaults()).shouldPresent(priorSuccesses: 0, reminderEnabled: false))
        #expect(!ReminderOffer(defaults: defaults()).shouldPresent(priorSuccesses: ReviewPrompt.firstAskThreshold - 1, reminderEnabled: false))
    }
}
