import Foundation
import GRDB

struct UserAchievement: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var achievementId: String
    var unlockedAt: Date
    var progress: Double
    var isCompleted: Bool
    
    static let databaseTableName = "user_achievements"
    
    init(userId: String, achievementId: String, progress: Double = 0.0) {
        self.id = UUID().uuidString
        self.userId = userId
        self.achievementId = achievementId
        self.unlockedAt = Date()
        self.progress = progress
        self.isCompleted = progress >= 1.0
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        
    }
    
    mutating func updateProgress(_ newProgress: Double) {
        progress = min(1.0, max(0.0, newProgress))
        isCompleted = progress >= 1.0
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("achievementId", .text).notNull()
            t.column("unlockedAt", .datetime).notNull()
            t.column("progress", .double).notNull().defaults(to: 0.0)
            t.column("isCompleted", .boolean).notNull().defaults(to: false)
            
            t.foreignKey(["userId"], references: "users", columns: ["id"], onDelete: .cascade)
            t.uniqueKey(["userId", "achievementId"])
        }
    }
}

struct Achievement: Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let criteria: AchievementCriteria
    
    struct AchievementCriteria: Codable {
        let type: CriteriaType
        let value: CriteriaValue
        
        enum CriteriaType: String, Codable {
            case completePath = "completePath"
            case completeMultiplePaths = "completeMultiplePaths"
            case completeAllPaths = "completeAllPaths"
            case perfectMasteryTest = "perfectMasteryTest"
            case totalXP = "totalXP"
            case correctQuestions = "correctQuestions"
            case completeLesson = "completeLesson"
        }
        
        enum CriteriaValue: Codable {
            case string(String)
            case int(Int)
            case bool(Bool)
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let stringValue = try? container.decode(String.self) {
                    self = .string(stringValue)
                } else if let intValue = try? container.decode(Int.self) {
                    self = .int(intValue)
                } else if let boolValue = try? container.decode(Bool.self) {
                    self = .bool(boolValue)
                } else {
                    throw DecodingError.typeMismatch(CriteriaValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode CriteriaValue"))
                }
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let value):
                    try container.encode(value)
                case .int(let value):
                    try container.encode(value)
                case .bool(let value):
                    try container.encode(value)
                }
            }
        }
    }
}