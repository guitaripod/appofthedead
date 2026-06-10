import Foundation
import GRDB
import RevenueCat


extension User {
    func hasAccess(to productId: ProductIdentifier) -> Bool {
        return DatabaseManager.shared.hasAccess(userId: id, to: productId)
    }
    
    func hasUltimateAccess() -> Bool {
        return hasAccess(to: .ultimateEnlightenment) || StoreManager.shared.hasAllAccess()
    }
    
    func hasOracleAccess() -> Bool {
        return hasAccess(to: .oracleWisdom) || hasUltimateAccess()
    }
    
    func hasPathAccess(beliefSystemId: String) -> Bool {
        
        if beliefSystemId == "judaism" { return true }
        
        
        if hasUltimateAccess() { return true }
        
        
        for product in ProductIdentifier.allCases {
            if product.beliefSystemId == beliefSystemId && hasAccess(to: product) {
                return true
            }
        }
        
        return false
    }
    
    func getOracleConsultationCount(for deityId: String) -> Int {
        return DatabaseManager.shared.getOracleConsultationCount(userId: id, deityId: deityId)
    }
    

    
    func canConsultOracle(deityId: String) -> Bool {

        if Purchases.shared.cachedCustomerInfo?.entitlements["oracle_unlimited"]?.isActive == true { return true }
        if StoreManager.shared.hasAllAccess() { return true }


        if hasDeityPackAccessFromRevenueCat(for: deityId) { return true }


        if hasOracleAccess() { return true }
        if hasDeityPackAccess(for: deityId) { return true }


        return DatabaseManager.shared.canConsultOracleForFree(userId: id, deityId: deityId)
    }

    private func hasDeityPackAccessFromRevenueCat(for deityId: String) -> Bool {
        guard let entitlement = ProductIdentifier.deityPack(for: deityId)?.deityPackEntitlement else {
            return false
        }
        return Purchases.shared.cachedCustomerInfo?.entitlements[entitlement]?.isActive == true
    }
    
    func getRemainingFreeConsultations(for deityId: String) -> Int {
        let used = getOracleConsultationCount(for: deityId)
        return max(0, 3 - used)
    }
    
    func recordOracleConsultation(deityId: String) {
        let consultation = OracleConsultation(userId: id, deityId: deityId)
        do {
            try DatabaseManager.shared.saveOracleConsultation(consultation)
        } catch {
            AppLogger.logError(error, context: "Recording oracle consultation", logger: AppLogger.database)
        }
    }
    
    private func hasDeityPackAccess(for deityId: String) -> Bool {
        guard let pack = ProductIdentifier.deityPack(for: deityId) else { return false }
        return hasAccess(to: pack)
    }
}