import Foundation
import UIKit
import RevenueCat

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

protocol PaywallProductProviding: AnyObject {
    func fetchPremiumPlans(completion: @escaping (PremiumPlans) -> Void)
    func formattedPrice(for productId: ProductIdentifier) -> String?
    func fetchAndCachePrice(for productId: ProductIdentifier, completion: @escaping (String?) -> Void)
    func purchase(productId: ProductIdentifier, completion: @escaping (Result<Bool, Error>) -> Void)
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void)
}

class StoreManager: NSObject {
    static let shared = StoreManager()

    static let premiumSubscriptionIds: Set<String> = [
        ProductIdentifier.premiumAnnual.rawValue,
        ProductIdentifier.premiumMonthly.rawValue
    ]


    private var offerings: Offerings?
    private var customerInfo: CustomerInfo?
    private var cachedProducts: [String: StoreProduct] = [:]
    
    
    static let purchaseCompletedNotification = Notification.Name("StoreManagerPurchaseCompleted")
    static let purchaseFailedNotification = Notification.Name("StoreManagerPurchaseFailed")
    static let entitlementsUpdatedNotification = Notification.Name("StoreManagerEntitlementsUpdated")
    
    
    private override init() {
        super.init()
    }
    
    func configure() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: "appl_EPdbsDpeVyslVzSVIWLwbgIGKsc")
        Purchases.shared.delegate = self
        AppLogger.purchases.info("RevenueCat configured successfully")

        prefetchAllPrices()
    }

    private func prefetchAllPrices() {
        let allProductIds = ProductIdentifier.allCases.map { $0.rawValue }

        Purchases.shared.getProducts(allProductIds) { [weak self] products in
            for product in products {
                self?.cachedProducts[product.productIdentifier] = product
            }
            AppLogger.purchases.info("Pre-fetched \(products.count) product prices")
        }
    }
    

    
    
    func fetchOfferings(completion: @escaping (Result<Offerings, Error>) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                completion(.failure(error))
            } else if let offerings = offerings {
                self.offerings = offerings

                for offering in offerings.all.values {
                    for package in offering.availablePackages {
                        self.cachedProducts[package.storeProduct.productIdentifier] = package.storeProduct
                    }
                }

                completion(.success(offerings))
            } else {
                completion(.failure(NSError(domain: "StoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No offerings found"])))
            }
        }
    }
    
    
    func purchase(productId: ProductIdentifier, completion: @escaping (Result<Bool, Error>) -> Void) {
        Purchases.shared.getProducts([productId.rawValue]) { products in
            guard let product = products.first else {
                completion(.failure(NSError(domain: "StoreManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Product not found"])))
                return
            }
            
            Purchases.shared.purchase(product: product) { transaction, customerInfo, error, userCancelled in
                if let error = error {
                    completion(.failure(error))
                } else if userCancelled {
                    completion(.failure(NSError(domain: "StoreManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled"])))
                } else {
                    self.customerInfo = customerInfo
                    completion(.success(true))
                    NotificationCenter.default.post(name: Self.purchaseCompletedNotification, object: productId)
                }
            }
        }
    }
    
    
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.customerInfo = customerInfo
                completion(.success(true))
                NotificationCenter.default.post(name: Self.entitlementsUpdatedNotification, object: nil)
            }
        }
    }
    
    
    func refreshCustomerInfo(completion: @escaping () -> Void) {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            if let customerInfo = customerInfo {
                self?.customerInfo = customerInfo
                NotificationCenter.default.post(name: Self.entitlementsUpdatedNotification, object: nil)
            }
            completion()
        }
    }
    

    
    func hasAllAccess() -> Bool {
        if isDemoPremium { return true }
        guard let customerInfo = customerInfo ?? Purchases.shared.cachedCustomerInfo else {
            return false
        }
        return Self.grantsAllAccess(customerInfo)
    }

    /// Screenshot/QA rig: AOTD_DEMO_PREMIUM=1 renders the fully unlocked app
    /// without StoreKit. DEBUG builds only.
    private var isDemoPremium: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["AOTD_DEMO_PREMIUM"] == "1"
        #else
        return false
        #endif
    }

    /// The premium subscriptions are not yet attached to a RevenueCat entitlement
    /// (dashboard credentials are not available on this machine), so all-access is
    /// derived from the raw purchase records in addition to the legacy "ultimate"
    /// entitlement. Move to a pure entitlement check once the RevenueCat project
    /// maps both subscription products to "ultimate".
    static func grantsAllAccess(_ customerInfo: CustomerInfo) -> Bool {
        if customerInfo.entitlements["ultimate"]?.isActive == true {
            return true
        }
        if !premiumSubscriptionIds.isDisjoint(with: customerInfo.activeSubscriptions) {
            return true
        }
        return customerInfo.nonSubscriptions.contains {
            $0.productIdentifier == ProductIdentifier.ultimateEnlightenment.rawValue
        }
    }

    func hasPathAccess(_ beliefSystemId: String) -> Bool {

        if beliefSystemId == "judaism" { return true }

        if isDemoPremium { return true }

        guard let customerInfo = customerInfo ?? Purchases.shared.cachedCustomerInfo else {
            return false
        }


        if Self.grantsAllAccess(customerInfo) {
            return true
        }
        
        
        let entitlementMapping: [String: String] = [
            
            "greek-underworld": "path_greek",
            "egyptian-afterlife": "path_ancient_egyptian",
            "aztec-mictlan": "path_aztec_mictlan",
            "aboriginal-dreamtime": "path_aboriginal_dreamtime",
            "native-american-visions": "path_native_american",
            "swedenborgian-visions": "path_swedenborgian",
            "zoroastrianism": "path_zoroastrian"
            
        ]
        
        
        let pathEntitlement: String
        if let mappedEntitlement = entitlementMapping[beliefSystemId] {
            pathEntitlement = mappedEntitlement
        } else {
            
            pathEntitlement = "path_\(beliefSystemId)"
        }
        
        return customerInfo.entitlements[pathEntitlement]?.isActive == true
    }
    
    
    func fetchPathProduct(for beliefSystemId: String, completion: @escaping (StoreProduct?, String?) -> Void) {
        
        if beliefSystemId == "judaism" {
            completion(nil, nil)
            return
        }
        
        
        guard let productId = ProductIdentifier.allCases.first(where: { $0.beliefSystemId == beliefSystemId }) else {
            completion(nil, nil)
            return
        }
        
        
        Purchases.shared.getProducts([productId.rawValue]) { products in
            if let product = products.first {
                completion(product, product.localizedPriceString)
            } else {
                completion(nil, self.formattedPrice(for: productId)) 
            }
        }
    }
    
    func fetchFeaturedProducts(completion: @escaping (Offering?) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            completion(offerings?.current)
        }
    }
    
    func fetchDeityPacks(completion: @escaping ([Package]) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            guard let offering = offerings?.current else {
                completion([])
                return
            }
            
            let deityPacks = [
                offering.package(identifier: "deity_egyptian"),
                offering.package(identifier: "deity_greek"),
                offering.package(identifier: "deity_eastern")
            ].compactMap { $0 }
            
            completion(deityPacks)
        }
    }
    

    func formattedPrice(for productId: ProductIdentifier) -> String? {

        if let cachedProduct = cachedProducts[productId.rawValue] {
            return cachedProduct.localizedPriceString
        }


        if let offerings = offerings,
           let product = offerings.all.values.flatMap({ $0.availablePackages }).first(where: { $0.storeProduct.productIdentifier == productId.rawValue })?.storeProduct {
            cachedProducts[productId.rawValue] = product
            return product.localizedPriceString
        }


        return nil
    }

    func fetchPremiumPlans(completion: @escaping (PremiumPlans) -> Void) {
        let planProductIds: [ProductIdentifier] = [.premiumAnnual, .premiumMonthly, .ultimateEnlightenment]

        Purchases.shared.getProducts(planProductIds.map(\.rawValue)) { [weak self] products in
            guard let self else {
                DispatchQueue.main.async { completion(.empty) }
                return
            }

            for product in products {
                self.cachedProducts[product.productIdentifier] = product
            }

            let productsById = Dictionary(uniqueKeysWithValues: products.map { ($0.productIdentifier, $0) })
            let annualProduct = productsById[ProductIdentifier.premiumAnnual.rawValue]

            Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: [ProductIdentifier.premiumAnnual.rawValue]) { eligibility in
                let status = eligibility[ProductIdentifier.premiumAnnual.rawValue]?.status ?? .unknown
                let trialEligible = status != .ineligible && status != .noIntroOfferExists

                let plans = PremiumPlans(
                    annual: annualProduct.map {
                        Self.planInfo(for: $0, id: .premiumAnnual, trialEligible: trialEligible)
                    },
                    monthly: productsById[ProductIdentifier.premiumMonthly.rawValue].map {
                        Self.planInfo(for: $0, id: .premiumMonthly, trialEligible: false)
                    },
                    lifetime: productsById[ProductIdentifier.ultimateEnlightenment.rawValue].map {
                        Self.planInfo(for: $0, id: .ultimateEnlightenment, trialEligible: false)
                    }
                )

                DispatchQueue.main.async { completion(plans) }
            }
        }
    }

    private static func planInfo(for product: StoreProduct, id: ProductIdentifier, trialEligible: Bool) -> PremiumPlanInfo {
        PremiumPlanInfo(
            productId: id,
            localizedPrice: product.localizedPriceString,
            monthlyEquivalentPrice: monthlyEquivalentPrice(for: product, id: id),
            trialDays: trialEligible ? freeTrialDays(for: product) : nil
        )
    }

    private static func monthlyEquivalentPrice(for product: StoreProduct, id: ProductIdentifier) -> String? {
        guard id == .premiumAnnual, let formatter = product.priceFormatter else { return nil }
        let monthly = (product.price as NSDecimalNumber)
            .dividing(by: 12, withBehavior: NSDecimalNumberHandler(
                roundingMode: .plain, scale: 2,
                raiseOnExactness: false, raiseOnOverflow: false,
                raiseOnUnderflow: false, raiseOnDivideByZero: false))
        return formatter.string(from: monthly)
    }

    private static func freeTrialDays(for product: StoreProduct) -> Int? {
        guard let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        }
    }

    func fetchAndCachePrice(for productId: ProductIdentifier, completion: @escaping (String?) -> Void) {

        if let cachedPrice = formattedPrice(for: productId) {
            completion(cachedPrice)
            return
        }


        Purchases.shared.getProducts([productId.rawValue]) { [weak self] products in
            if let product = products.first {
                self?.cachedProducts[productId.rawValue] = product
                completion(product.localizedPriceString)
            } else {
                completion(nil)
            }
        }
    }
}


extension StoreManager: PaywallProductProviding {}

extension StoreManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        
        
        NotificationCenter.default.post(name: Self.entitlementsUpdatedNotification, object: nil)
    }
    
    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        
        startPurchase { transaction, customerInfo, error, userCancelled in
            if error == nil && !userCancelled {
                NotificationCenter.default.post(name: Self.purchaseCompletedNotification, object: nil)
            }
        }
    }
}