import Foundation
import UIKit
import RevenueCat

class StoreManager: NSObject {
    static let shared = StoreManager()
    
    // MARK: - Properties
    private var offerings: Offerings?
    private var customerInfo: CustomerInfo?
    
    // MARK: - Notifications
    static let purchaseCompletedNotification = Notification.Name("StoreManagerPurchaseCompleted")
    static let purchaseFailedNotification = Notification.Name("StoreManagerPurchaseFailed")
    static let entitlementsUpdatedNotification = Notification.Name("StoreManagerEntitlementsUpdated")
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_EPdbsDpeVyslVzSVIWLwbgIGKsc")
        Purchases.shared.delegate = self
        AppLogger.purchases.info("RevenueCat configured successfully")
    }
    

    
    // MARK: - Products and Offerings
    func fetchOfferings(completion: @escaping (Result<Offerings, Error>) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                completion(.failure(error))
            } else if let offerings = offerings {
                self.offerings = offerings
                completion(.success(offerings))
            } else {
                completion(.failure(NSError(domain: "StoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No offerings found"])))
            }
        }
    }
    
    // MARK: - Purchase Methods
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
    
    // MARK: - Restore Purchases
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
    
    // MARK: - Refresh Customer Info
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
        // Judaism is always free
        if beliefSystemId == "judaism" { return true }
        
        guard let customerInfo = customerInfo ?? Purchases.shared.cachedCustomerInfo else { 
            return false 
        }
        
        // Check ultimate access first
        if customerInfo.entitlements["ultimate"]?.isActive == true {
            return true
        }
        
        // Map belief system IDs from aotd.json to their RevenueCat entitlement names
        let entitlementMapping: [String: String] = [
            // Complex ID mappings
            "greek-underworld": "path_greek",
            "egyptian-afterlife": "path_ancient_egyptian",
            "aztec-mictlan": "path_aztec_mictlan",
            "aboriginal-dreamtime": "path_aboriginal_dreamtime",
            "native-american-visions": "path_native_american",
            "swedenborgian-visions": "path_swedenborgian",
            "zoroastrianism": "path_zoroastrian"
            // Simple IDs like "christianity", "islam", etc. will just get "path_" prefix
        ]
        
        // Use mapped entitlement name if available, otherwise convert directly
        let pathEntitlement: String
        if let mappedEntitlement = entitlementMapping[beliefSystemId] {
            pathEntitlement = mappedEntitlement
        } else {
            // For simple IDs without special characters, just add path_ prefix
            pathEntitlement = "path_\(beliefSystemId)"
        }
        
        return customerInfo.entitlements[pathEntitlement]?.isActive == true
    }
    
    // MARK: - Fetch Specific Products
    func fetchPathProduct(for beliefSystemId: String, completion: @escaping (StoreProduct?, String?) -> Void) {
        // Skip Judaism - it's free
        if beliefSystemId == "judaism" {
            completion(nil, nil)
            return
        }
        
        // Find the matching ProductIdentifier
        guard let productId = ProductIdentifier.allCases.first(where: { $0.beliefSystemId == beliefSystemId }) else {
            completion(nil, nil)
            return
        }
        
        // Fetch the product directly
        Purchases.shared.getProducts([productId.rawValue]) { products in
            if let product = products.first {
                completion(product, product.localizedPriceString)
            } else {
                completion(nil, self.formattedPrice(for: productId)) // Fallback price
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
    
    // MARK: - Price Formatting
    func formattedPrice(for productId: ProductIdentifier) -> String? {
        // Try to get actual price from cached products first
        if let offerings = offerings,
           let product = offerings.all.values.flatMap({ $0.availablePackages }).first(where: { $0.storeProduct.productIdentifier == productId.rawValue })?.storeProduct {
            return product.localizedPriceString
        }
        
        // Fallback prices
        switch productId {
        case .christianity, .islam, .buddhism, .hinduism, .ancientEgyptian, .greek, .norse, .shinto, .zoroastrian,
             .sikhism, .aztecMictlan, .taoism, .mandaeism, .wicca, .bahai, .tenrikyo, .aboriginalDreamtime,
             .nativeAmerican, .anthroposophy, .theosophy, .swedenborgian:
            return "$2.99"
        case .oracleWisdom:
            return "$9.99"
        case .ultimateEnlightenment:
            return "$19.99"
        case .egyptianPantheon, .greekGuides, .easternWisdom:
            return "$1.99"

        }
    }
}

// MARK: - PurchasesDelegate
extension StoreManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        
        
        NotificationCenter.default.post(name: Self.entitlementsUpdatedNotification, object: nil)
    }
    
    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        // Handle App Store promoted purchases
        startPurchase { transaction, customerInfo, error, userCancelled in
            if error == nil && !userCancelled {
                NotificationCenter.default.post(name: Self.purchaseCompletedNotification, object: nil)
            }
        }
    }
}