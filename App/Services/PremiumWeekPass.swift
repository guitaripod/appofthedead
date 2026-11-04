import Foundation
import Security
import MidgarCore
import AppOfTheDeadCore

/// Where the Premium Week's start lives. The keychain keeps it across a reinstall, which would otherwise hand out a new
/// week; a defaults copy answers when the keychain cannot, as in a test host. The item is never synchronizable: a week
/// belongs to one device.
nonisolated struct PremiumWeekStore {
    static let defaultsKey = "aotd.premiumWeek.start"
    static let announcedKey = "aotd.premiumWeek.endAnnounced"
    private static let keychainService = "com.marcusziade.aotd.premiumweek"
    private static let keychainAccount = "start"

    private let defaults: UserDefaults
    private let usesKeychain: Bool

    static func live(defaults: UserDefaults = .standard) -> PremiumWeekStore {
        PremiumWeekStore(defaults: defaults, usesKeychain: true)
    }

    static func local(defaults: UserDefaults) -> PremiumWeekStore {
        PremiumWeekStore(defaults: defaults, usesKeychain: false)
    }

    func loadStart() -> Date? {
        let stored = usesKeychain ? Self.keychainStart() : nil
        let copy = defaults.object(forKey: Self.defaultsKey) as? Double
        guard let seconds = stored ?? copy else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    func saveStart(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: Self.defaultsKey)
        if usesKeychain { Self.writeKeychainStart(date.timeIntervalSince1970) }
    }

    var endAnnounced: Bool {
        get { defaults.bool(forKey: Self.announcedKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.announcedKey) }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
    }

    private static func keychainStart() -> Double? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let text = String(data: data, encoding: .utf8)
        else { return nil }
        return Double(text)
    }

    /// Adds the item once; a start that is already stored is never moved, so a wound clock cannot hand out a later week.
    private static func writeKeychainStart(_ seconds: Double) {
        var query = baseQuery
        query[kSecValueData as String] = Data(String(seconds).utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            MidgarLog.notice("Premium Week start not written to the keychain: \(status)", category: .purchases)
        }
    }
}

/// The person's Premium Week: whether it runs, when it ends, and starting it at the Judgment's verdict. A buyer never
/// gets one, and a week that has ended never comes back.
nonisolated final class PremiumWeekPass: @unchecked Sendable {
    static let shared = PremiumWeekPass(store: .live())
    static let changedNotification = Notification.Name("aotd.premiumWeek.changed")

    private let store: PremiumWeekStore
    private let now: @Sendable () -> Date
    private let notifications: NotificationCenter

    init(store: PremiumWeekStore, now: @escaping @Sendable () -> Date = Date.init, notifications: NotificationCenter = .default) {
        self.store = store
        self.now = now
        self.notifications = notifications
    }

    var phase: PremiumWeek.Phase {
        #if DEBUG
        if let demo = demoPhase { return demo }
        #endif
        return PremiumWeek.phase(start: store.loadStart(), now: now())
    }

    var isActive: Bool { phase.isActive }

    /// Days left, or nil when no week is running.
    var daysLeft: Int? {
        guard case .active(let end) = phase else { return nil }
        return PremiumWeek.daysLeft(until: end, now: now())
    }

    var endDate: Date? {
        if case .active(let end) = phase { return end }
        return nil
    }

    /// Starts the week unless it was given before or the person already owns everything. Returns whether it started.
    @discardableResult
    func start(ownsAllAccess: Bool) -> Bool {
        guard !ownsAllAccess, phase == .notStarted else { return false }
        store.saveStart(now())
        MidgarLog.info("Premium Week started", category: .purchases)
        notifications.post(name: Self.changedNotification, object: nil)
        return true
    }

    /// True once, the first time it is asked after the week ended for someone who still owns nothing.
    func takeEndAnnouncement(ownsAllAccess: Bool) -> Bool {
        guard case .over = phase, !ownsAllAccess, !store.endAnnounced else { return false }
        store.endAnnounced = true
        return true
    }

    #if DEBUG
    /// Screenshot rig: `AOTD_DEMO_WEEK=<days left>` shows a running week, `AOTD_DEMO_WEEK=over` an ended one.
    private var demoPhase: PremiumWeek.Phase? {
        guard let value = ProcessInfo.processInfo.environment["AOTD_DEMO_WEEK"] else { return nil }
        if value == "over" { return .over(endedAt: Date().addingTimeInterval(-3600)) }
        let days = Double(Int(value) ?? 5)
        return .active(endsAt: Date().addingTimeInterval(days * 86_400 - 3600))
    }
    #endif
}
