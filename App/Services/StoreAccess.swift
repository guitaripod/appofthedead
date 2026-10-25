import Foundation
import MidgarCommerce
import MidgarCore
import Observation

/// What this person may open, read from `MidgarStore`. The store's entitlements are StoreKit's current entitlements on
/// this device united with the ledger's answer for the Midgar ID, so every gate here works with no network for anyone
/// who owns something, including a buyer from before purchases moved onto MidgarStore: an Apple transaction is an Apple
/// transaction whoever sold it.
///
/// The model keeps the entitlement names as plain state. It starts from the names the store last reported
/// (`EntitlementCache`), so a launch with no network opens what the person owns before the store has answered, and it
/// only replaces them with an answer from the store. A refund, a lapse or an Ask to Buy approval reaches it through the
/// store's `entitlementsChanged`; each change posts `StoreManager.entitlementsUpdatedNotification` for the screens that
/// listen. The store is nil in a test host or a demo capture, and the model then holds only what it was given.
@Observable
final class StoreAccess {
    static let shared = StoreAccess(store: AotdMidgar.shared.store)

    private(set) var entitlements: Set<String>

    @ObservationIgnored private let store: MidgarStore?
    @ObservationIgnored private let cache: EntitlementCache
    @ObservationIgnored private let notifications: NotificationCenter
    @ObservationIgnored private var listener: Task<Void, Never>?

    init(
        store: MidgarStore?, cache: EntitlementCache = EntitlementCache(),
        notifications: NotificationCenter = .default
    ) {
        self.store = store
        self.cache = cache
        self.notifications = notifications
        entitlements = cache.names
    }

    deinit {
        listener?.cancel()
    }

    /// True for the Ultimate unlock and for both Premium subscriptions, which all grant the `ultimate` entitlement.
    var hasAllAccess: Bool {
        isDemoPremium || entitlements.contains(AotdEntitlement.allAccess)
    }

    /// True when the person may consult any deity without a limit.
    var hasUnlimitedOracle: Bool {
        hasAllAccess || entitlements.contains(AotdEntitlement.oracleUnlimited)
    }

    func hasPathAccess(_ beliefSystemId: String) -> Bool {
        if FreePaths.shared.isOpen(beliefSystemId) { return true }
        if hasAllAccess { return true }
        guard let entitlement = ProductIdentifier.pathEntitlement(forBeliefSystem: beliefSystemId) else {
            return false
        }
        return entitlements.contains(entitlement)
    }

    func hasDeityPack(for deityId: String) -> Bool {
        guard let entitlement = ProductIdentifier.deityPack(for: deityId)?.entitlement else { return false }
        return entitlements.contains(entitlement)
    }

    /// Starts listening to the store, once. Every `entitlementsChanged` and `purchaseApproved` reads the entitlements
    /// again, so an Ask to Buy approval, a promoted purchase, an offer code, a purchase on another device, a refund
    /// and a lapse all reach the screens with no call of the app behind them.
    func startListening() {
        guard listener == nil, let store else { return }
        listener = Task { [weak self] in
            for await event in await store.events() {
                await self?.handle(event)
            }
        }
    }

    /// Brings the store up to date, then reads the entitlements: for the moments a decision must not rest on the
    /// placeholder of a store that has not answered yet.
    func refresh() async {
        guard let store else { return }
        await store.refresh()
        await readEntitlements()
    }

    /// Reads the store's entitlements into the model, remembers them for the next offline launch and tells the
    /// screens when they changed.
    func readEntitlements() async {
        guard let store else { return }
        let names = Set(await store.entitlements.map(\.name))
        cache.record(names)
        guard names != entitlements else { return }
        entitlements = names
        notifications.post(name: StoreManager.entitlementsUpdatedNotification, object: nil)
    }

    private func handle(_ event: MidgarStoreEvent) async {
        switch event {
        case .entitlementsChanged:
            await readEntitlements()
        case .purchaseApproved(let productID):
            await readEntitlements()
            notifications.post(
                name: StoreManager.purchaseCompletedNotification, object: ProductIdentifier(rawValue: productID))
        case .refused(let productID):
            MidgarLog.error("Store refused an unverified transaction for \(productID)", category: .purchases)
        }
    }

    /// Screenshot/QA rig: AOTD_DEMO_PREMIUM=1 renders the fully unlocked app without StoreKit. DEBUG builds only.
    private var isDemoPremium: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["AOTD_DEMO_PREMIUM"] == "1"
        #else
        return false
        #endif
    }
}
