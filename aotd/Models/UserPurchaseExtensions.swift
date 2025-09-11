import Foundation
import GRDB
import RevenueCat

// Extension to User model for purchase and Oracle tracking
extension User {
    func hasAccess(to productId: ProductIdentifier) -> Bool {
        return DatabaseManager.shared.hasAccess(userId: id, to: productId)
    }
    
    func hasUltimateAccess() -> Bool {
        return hasAccess(to: .ultimateEnlightenment)
    }
    
    func hasOracleAccess() -> Bool {
        return hasAccess(to: .oracleWisdom) || hasUltimateAccess()
    }
    
    func hasPathAccess(beliefSystemId: String) -> Bool {
        // Judaism is always free
        if beliefSystemId == "judaism" { return true }
        
        // Check ultimate access
        if hasUltimateAccess() { return true }
        
        // Check specific path purchase
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
        // First check RevenueCat entitlements
        if Purchases.shared.cachedCustomerInfo?.entitlements["oracle_unlimited"]?.isActive == true { return true }
        if Purchases.shared.cachedCustomerInfo?.entitlements["ultimate"]?.isActive == true { return true }
        
        // Check deity pack access through RevenueCat
        if hasDeityPackAccessFromRevenueCat(for: deityId) { return true }
        
        // Fall back to local database check
        if hasOracleAccess() { return true }
        if hasDeityPackAccess(for: deityId) { return true }
        
        // Check free consultations (3 per deity)
        return DatabaseManager.shared.canConsultOracleForFree(userId: id, deityId: deityId)
    }
    
    private func hasDeityPackAccessFromRevenueCat(for deityId: String) -> Bool {
        // Map deities to their packs
        let egyptianDeities = ["anubis", "kali", "baron_samedi"]
        let greekDeities = ["hermes", "hecate", "pachamama"]
        let easternDeities = ["yama", "meng_po", "izanami"]
        
        if egyptianDeities.contains(deityId) {
            return Purchases.shared.cachedCustomerInfo?.entitlements["deity_egyptian"]?.isActive == true
        }
        if greekDeities.contains(deityId) {
            return Purchases.shared.cachedCustomerInfo?.entitlements["deity_greek"]?.isActive == true
        }
        if easternDeities.contains(deityId) {
            return Purchases.shared.cachedCustomerInfo?.entitlements["deity_eastern"]?.isActive == true
        }
        
        return false
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
        // Map deities to their packs based on actual deities in deity_prompts.json
        let egyptianDeities = ["anubis", "kali", "baron_samedi"] // Death deities pack
        let greekDeities = ["hermes", "hecate", "pachamama"] // Guide/Nature deities pack
        let easternDeities = ["yama", "meng_po", "izanami"] // Eastern afterlife deities pack
        
        if egyptianDeities.contains(deityId) && hasAccess(to: .egyptianPantheon) {
            return true
        }
        if greekDeities.contains(deityId) && hasAccess(to: .greekGuides) {
            return true
        }
        if easternDeities.contains(deityId) && hasAccess(to: .easternWisdom) {
            return true
        }
        
        return false
    }
}