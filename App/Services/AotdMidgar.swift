import Foundation
import MidgarCommerce
import MidgarCore
import MidgarPortal

/// The composition root of everything App of the Dead shares with the other Midgar apps: the Midgar ID, the
/// gateway client built on it, the anonymous signals client and the purchase store. One instance lives for the whole
/// process, so there is one identity, one store and one ledger cache.
nonisolated final class AotdMidgar: Sendable {
    /// The registry slug: the `X-App-ID` of every gateway call and the `app` of the ledger entries this app honours.
    static let appID = "app-of-the-dead"

    /// The bundle id the registry holds for the App Store record.
    static let bundleID = "com.marcusziade.aotd"

    /// The log file name, kept from the retired per-app logger so the `ios-device-logs` workflow still finds it.
    static let logFileName = "aotd.log"

    static let shared = AotdMidgar()

    /// The Midgar ID client. Minted on first launch, attached on every later one, shared through the keychain group.
    let identity: MidgarIdentity

    /// The gateway client that carries the Midgar ID's bearer token, for the ledger and the portal's "Your Midgar".
    let account: MidgarHTTPClient

    /// The purchase engine for everything the app sells: StoreKit 2 with the Midgar ID as `appAccountToken`, and the
    /// Midgar ledger as the cross-app record. Nil in a test host or a demo capture, which must not reach the ledger.
    let store: MidgarStore?

    private init() {
        let configuration = MidgarHTTPConfiguration(appID: Self.appID)
        let identity = MidgarIdentity(httpConfiguration: configuration, bundleID: Self.bundleID)
        let account = MidgarHTTPClient(configuration: identity.authorizing(configuration))
        self.identity = identity
        self.account = account
        store = Self.reachesMidgarServices ? Self.makeStore(identity: identity, account: account) : nil
    }

    /// The portal configuration of Settings: the authorized client, so "Your Midgar" shows what the person owns in
    /// the other apps and a cross-sell skips an app they already use.
    var portalConfig: MidgarPortal.MidgarConfig {
        MidgarPortal.MidgarConfig(placement: "settings", account: account)
    }

    /// Opens the log file. Call first thing at launch so nothing before the rest of the setup is lost.
    static func configureLogging() {
        MidgarLog.configure(fileName: logFileName)
    }

    /// Configures anonymous signals for the portal and starts the Midgar ID in the background, so the app holds one
    /// before the ledger is first asked. Call once at launch. A test host or a demo capture talks to no Midgar service.
    func start() {
        guard Self.reachesMidgarServices else {
            MidgarLog.info("Midgar services not started: test host or demo world", category: .account)
            return
        }
        MidgarSignals.configure(configuration: MidgarHTTPConfiguration(appID: Self.appID))
        let identity = identity
        let store = store
        Task {
            do {
                _ = try await identity.midgarId
                MidgarLog.info("Midgar ID ready", category: .account)
            } catch {
                MidgarLog.info("Midgar ID not available yet: \(error)", category: .account)
            }
            await Self.logEntitlements(of: store)
        }
    }

    /// Writes the entitlement names the store holds for this person, so a support log shows what the app unlocks.
    /// Names only, never ids or receipts.
    private static func logEntitlements(of store: MidgarStore?) async {
        guard let store else { return }
        await store.refresh()
        let names = await store.entitlements.map(\.name).sorted().joined(separator: ", ")
        MidgarLog.info("Store entitlements: \(names.isEmpty ? "none" : names)", category: .commerce)
    }

    /// The purchase store. MidgarCommerce buys, finishes and listens (registry engine `storekit2`). Creating the store
    /// starts its listeners and foreground refresh, so create it once.
    private static func makeStore(identity: MidgarIdentity, account: MidgarHTTPClient) -> MidgarStore {
        MidgarStore(configuration: storeConfiguration(), identity: identity, http: account)
    }

    /// Every product the app sells with the entitlement it grants (`ProductIdentifier.entitlement`, the table the
    /// registry's `[commerce.entitlements]` repeats), in `Mode.purchases`. `directory` moves the store's files for tests.
    static func storeConfiguration(directory: URL? = nil) -> MidgarStoreConfiguration {
        MidgarStoreConfiguration(
            appID: appID,
            productIDs: ProductIdentifier.allCases.map(\.rawValue),
            entitlementsByProduct: ProductIdentifier.entitlementsByProduct,
            mode: .purchases,
            directory: directory
        )
    }

    /// False inside an XCTest or Swift Testing host and in a DEBUG demo capture, which must not mint identities or
    /// send signals to the production services.
    static var reachesMidgarServices: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return false }
        #if DEBUG
        if DemoWorld.isActive { return false }
        #endif
        return true
    }
}
