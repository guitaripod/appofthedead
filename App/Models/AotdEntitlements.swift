import Foundation

/// The two entitlement names that are not tied to a single path or deity pack.
nonisolated enum AotdEntitlement {
    /// Every path, the Oracle and every future addition: the Ultimate unlock and both Premium subscriptions.
    static let allAccess = "ultimate"

    /// Unlimited Oracle consultations with every deity, from the Oracle Wisdom pack.
    static let oracleUnlimited = "oracle_unlimited"
}

nonisolated extension ProductIdentifier {
    /// The entitlement this product grants, exactly as the app checks it and as the registry's
    /// `[commerce.entitlements]` table names it. This switch is the one table in the app: the store configuration
    /// and every gate read it, and a test holds it equal to the registry.
    var entitlement: String {
        switch self {
        case .ultimateEnlightenment, .premiumAnnual, .premiumMonthly: return AotdEntitlement.allAccess
        case .oracleWisdom: return AotdEntitlement.oracleUnlimited
        case .egyptianPantheon: return "deity_egyptian"
        case .greekGuides: return "deity_greek"
        case .easternWisdom: return "deity_eastern"
        case .christianity: return "path_christianity"
        case .islam: return "path_islam"
        case .buddhism: return "path_buddhism"
        case .hinduism: return "path_hinduism"
        case .ancientEgyptian: return "path_ancient_egyptian"
        case .greek: return "path_greek"
        case .norse: return "path_norse"
        case .shinto: return "path_shinto"
        case .zoroastrian: return "path_zoroastrian"
        case .sikhism: return "path_sikhism"
        case .aztecMictlan: return "path_aztec_mictlan"
        case .taoism: return "path_taoism"
        case .mandaeism: return "path_mandaeism"
        case .wicca: return "path_wicca"
        case .bahai: return "path_bahai"
        case .tenrikyo: return "path_tenrikyo"
        case .aboriginalDreamtime: return "path_aboriginal_dreamtime"
        case .nativeAmerican: return "path_native_american"
        case .anthroposophy: return "path_anthroposophy"
        case .theosophy: return "path_theosophy"
        case .swedenborgian: return "path_swedenborgian"
        }
    }

    /// Product id to entitlement name for every product the app sells, the map `MidgarStoreConfiguration` takes.
    static var entitlementsByProduct: [String: String] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0.rawValue, $0.entitlement) })
    }

    /// The entitlement that unlocks the path of `beliefSystemId`, or nil for a path nobody sells (Judaism).
    static func pathEntitlement(forBeliefSystem beliefSystemId: String) -> String? {
        allCases.first { $0.beliefSystemId == beliefSystemId }?.entitlement
    }
}
