import Foundation
import MidgarCommerce
import MidgarCore
import UIKit

struct PremiumPlanInfo: Equatable {
    let productId: ProductIdentifier
    let localizedPrice: String
    let monthlyEquivalentPrice: String?
    let trialDays: Int?
}

struct PremiumPlans: Equatable {
    let annual: PremiumPlanInfo?
    let monthly: PremiumPlanInfo?
    let lifetime: PremiumPlanInfo?

    static let empty = PremiumPlans(annual: nil, monthly: nil, lifetime: nil)
}

/// What a purchase that did not fail ended in. A cancel is silent and an Ask to Buy request waits for approval.
enum PurchaseOutcome: Equatable {
    case purchased
    case pending
    case cancelled

    init(_ result: MidgarPurchaseResult) {
        switch result {
        case .purchased: self = .purchased
        case .pending: self = .pending
        case .cancelled: self = .cancelled
        }
    }
}

protocol PaywallProductProviding: AnyObject {
    func fetchPremiumPlans(completion: @escaping (PremiumPlans) -> Void)
    func formattedPrice(for productId: ProductIdentifier) -> String?
    func fetchAndCachePrice(for productId: ProductIdentifier, completion: @escaping (String?) -> Void)
    func purchase(productId: ProductIdentifier, completion: @escaping (Result<PurchaseOutcome, Error>) -> Void)
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void)
}

/// Buys, restores and prices everything App of the Dead sells, through `MidgarStore`: StoreKit 2 on the device with the
/// Midgar ID as the `appAccountToken` of every purchase and the Midgar ledger as the record. Prices, billing periods and
/// the free trial come from StoreKit's own product data. What the person owns is read from ``StoreAccess``.
///
/// The store is nil in a test host or a demo capture; every call then ends in a failure or an empty answer.
final class StoreManager {
    static let shared = StoreManager(store: AotdMidgar.shared.store, access: .shared)

    static let purchaseCompletedNotification = Notification.Name("StoreManagerPurchaseCompleted")
    static let purchaseFailedNotification = Notification.Name("StoreManagerPurchaseFailed")
    static let entitlementsUpdatedNotification = Notification.Name("StoreManagerEntitlementsUpdated")

    private let store: MidgarStore?
    private let access: StoreAccess
    private let trialPolicy: MidgarTrialPolicy
    private let notifications: NotificationCenter
    private let confirmationScene: @MainActor () -> UIScene?
    private var cachedProducts: [String: StoreProduct] = [:]

    init(
        store: MidgarStore?, access: StoreAccess, trialPolicy: MidgarTrialPolicy = MidgarTrialPolicy(),
        notifications: NotificationCenter = .default,
        confirmationScene: @escaping @MainActor () -> UIScene? = StoreManager.foregroundScene
    ) {
        self.store = store
        self.access = access
        self.trialPolicy = trialPolicy
        self.notifications = notifications
        self.confirmationScene = confirmationScene
    }

    /// Starts the store's listeners and brings the entitlements up to date. Queues the purchases StoreKit already holds
    /// for the ledger once per install, so a buyer from before purchases moved onto MidgarStore reaches their Midgar ID
    /// without a restore. Call once at launch.
    func start() {
        guard let store else {
            MidgarLog.info("Store not started: test host or demo world", category: .purchases)
            return
        }
        access.startListening()
        Task {
            await store.reportPurchaseHistory()
            await access.refresh()
            await prefetchAllPrices()
        }
    }

    private func prefetchAllPrices() async {
        guard let store else { return }
        do {
            let products = try await store.products()
            cache(products)
            MidgarLog.info("Pre-fetched \(products.count) product prices", category: .purchases)
        } catch {
            MidgarLog.error("Product prices not available yet: \(error)", category: .purchases)
        }
    }

    private func cache(_ products: [StoreProduct]) {
        for product in products {
            cachedProducts[product.id] = product
        }
    }

    func purchase(productId: ProductIdentifier, completion: @escaping (Result<PurchaseOutcome, Error>) -> Void) {
        Task {
            guard let store else {
                completion(.failure(StorePurchaseError.unavailable))
                return
            }
            do {
                let outcome = PurchaseOutcome(try await buy(productId.rawValue, in: store))
                switch outcome {
                case .purchased:
                    await access.readEntitlements()
                    completion(.success(.purchased))
                    notifications.post(name: Self.purchaseCompletedNotification, object: productId)
                case .pending:
                    MidgarLog.info("Purchase waiting for approval: \(productId.rawValue)", category: .purchases)
                    completion(.success(.pending))
                case .cancelled:
                    MidgarLog.info("Purchase cancelled by user: \(productId.rawValue)", category: .purchases)
                    completion(.success(.cancelled))
                }
            } catch {
                MidgarLog.error("Purchase failed for \(productId.rawValue): \(error)", category: .purchases)
                ReviewPrompt.notePurchaseFailure()
                completion(.failure(StorePurchaseError.purchaseFailed))
            }
        }
    }

    /// Buys through the store with the confirmation sheet anchored to the foreground scene, or without an anchor when
    /// the app has no scene yet.
    private func buy(_ productID: String, in store: MidgarStore) async throws -> MidgarPurchaseResult {
        if let scene = confirmationScene() {
            return try await store.purchase(productID, confirmIn: scene)
        }
        return try await store.purchase(productID)
    }

    /// The scene a purchase confirms in: the active window scene, else any window scene.
    static func foregroundScene() -> UIScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }

    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            guard let store else {
                completion(.failure(StorePurchaseError.unavailable))
                return
            }
            do {
                try await store.restore()
                await access.readEntitlements()
                let restored = await !store.entitlements.isEmpty
                MidgarLog.info("Restore completed, restored purchases found: \(restored)", category: .purchases)
                completion(.success(restored))
                notifications.post(name: Self.entitlementsUpdatedNotification, object: nil)
            } catch {
                MidgarLog.error("Restore failed: \(error)", category: .purchases)
                completion(.failure(StorePurchaseError.restoreFailed))
            }
        }
    }

    func refreshEntitlements(completion: @escaping () -> Void) {
        Task {
            await access.refresh()
            completion()
        }
    }

    func formattedPrice(for productId: ProductIdentifier) -> String? {
        cachedProducts[productId.rawValue]?.displayPrice
    }

    func fetchPremiumPlans(completion: @escaping (PremiumPlans) -> Void) {
        Task {
            guard let store else {
                completion(.empty)
                return
            }
            let products: [StoreProduct]
            do {
                products = try await store.products()
            } catch {
                MidgarLog.error("Failed to fetch premium plan products from the App Store: \(error)", category: .purchases)
                completion(.empty)
                return
            }
            guard !products.isEmpty else {
                MidgarLog.error("Failed to fetch premium plan products from the App Store", category: .purchases)
                completion(.empty)
                return
            }
            cache(products)
            let trials = (try? await trialPolicy.presentations(for: [ProductIdentifier.premiumAnnual.rawValue])) ?? [:]
            completion(Self.plans(from: products, trials: trials))
        }
    }

    static func plans(from products: [StoreProduct], trials: [String: MidgarTrialPresentation]) -> PremiumPlans {
        let productsById = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        func info(_ id: ProductIdentifier) -> PremiumPlanInfo? {
            productsById[id.rawValue].map {
                planInfo(for: $0, id: id, trial: trials[id.rawValue])
            }
        }
        return PremiumPlans(
            annual: info(.premiumAnnual),
            monthly: info(.premiumMonthly),
            lifetime: info(.ultimateEnlightenment)
        )
    }

    private static func planInfo(for product: StoreProduct, id: ProductIdentifier, trial: MidgarTrialPresentation?)
        -> PremiumPlanInfo
    {
        PremiumPlanInfo(
            productId: id,
            localizedPrice: product.displayPrice,
            monthlyEquivalentPrice: monthlyEquivalentPrice(for: product, id: id),
            trialDays: trial.flatMap(freeTrialDays(of:))
        )
    }

    private static func monthlyEquivalentPrice(for product: StoreProduct, id: ProductIdentifier) -> String? {
        guard id == .premiumAnnual else { return nil }
        let monthly = (product.price as NSDecimalNumber)
            .dividing(by: 12, withBehavior: NSDecimalNumberHandler(
                roundingMode: .plain, scale: 2,
                raiseOnExactness: false, raiseOnOverflow: false,
                raiseOnUnderflow: false, raiseOnDivideByZero: false))
        return priceFormatter(for: product).string(from: monthly)
    }

    private static func priceFormatter(for product: StoreProduct) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale ?? .current
        if let code = product.currencyCode {
            formatter.currencyCode = code
        }
        return formatter
    }

    /// The length of a free trial in days, with a week counted as 7, a month as 30 and a year as 365. A paid
    /// introductory offer is not a trial.
    private static func freeTrialDays(of presentation: MidgarTrialPresentation) -> Int? {
        guard presentation.isFreeTrial else { return nil }
        let total = presentation.offer.totalDuration
        switch total.unit {
        case .day: return total.value
        case .week: return total.value * 7
        case .month: return total.value * 30
        case .year: return total.value * 365
        }
    }

    func fetchAndCachePrice(for productId: ProductIdentifier, completion: @escaping (String?) -> Void) {
        if let cachedPrice = formattedPrice(for: productId) {
            completion(cachedPrice)
            return
        }
        Task {
            await prefetchAllPrices()
            completion(formattedPrice(for: productId))
        }
    }
}

extension StoreManager: PaywallProductProviding {}
