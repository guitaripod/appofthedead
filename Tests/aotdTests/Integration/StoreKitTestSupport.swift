import Foundation
import StoreKit
import Testing
import UIKit

/// The parent of every suite that touches StoreKit or the gateway stub. StoreKit's test session and the stub are
/// process-wide, so these suites run one after another and never beside each other.
@MainActor
@Suite("StoreKit", .serialized)
enum StoreKitSuites {}

/// Polls `condition` until it holds or `timeout` passes, for the StoreKit changes that reach the store through
/// `Transaction.updates` a moment after the test session makes them.
@MainActor
func eventually(timeout: Duration = .seconds(10), _ condition: () async -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(100))
    }
    return await condition()
}

/// The window scene of the test host, which every purchase confirms in: StoreKit inside a test host finds no window for
/// a scene-less purchase, so it never completes.
@MainActor
func hostScene() throws -> UIWindowScene {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
        throw URLError(.cannotFindHost)
    }
    return scene
}

/// The StoreKit configuration file the scheme runs with, which every StoreKit test reads.
nonisolated let productsConfigurationURL = appRootURL.appendingPathComponent("Products.storekit")

/// The registry entry of this app, which the entitlement table of the app must equal.
nonisolated let registryEntryURL = appRootURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("registry/apps/app-of-the-dead.toml")

/// The app's folder in the repository, found from this file's own path.
nonisolated private var appRootURL: URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

/// The parts of a StoreKit configuration file the product checks read.
nonisolated struct StoreKitFile: Decodable {
    struct Item: Decodable {
        let productID: String
        let displayPrice: String
        let referenceName: String
        let type: String
        let familyShareable: Bool
        let recurringSubscriptionPeriod: String?
        let introductoryOffer: IntroductoryOffer?
    }

    struct IntroductoryOffer: Decodable {
        let paymentMode: String
        let subscriptionPeriod: String
    }

    struct Group: Decodable {
        let name: String
        let subscriptions: [Item]
    }

    let products: [Item]
    let subscriptionGroups: [Group]

    static func load() throws -> StoreKitFile {
        try JSONDecoder().decode(StoreKitFile.self, from: Data(contentsOf: productsConfigurationURL))
    }

    var allProducts: [Item] {
        products + subscriptionGroups.flatMap(\.subscriptions)
    }
}
