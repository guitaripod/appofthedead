import Foundation
import UIKit
import RevenueCat

class StoreManager: NSObject {
    static let shared = StoreManager()


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
        Purchases.logLevel = .debug
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
    

    
    func hasPathAccess(_ beliefSystemId: String) -> Bool {
        
        if beliefSystemId == "judaism" { return true }
        
        guard let customerInfo = customerInfo ?? Purchases.shared.cachedCustomerInfo else { 
            return false 
        }
        
        
        if customerInfo.entitlements["ultimate"]?.isActive == true {
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