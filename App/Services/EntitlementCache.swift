import Foundation

/// The entitlement names the store last reported, kept on disk so a launch with no network opens with what the person
/// owns before the store has answered. Only an answer from the store replaces it.
nonisolated struct EntitlementCache {
    private static let key = "aotd.store.entitlements"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var names: Set<String> {
        Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func record(_ names: Set<String>) {
        defaults.set(names.sorted(), forKey: Self.key)
    }
}
