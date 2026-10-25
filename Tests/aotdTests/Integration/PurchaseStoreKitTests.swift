import Foundation
import MidgarCommerce
import MidgarCore
import StoreKit
import StoreKitTest
import Testing
import UIKit

@testable import aotd

extension StoreKitSuites {
    /// Buys App of the Dead's products through MidgarStore with the app's own configuration, against `Products.storekit`
    /// (the file the scheme runs with), so the products, prices, trial and entitlement table the app ships are checked
    /// together on a real StoreKit. A test session signs its transactions with Xcode's local certificate, so the store
    /// never reports them to the ledger; the ledger is the gateway stub, which knows the Midgar ID and holds nothing.
    @MainActor
    @Suite(.timeLimit(.minutes(5)))
    struct PurchaseStoreKitTests {
        @MainActor
        private struct Harness {
            let store: MidgarStore
            let access: StoreAccess
            let manager: StoreManager
            let session: SKTestSession
            let notifications: NotificationCenter
            let directory: URL

            func stop() async {
                await store.stop()
                try? FileManager.default.removeItem(at: directory)
            }

            func buy(_ product: ProductIdentifier) async -> Result<PurchaseOutcome, Error> {
                await withCheckedContinuation { continuation in
                    manager.purchase(productId: product) { continuation.resume(returning: $0) }
                }
            }

            func restore() async -> Result<Bool, Error> {
                await withCheckedContinuation { continuation in
                    manager.restorePurchases { continuation.resume(returning: $0) }
                }
            }
        }

        private static let beliefSystemIds = ProductIdentifier.allCases.compactMap(\.beliefSystemId)

        private func makeHarness(
            askToBuy: Bool = false, earlier: [ProductIdentifier] = [], gatewayDown: Bool = false
        ) async throws -> Harness {
            let session = try SKTestSession(contentsOf: productsConfigurationURL)
            session.resetToDefaultState()
            session.clearTransactions()
            session.disableDialogs = true
            session.askToBuyEnabled = false
            for product in earlier {
                _ = try await session.buyProduct(identifier: product.rawValue)
            }
            session.askToBuyEnabled = askToBuy
            GatewayStub.reset()
            GatewayStub.setDown(gatewayDown)
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("aotd-store-" + UUID().uuidString, isDirectory: true)
            let store = MidgarStore(
                configuration: AotdMidgar.storeConfiguration(directory: directory),
                identity: StubIdentity(),
                http: MidgarHTTPClient(configuration: GatewayStub.httpConfiguration())
            )
            let notifications = NotificationCenter()
            let defaults = try #require(UserDefaults(suiteName: "aotd.tests.\(UUID().uuidString)"))
            let access = StoreAccess(store: store, cache: EntitlementCache(defaults: defaults), notifications: notifications)
            let scene = try hostScene()
            let manager = StoreManager(
                store: store, access: access, notifications: notifications, confirmationScene: { scene })
            manager.start()
            return Harness(
                store: store, access: access, manager: manager, session: session, notifications: notifications,
                directory: directory)
        }

        private func midgarIDOfCurrentTransaction(for product: ProductIdentifier) async -> UUID? {
            var found: UUID?
            _ = await eventually {
                for await verification in Transaction.currentEntitlements {
                    if case .verified(let transaction) = verification, transaction.productID == product.rawValue {
                        found = transaction.appAccountToken
                        return true
                    }
                }
                return false
            }
            return found
        }

        private func expectOwnsOnly(_ entitlements: Set<String>, in harness: Harness) async {
            #expect(await harness.store.entitlements.map(\.name).sorted() == entitlements.sorted())
            #expect(harness.access.entitlements == entitlements)
        }

        @Test func theConfigurationFileSellsEveryProductAtItsLivePrice() throws {
            let file = try StoreKitFile.load()
            let group = try #require(file.subscriptionGroups.first)
            let plans = Dictionary(uniqueKeysWithValues: group.subscriptions.map { ($0.productID, $0) })
            let oneTime = Dictionary(uniqueKeysWithValues: file.products.map { ($0.productID, $0) })

            #expect(file.subscriptionGroups.count == 1)
            #expect(group.name == "Premium")
            #expect(Set(plans.keys) == ["com.appofthedead.premium.annual", "com.appofthedead.premium.monthly"])
            #expect(plans["com.appofthedead.premium.monthly"]?.displayPrice == "2.99")
            #expect(plans["com.appofthedead.premium.monthly"]?.recurringSubscriptionPeriod == "P1M")
            #expect(plans["com.appofthedead.premium.monthly"]?.introductoryOffer == nil)
            #expect(plans["com.appofthedead.premium.annual"]?.displayPrice == "19.99")
            #expect(plans["com.appofthedead.premium.annual"]?.recurringSubscriptionPeriod == "P1Y")
            #expect(plans["com.appofthedead.premium.annual"]?.introductoryOffer?.paymentMode == "free")
            #expect(plans["com.appofthedead.premium.annual"]?.introductoryOffer?.subscriptionPeriod == "P1W")
            #expect(file.products.allSatisfy { $0.type == "NonConsumable" })
            #expect(file.allProducts.allSatisfy { !$0.familyShareable })
            #expect(Set(file.allProducts.map(\.productID)) == Set(ProductIdentifier.allCases.map(\.rawValue)))
            #expect(oneTime["com.appofthedead.ultimate"]?.displayPrice == "89.99")
            #expect(oneTime["com.appofthedead.oracle.wisdom"]?.displayPrice == "9.99")
            for product in ProductIdentifier.allCases where product.beliefSystemId != nil {
                #expect(oneTime[product.rawValue]?.displayPrice == "3.99")
            }
            for product in [ProductIdentifier.egyptianPantheon, .greekGuides, .easternWisdom] {
                #expect(oneTime[product.rawValue]?.displayPrice == "1.99")
            }
        }

        @Test func theStoreSellsEveryProductInPurchasesMode() {
            let configuration = AotdMidgar.storeConfiguration()

            #expect(configuration.mode == .purchases)
            #expect(configuration.appID == "app-of-the-dead")
            #expect(Set(configuration.productIDs) == Set(ProductIdentifier.allCases.map(\.rawValue)))
            #expect(configuration.productIDs.count == 28)
            #expect(configuration.crossAppEntitlements.isEmpty)
        }

        @Test func thePaywallPlansAreWhatStoreKitReportsWithTheTrialOnTheAnnualPlan() async throws {
            let harness = try await makeHarness()

            let plans = await withCheckedContinuation { continuation in
                harness.manager.fetchPremiumPlans { continuation.resume(returning: $0) }
            }
            let reported = try await Product.products(for: [
                "com.appofthedead.premium.annual", "com.appofthedead.premium.monthly", "com.appofthedead.ultimate"
            ])
            func displayPrice(_ id: String) throws -> String {
                try #require(reported.first { $0.id == id }).displayPrice
            }

            #expect(plans.annual?.localizedPrice == (try displayPrice("com.appofthedead.premium.annual")))
            #expect(plans.monthly?.localizedPrice == (try displayPrice("com.appofthedead.premium.monthly")))
            #expect(plans.lifetime?.localizedPrice == (try displayPrice("com.appofthedead.ultimate")))
            #expect(plans.annual?.trialDays == 7)
            #expect(plans.annual?.monthlyEquivalentPrice != nil)
            #expect(plans.monthly?.trialDays == nil)
            #expect(plans.monthly?.monthlyEquivalentPrice == nil)
            #expect(plans.lifetime?.trialDays == nil)
            await harness.stop()
        }

        @Test func everyProductHasAPriceInTheCacheOnceTheStoreStarts() async throws {
            let harness = try await makeHarness()

            #expect(await eventually {
                ProductIdentifier.allCases.allSatisfy { harness.manager.formattedPrice(for: $0) != nil }
            })
            let reported = try await Product.products(for: ["com.appofthedead.path.norse"])
            #expect(harness.manager.formattedPrice(for: .norse) == reported.first?.displayPrice)
            await harness.stop()
        }

        @Test(arguments: ProductIdentifier.allCases.filter { $0.beliefSystemId != nil })
        func buyingAPathGrantsOnlyThatPathAndCarriesTheMidgarID(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness()
            let beliefSystemId = try #require(product.beliefSystemId)
            #expect(!harness.access.hasPathAccess(beliefSystemId) || FreePaths.shared.isOpen(beliefSystemId))

            let result = await harness.buy(product)

            #expect(try result.get() == .purchased)
            await expectOwnsOnly([product.entitlement], in: harness)
            #expect(harness.access.hasPathAccess(beliefSystemId))
            #expect(!harness.access.hasAllAccess)
            #expect(!harness.access.hasUnlimitedOracle)
            for other in Self.beliefSystemIds where other != beliefSystemId && !FreePaths.shared.isOpen(other) {
                #expect(!harness.access.hasPathAccess(other))
            }
            #expect(await midgarIDOfCurrentTransaction(for: product) == UUID(uuidString: StubIdentity.midgarID))
            #expect(GatewayStub.requests(method: "POST", pathSuffix: "/v1/ledger/transactions").isEmpty)
            await harness.stop()
        }

        @Test(arguments: [ProductIdentifier.egyptianPantheon, .greekGuides, .easternWisdom])
        func buyingADeityPackGrantsOnlyThatPack(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness()
            let deities = ["anubis", "kali", "baron_samedi", "hermes", "hecate", "pachamama", "yama", "meng_po", "izanami"]

            let result = await harness.buy(product)

            #expect(try result.get() == .purchased)
            await expectOwnsOnly([product.entitlement], in: harness)
            for deity in deities {
                #expect(harness.access.hasDeityPack(for: deity) == (ProductIdentifier.deityPack(for: deity) == product))
            }
            #expect(!harness.access.hasAllAccess)
            #expect(!harness.access.hasUnlimitedOracle)
            #expect(await midgarIDOfCurrentTransaction(for: product) == UUID(uuidString: StubIdentity.midgarID))
            await harness.stop()
        }

        @Test func buyingTheOracleWisdomPackGrantsUnlimitedOracleOnly() async throws {
            let harness = try await makeHarness()

            let result = await harness.buy(.oracleWisdom)

            #expect(try result.get() == .purchased)
            await expectOwnsOnly(["oracle_unlimited"], in: harness)
            #expect(harness.access.hasUnlimitedOracle)
            #expect(!harness.access.hasAllAccess)
            for other in Self.beliefSystemIds where !FreePaths.shared.isOpen(other) {
                #expect(!harness.access.hasPathAccess(other))
            }
            await harness.stop()
        }

        @Test(arguments: [ProductIdentifier.ultimateEnlightenment, .premiumAnnual, .premiumMonthly])
        func buyingUltimateOrEitherSubscriptionGrantsAllAccess(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness()

            let result = await harness.buy(product)

            #expect(try result.get() == .purchased)
            await expectOwnsOnly(["ultimate"], in: harness)
            #expect(harness.access.hasAllAccess)
            #expect(harness.access.hasUnlimitedOracle)
            for beliefSystemId in Self.beliefSystemIds {
                #expect(harness.access.hasPathAccess(beliefSystemId))
            }
            #expect(await midgarIDOfCurrentTransaction(for: product) == UUID(uuidString: StubIdentity.midgarID))
            await harness.stop()
        }

        @Test(arguments: [ProductIdentifier.norse, .ultimateEnlightenment, .egyptianPantheon, .premiumAnnual])
        func aRestoreFindsAnEarlierPurchase(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness(earlier: [product])

            let result = await harness.restore()

            #expect(try result.get() == true)
            await expectOwnsOnly([product.entitlement], in: harness)
            await harness.stop()
        }

        @Test func aRestoreWithNothingToRestoreFindsNothing() async throws {
            let harness = try await makeHarness()

            let result = await harness.restore()

            #expect(try result.get() == false)
            #expect(harness.access.entitlements.isEmpty)
            await harness.stop()
        }

        @Test func anOwnerFromBeforeTheMoveKeepsEveryItemWithTheGatewayDown() async throws {
            let owned: [ProductIdentifier] = [.ultimateEnlightenment, .oracleWisdom, .greekGuides, .norse, .ancientEgyptian]
            let harness = try await makeHarness(earlier: owned, gatewayDown: true)

            await harness.access.refresh()

            await expectOwnsOnly(Set(owned.map(\.entitlement)), in: harness)
            #expect(harness.access.hasAllAccess)
            #expect(harness.access.hasUnlimitedOracle)
            #expect(harness.access.hasDeityPack(for: "hermes"))
            #expect(!GatewayStub.requests(method: "GET", pathSuffix: "/v1/ledger/entitlements").isEmpty)
            await harness.stop()
        }

        @Test(arguments: [ProductIdentifier.premiumAnnual, .premiumMonthly])
        func anEarlierSubscriberKeepsAllAccessWithTheGatewayDown(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness(earlier: [product], gatewayDown: true)

            await harness.access.refresh()

            #expect(harness.access.hasAllAccess)
            await harness.stop()
        }

        @Test func anEarlierPathOwnerKeepsOnlyThatPathWithTheGatewayDown() async throws {
            let harness = try await makeHarness(earlier: [.hinduism], gatewayDown: true)

            await harness.access.refresh()

            await expectOwnsOnly(["path_hinduism"], in: harness)
            #expect(harness.access.hasPathAccess("hinduism"))
            #expect(!harness.access.hasAllAccess)
            await harness.stop()
        }

        @Test(arguments: [ProductIdentifier.norse, .egyptianPantheon, .oracleWisdom, .ultimateEnlightenment])
        func aRefundTakesTheItemAway(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness()
            _ = await harness.buy(product)
            #expect(harness.access.entitlements == [product.entitlement])

            let transaction = try #require(harness.session.allTransactions().first)
            try harness.session.refundTransaction(identifier: UInt(transaction.identifier))

            #expect(await eventually { harness.access.entitlements.isEmpty })
            #expect(!harness.access.hasAllAccess)
            await harness.stop()
        }

        @Test func aRefundedPathLeavesAnotherOwnedPathAlone() async throws {
            let harness = try await makeHarness()
            _ = await harness.buy(.norse)
            _ = await harness.buy(.shinto)
            #expect(harness.access.entitlements == ["path_norse", "path_shinto"])

            let norse = try #require(
                harness.session.allTransactions().first { $0.productIdentifier == ProductIdentifier.norse.rawValue })
            try harness.session.refundTransaction(identifier: UInt(norse.identifier))

            #expect(await eventually { harness.access.entitlements == ["path_shinto"] })
            await harness.stop()
        }

        @Test(arguments: [ProductIdentifier.premiumMonthly, .premiumAnnual])
        func anExpiredSubscriptionTakesAllAccessAway(_ product: ProductIdentifier) async throws {
            let harness = try await makeHarness()
            _ = await harness.buy(product)
            #expect(harness.access.hasAllAccess)

            let transaction = try #require(harness.session.allTransactions().first)
            try harness.session.disableAutoRenewForTransaction(identifier: UInt(transaction.identifier))
            try harness.session.expireSubscription(productIdentifier: product.rawValue)

            #expect(await eventually {
                await harness.access.refresh()
                return !harness.access.hasAllAccess
            })
            await harness.stop()
        }

        @Test func askToBuyIsPendingUntilApprovedAndThenUnlocksByItself() async throws {
            let harness = try await makeHarness(askToBuy: true)
            var announced: [Notification.Name] = []
            let observers = [StoreManager.entitlementsUpdatedNotification, StoreManager.purchaseCompletedNotification]
                .map { name in
                    harness.notifications.addObserver(forName: name, object: nil, queue: .main) { _ in
                        MainActor.assumeIsolated { announced.append(name) }
                    }
                }

            let result = await harness.buy(.norse)

            #expect(try result.get() == .pending)
            #expect(harness.access.entitlements.isEmpty)
            #expect(!harness.access.hasPathAccess("norse") || FreePaths.shared.isOpen("norse"))

            let waiting = try #require(harness.session.allTransactions().first)
            try harness.session.approveAskToBuyTransaction(identifier: UInt(waiting.identifier))

            #expect(await eventually { harness.access.entitlements == ["path_norse"] })
            #expect(announced.contains(StoreManager.entitlementsUpdatedNotification))
            observers.forEach(harness.notifications.removeObserver)
            await harness.stop()
        }

        @Test func aFailedStorePurchaseIsASentenceAndGrantsNothing() async throws {
            let harness = try await makeHarness()
            try await harness.session.setSimulatedError(SKTestFailures.Purchase.generic(.unknown), forAPI: .purchase)

            let result = await harness.buy(.norse)

            guard case .failure(let error) = result else {
                Issue.record("A failed purchase must be a failure, got \(result)")
                return
            }
            #expect(error.localizedDescription == "The purchase could not be completed. Please try again.")
            #expect(harness.access.entitlements.isEmpty)
            try await harness.session.setSimulatedError(nil, forAPI: .purchase)
            await harness.stop()
        }

        @Test func aCancelledPurchaseIsNotAFailureAndShowsNothing() {
            #expect(PurchaseOutcome(.cancelled) == .cancelled)
            #expect(PurchaseOutcome(.pending) == .pending)
            #expect(PurchaseOutcome(.purchased) == .purchased)
        }
    }
}
