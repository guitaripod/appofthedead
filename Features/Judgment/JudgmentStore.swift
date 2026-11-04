import Foundation
import MidgarCore
import AppOfTheDeadCore

/// Keeps the weighed soul. The verdict is derived from it, so a better reading of the rules reaches old verdicts too.
/// The record is mirrored to iCloud key-value storage and read from there first, so every iPhone on the same Apple
/// Account shows the latest Soul Card.
nonisolated struct JudgmentStore {
    static let key = "aotd.judgment.soul"
    static let changedNotification = Notification.Name("aotd.judgment.changed")

    private let defaults: UserDefaults
    private let mirrorsToCloud: Bool

    init(defaults: UserDefaults = .standard, mirrorsToCloud: Bool = true) {
        self.defaults = defaults
        self.mirrorsToCloud = mirrorsToCloud
    }

    func load() -> SoulRecord? {
        let data = cloudData() ?? defaults.data(forKey: Self.key)
        guard let data else { return nil }
        do {
            return try JSONDecoder().decode(SoulRecord.self, from: data)
        } catch {
            MidgarLog.error("Could not read the saved soul: \(error)", category: .learning)
            return nil
        }
    }

    var verdict: Verdict? {
        load().map(JudgmentEngine.verdict(for:))
    }

    func save(_ soul: SoulRecord) {
        do {
            let data = try JSONEncoder().encode(soul)
            defaults.set(data, forKey: Self.key)
            if mirrorsToCloud {
                NSUbiquitousKeyValueStore.default.set(data, forKey: Self.key)
                NSUbiquitousKeyValueStore.default.synchronize()
            }
            NotificationCenter.default.post(name: Self.changedNotification, object: nil)
        } catch {
            MidgarLog.error("Could not save the soul: \(error)", category: .learning)
        }
    }

    private func cloudData() -> Data? {
        guard mirrorsToCloud else { return nil }
        return NSUbiquitousKeyValueStore.default.data(forKey: Self.key)
    }
}
