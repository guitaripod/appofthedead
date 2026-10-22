import Foundation
import MidgarCommerce
import MidgarCore
import MidgarPortal

/// The composition root of everything App of the Dead shares with the other Midgar apps: the Midgar ID, the
/// gateway client built on it, the anonymous signals client and the read-only purchase store. One instance lives
/// for the whole process, so there is one identity and one ledger cache.
final class AotdMidgar: Sendable {
    /// The registry slug: the `X-App-ID` of every gateway call and the `app` of the ledger entries this app honours.
    static let appID = "app-of-the-dead"

    /// The bundle id the registry holds for the App Store record.
    static let bundleID = "com.marcusziade.aotd"

    /// The log file name, kept from the retired per-app logger so the `ios-device-logs` workflow still finds it.
    static let logFileName = "aotd.log"

    /// Every product the ledger may know about, with the registry's single entitlement for the three that unlock
    /// the whole app. Path and deity purchases keep their own RevenueCat entitlements and map to nothing here.
    static let allAccessEntitlement = "ultimate"

    static let shared = AotdMidgar()

    /// The Midgar ID client. Minted on first launch, attached on every later one, shared through the keychain group.
    let identity: MidgarIdentity

    /// The gateway client that carries the Midgar ID's bearer token, for the ledger and the portal's "Your Midgar".
    let account: MidgarHTTPClient

    /// The read-only ledger store, or nil in a test host or a demo capture.
    let ledger: MidgarStore?

    private init() {
        let configuration = MidgarHTTPConfiguration(appID: Self.appID)
        let identity = MidgarIdentity(httpConfiguration: configuration, bundleID: Self.bundleID)
        let account = MidgarHTTPClient(configuration: identity.authorizing(configuration))
        self.identity = identity
        self.account = account
        ledger = Self.reachesMidgarServices ? Self.makeStore(identity: identity, account: account) : nil
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
        let ledger = ledger
        Task {
            do {
                _ = try await identity.midgarId
                MidgarLog.info("Midgar ID ready", category: .account)
            } catch {
                MidgarLog.info("Midgar ID not available yet: \(error)", category: .account)
            }
            await Self.logLedgerEntitlements(of: ledger)
        }
    }

    /// Writes the entitlement names the ledger holds for this Midgar ID, so a support log shows whether the ledger
    /// knows the person's purchases. Names only, never ids or receipts.
    private static func logLedgerEntitlements(of ledger: MidgarStore?) async {
        guard let ledger else { return }
        await ledger.refresh()
        let names = await ledger.entitlements.map(\.name).sorted().joined(separator: ", ")
        MidgarLog.info("Ledger entitlements: \(names.isEmpty ? "none" : names)", category: .commerce)
    }

    /// The ledger reader. RevenueCat keeps buying, restoring and finishing every purchase (registry engine
    /// `rc-full`), so the store runs in `Mode.readOnly`: it asks the ledger what the Midgar ID owns and touches no
    /// transaction. Creating the store starts its foreground refresh, so create it once.
    private static func makeStore(identity: MidgarIdentity, account: MidgarHTTPClient) -> MidgarStore {
        MidgarStore(configuration: storeConfiguration, identity: identity, http: account)
    }

    static var storeConfiguration: MidgarStoreConfiguration {
        MidgarStoreConfiguration(
            appID: appID,
            productIDs: ProductIdentifier.allCases.map(\.rawValue),
            entitlementsByProduct: [
                ProductIdentifier.ultimateEnlightenment.rawValue: allAccessEntitlement,
                ProductIdentifier.premiumAnnual.rawValue: allAccessEntitlement,
                ProductIdentifier.premiumMonthly.rawValue: allAccessEntitlement
            ],
            mode: .readOnly
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
