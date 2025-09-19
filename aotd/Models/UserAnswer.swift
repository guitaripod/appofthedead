import Foundation
import GRDB

struct UserAnswer: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var questionId: String
    var userAnswer: String
    var isCorrect: Bool
    var timeSpent: TimeInterval
    var attemptedAt: Date
    var beliefSystemId: String
    var lessonId: String?
    var isMasteryTest: Bool
    
    static let databaseTableName = "user_answers"
    
    init(userId: String, questionId: String, userAnswer: String, isCorrect: Bool, 
         beliefSystemId: String, lessonId: String? = nil, isMasteryTest: Bool = false, timeSpent: TimeInterval = 0) {
        self.id = UUID().uuidString
        self.userId = userId
        self.questionId = questionId
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.attemptedAt = Date()
        self.beliefSystemId = beliefSystemId
        self.lessonId = lessonId
        self.isMasteryTest = isMasteryTest
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("questionId", .text).notNull()
            t.column("userAnswer", .text).notNull()
            t.column("isCorrect", .boolean).notNull()
            t.column("timeSpent", .double).notNull().defaults(to: 0.0)
            t.column("attemptedAt", .datetime).notNull()
            t.column("beliefSystemId", .text).notNull()
            t.column("lessonId", .text)
            t.column("isMasteryTest", .boolean).notNull().defaults(to: false)
            
            t.foreignKey(["userId"], references: "users", columns: ["id"], onDelete: .cascade)
        }
    }
}