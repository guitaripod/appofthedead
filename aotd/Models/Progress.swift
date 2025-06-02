import Foundation
import GRDB

struct Progress: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var beliefSystemId: String
    var lessonId: String?
    var questionId: String?
    var status: ProgressStatus
    var score: Int?
    var totalAttempts: Int
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum ProgressStatus: String, Codable, CaseIterable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case completed = "completed"
        case mastered = "mastered"
    }
    
    static let databaseTableName = "progress"
    
    init(userId: String, beliefSystemId: String, lessonId: String? = nil, questionId: String? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.beliefSystemId = beliefSystemId
        self.lessonId = lessonId
        self.questionId = questionId
        self.status = .notStarted
        self.score = nil
        self.totalAttempts = 0
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        // Called after insert
    }
    
    mutating func markCompleted(score: Int? = nil) {
        self.status = .completed
        self.score = score
        self.completedAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func incrementAttempts() {
        totalAttempts += 1
        updatedAt = Date()
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("beliefSystemId", .text).notNull()
            t.column("lessonId", .text)
            t.column("questionId", .text)
            t.column("status", .text).notNull()
            t.column("score", .integer)
            t.column("totalAttempts", .integer).notNull().defaults(to: 0)
            t.column("completedAt", .datetime)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            
            t.foreignKey(["userId"], references: "users", columns: ["id"], onDelete: .cascade)
            t.uniqueKey(["userId", "beliefSystemId", "lessonId", "questionId"])
        }
    }
}