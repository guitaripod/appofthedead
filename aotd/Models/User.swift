import Foundation
import GRDB

struct User: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var name: String
    var email: String
    var totalXP: Int
    var currentLevel: Int
    var streakDays: Int
    var lastActiveDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "users"
    
    init(id: String = UUID().uuidString, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.totalXP = 0
        self.currentLevel = 1
        self.streakDays = 0
        self.lastActiveDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        // Called after insert
    }
    
    mutating func addXP(_ points: Int) {
        totalXP += points
        currentLevel = calculateLevel(from: totalXP)
        updatedAt = Date()
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        // Every 100 XP = 1 level
        return max(1, xp / 100 + 1)
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull()
            t.column("email", .text).notNull().unique()
            t.column("totalXP", .integer).notNull().defaults(to: 0)
            t.column("currentLevel", .integer).notNull().defaults(to: 1)
            t.column("streakDays", .integer).notNull().defaults(to: 0)
            t.column("lastActiveDate", .datetime)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}