import Foundation
import GRDB

struct OracleConsultation: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var deityId: String
    var consultationDate: Date
    var messageCount: Int
    var createdAt: Date
    
    static let databaseTableName = "oracle_consultations"
    
    init(id: String = UUID().uuidString,
         userId: String,
         deityId: String,
         messageCount: Int = 1) {
        self.id = id
        self.userId = userId
        self.deityId = deityId
        self.consultationDate = Date()
        self.messageCount = messageCount
        self.createdAt = Date()
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("deityId", .text).notNull()
            t.column("consultationDate", .datetime).notNull()
            t.column("messageCount", .integer).notNull().defaults(to: 1)
            t.column("createdAt", .datetime).notNull()
            
            t.foreignKey(["userId"], references: User.databaseTableName, columns: ["id"])
        }
    }
    
    
    static func getConsultationCount(for userId: String, deityId: String, in db: Database) throws -> Int {
        return try OracleConsultation
            .filter(Column("userId") == userId)
            .filter(Column("deityId") == deityId)
            .fetchCount(db)
    }
    
    
    static func getTotalConsultations(for userId: String, in db: Database) throws -> Int {
        return try OracleConsultation
            .filter(Column("userId") == userId)
            .fetchCount(db)
    }
    
    
    static func canConsultForFree(userId: String, deityId: String, in db: Database) throws -> Bool {
        let count = try getConsultationCount(for: userId, deityId: deityId, in: db)
        return count < 3
    }
}