import Foundation
import GRDB

// MARK: - Purchase Model
struct Purchase: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var productId: String
    var purchaseDate: Date
    var expirationDate: Date?
    var isActive: Bool
    var transactionId: String
    var originalTransactionId: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "purchases"
    
    init(id: String = UUID().uuidString,
         userId: String,
         productId: String,
         transactionId: String,
         originalTransactionId: String? = nil,
         expirationDate: Date? = nil) {
        self.id = id
        self.userId = userId
        self.productId = productId
        self.purchaseDate = Date()
        self.expirationDate = expirationDate
        self.isActive = true
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("productId", .text).notNull()
            t.column("purchaseDate", .datetime).notNull()
            t.column("expirationDate", .datetime)
            t.column("isActive", .boolean).notNull().defaults(to: true)
            t.column("transactionId", .text).notNull()
            t.column("originalTransactionId", .text)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            
            t.foreignKey(["userId"], references: User.databaseTableName, columns: ["id"])
        }
    }
}

// MARK: - Product Identifiers
enum ProductIdentifier: String, CaseIterable {
    // Individual Paths
    case christianity = "com.appofthedead.path.christianity"
    case islam = "com.appofthedead.path.islam"
    case buddhism = "com.appofthedead.path.buddhism"
    case hinduism = "com.appofthedead.path.hinduism"
    case ancientEgyptian = "com.appofthedead.path.egyptian"
    case greek = "com.appofthedead.path.greek"
    case norse = "com.appofthedead.path.norse"
    case shinto = "com.appofthedead.path.shinto"
    case zoroastrian = "com.appofthedead.path.zoroastrian"
    case sikhism = "com.appofthedead.path.sikhism"
    case aztecMictlan = "com.appofthedead.path.aztecmictlan"
    case taoism = "com.appofthedead.path.taoism"
    case mandaeism = "com.appofthedead.path.mandaeism"
    case wicca = "com.appofthedead.path.wicca"
    case bahai = "com.appofthedead.path.bahai"
    case tenrikyo = "com.appofthedead.path.tenrikyo"
    case aboriginalDreamtime = "com.appofthedead.path.aboriginaldreamtime"
    case nativeAmerican = "com.appofthedead.path.nativeamerican"
    case anthroposophy = "com.appofthedead.path.anthroposophy"
    case theosophy = "com.appofthedead.path.theosophy"
    case swedenborgian = "com.appofthedead.path.swedenborgian"
    
    // Oracle Access
    case oracleWisdom = "com.appofthedead.oracle.wisdom"
    
    // Ultimate Pack
    case ultimateEnlightenment = "com.appofthedead.ultimate"
    
    // Deity Packs
    case egyptianPantheon = "com.appofthedead.deities.egyptian"
    case greekGuides = "com.appofthedead.deities.greek"
    case easternWisdom = "com.appofthedead.deities.eastern"
    
    // Boosts
    case xpBoost7Days = "com.appofthedead.boost.xp7"
    
    var displayName: String {
        switch self {
        case .christianity: return "Christianity Path"
        case .islam: return "Islam Path"
        case .buddhism: return "Buddhism Path"
        case .hinduism: return "Hinduism Path"
        case .ancientEgyptian: return "Ancient Egyptian Path"
        case .greek: return "Greek Path"
        case .norse: return "Norse Path"
        case .shinto: return "Shinto Path"
        case .zoroastrian: return "Zoroastrian Path"
        case .oracleWisdom: return "Oracle Wisdom Pack"
        case .ultimateEnlightenment: return "Ultimate Enlightenment"
        case .egyptianPantheon: return "Death Masters Pack"
        case .greekGuides: return "Spirit Guides Pack"
        case .easternWisdom: return "Eastern Guardians Pack"
        case .xpBoost7Days: return "7-Day XP Boost"
        case .sikhism: return "Sikhism Path"
        case .aztecMictlan: return "Aztec Mictlan Path"
        case .taoism: return "Taoism Path"
        case .mandaeism: return "Mandaeism Path"
        case .wicca: return "Wicca Path"
        case .bahai: return "Baha'i Path"
        case .tenrikyo: return "Tenrikyo Path"
        case .aboriginalDreamtime: return "Aboriginal Dreamtime Path"
        case .nativeAmerican: return "Native American Visions Path"
        case .anthroposophy: return "Anthroposophy Path"
        case .theosophy: return "Theosophy Path"
        case .swedenborgian: return "Swedenborgian Visions Path"
        }
    }
    
    var description: String {
        switch self {
        case .christianity: return "Explore Heaven, Hell, and salvation through Christian teachings"
        case .islam: return "Discover Paradise, the Day of Judgment, and Islamic afterlife"
        case .buddhism: return "Learn about rebirth, Nirvana, and the Bardo states"
        case .hinduism: return "Understand karma, reincarnation, and moksha"
        case .ancientEgyptian: return "Journey through the Duat with ancient Egyptian wisdom"
        case .greek: return "Traverse Hades, Elysium, and Greek underworld myths"
        case .norse: return "Explore Valhalla, Hel, and Norse afterlife beliefs"
        case .shinto: return "Discover the spirit world and ancestor veneration"
        case .zoroastrian: return "Learn about the Bridge of Judgment and cosmic dualism"
        case .oracleWisdom: return "Unlimited consultations with all 21 divine guides"
        case .ultimateEnlightenment: return "All paths, unlimited Oracle, and exclusive features"
        case .egyptianPantheon: return "Consult Anubis, Kali, and Baron Samedi - Masters of Death"
        case .greekGuides: return "Speak with Hermes, Hecate, and Pachamama - Guides & Nature Spirits"
        case .easternWisdom: return "Connect with Yama, Meng Po, and Izanami - Eastern Afterlife Guardians"
        case .xpBoost7Days: return "Double your XP gains for 7 days"
        case .sikhism: return "Discover the cycle of rebirth and liberation through Sikh teachings"
        case .aztecMictlan: return "Follow the four-year journey through nine levels of Mictlan"
        case .taoism: return "Explore immortality and the harmonious afterlife realms"
        case .mandaeism: return "Ascend through the House of Life to the World of Light"
        case .wicca: return "Enter the Summerland and prepare for rebirth"
        case .bahai: return "Progress through spiritual worlds beyond physical death"
        case .tenrikyo: return "Return to the Jiba for spiritual rebirth"
        case .aboriginalDreamtime: return "Join ancestors in the eternal Dreamtime"
        case .nativeAmerican: return "Walk the Spirit Trail to the Happy Hunting Ground"
        case .anthroposophy: return "Navigate Kamaloka and ascend through spiritual spheres"
        case .theosophy: return "Experience Devachan and prepare for reincarnation"
        case .swedenborgian: return "Enter the World of Spirits and choose your eternal home"
        }
    }
    
    var beliefSystemId: String? {
        switch self {
        case .christianity: return "christianity"
        case .islam: return "islam"
        case .buddhism: return "buddhism"
        case .hinduism: return "hinduism"
        case .ancientEgyptian: return "egyptian-afterlife"
        case .greek: return "greek-underworld"
        case .norse: return "norse"
        case .shinto: return "shinto"
        case .zoroastrian: return "zoroastrianism"
        case .sikhism: return "sikhism"
        case .aztecMictlan: return "aztec-mictlan"
        case .taoism: return "taoism"
        case .mandaeism: return "mandaeism"
        case .wicca: return "wicca"
        case .bahai: return "bahai"
        case .tenrikyo: return "tenrikyo"
        case .aboriginalDreamtime: return "aboriginal-dreamtime"
        case .nativeAmerican: return "native-american-visions"
        case .anthroposophy: return "anthroposophy"
        case .theosophy: return "theosophy"
        case .swedenborgian: return "swedenborgian-visions"
        default: return nil
        }
    }
}

// MARK: - Entitlement Types
enum EntitlementType: String {
    case pathAccess = "path_access"
    case oracleUnlimited = "oracle_unlimited"
    case xpBoost = "xp_boost"
    case deityPack = "deity_pack"
    case ultimate = "ultimate"
}