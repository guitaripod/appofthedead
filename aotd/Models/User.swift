import Foundation
import GRDB

struct User: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var totalXP: Int
    var currentLevel: Int
    var streakDays: Int
    var lastActiveDate: Date?
    var createdAt: Date
    var updatedAt: Date

    static let databaseTableName = "users"

    init() {
        self.id = UUID().uuidString
        self.totalXP = 0
        self.currentLevel = 1
        self.streakDays = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    mutating func didInsert(with rowID: Int64, for column: String?) {
    }

    mutating func addXP(_ points: Int) {
        totalXP += points
        currentLevel = calculateLevel(from: totalXP)
        updatedAt = Date()
    }

    private func calculateLevel(from xp: Int) -> Int {
        return max(1, xp / 100 + 1)
    }

    var currentStreak: Int {
        return streakDays
    }

    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("totalXP", .integer).notNull().defaults(to: 0)
            t.column("currentLevel", .integer).notNull().defaults(to: 1)
            t.column("streakDays", .integer).notNull().defaults(to: 0)
            t.column("lastActiveDate", .datetime)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}