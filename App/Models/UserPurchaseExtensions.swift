import Foundation
import GRDB


extension User {
    func hasAccess(to productId: ProductIdentifier) -> Bool {
        return DatabaseManager.shared.hasAccess(userId: id, to: productId)
    }
    
    func hasUltimateAccess() -> Bool {
        return hasAccess(to: .ultimateEnlightenment) || StoreAccess.shared.hasAllAccess
    }
    
    func hasOracleAccess() -> Bool {
        return hasAccess(to: .oracleWisdom) || hasUltimateAccess()
    }
    
    func hasPathAccess(beliefSystemId: String) -> Bool {
        
        if FreePaths.shared.isOpen(beliefSystemId) { return true }
        
        
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

        if StoreAccess.shared.hasUnlimitedOracle { return true }


        if StoreAccess.shared.hasDeityPack(for: deityId) { return true }


        if hasOracleAccess() { return true }
        if hasDeityPackAccess(for: deityId) { return true }


        return DatabaseManager.shared.canConsultOracleForFree(userId: id, deityId: deityId)
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
            Diagnostics.logError(error, context: "Recording oracle consultation", category: .database)
        }
    }
    
    private func hasDeityPackAccess(for deityId: String) -> Bool {
        guard let pack = ProductIdentifier.deityPack(for: deityId) else { return false }
        return hasAccess(to: pack)
    }
}