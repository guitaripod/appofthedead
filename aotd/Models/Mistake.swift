import Foundation
import GRDB

struct Mistake: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var beliefSystemId: String
    var lessonId: String?
    var questionId: String
    var incorrectAnswer: String
    var correctAnswer: String
    var reviewCount: Int
    var lastReviewed: Date?
    var nextReview: Date?
    var createdAt: Date
    var mastered: Bool
    
    static let databaseTableName = "mistakes"
    
    init(userId: String, beliefSystemId: String, lessonId: String? = nil, 
         questionId: String, incorrectAnswer: String, correctAnswer: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.beliefSystemId = beliefSystemId
        self.lessonId = lessonId
        self.questionId = questionId
        self.incorrectAnswer = incorrectAnswer
        self.correctAnswer = correctAnswer
        self.reviewCount = 0
        self.lastReviewed = nil
        self.nextReview = Date() // Available for immediate review
        self.createdAt = Date()
        self.mastered = false
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        // Called after insert
    }
    
    mutating func markReviewed(wasCorrect: Bool) {
        reviewCount += 1
        lastReviewed = Date()
        
        if wasCorrect {
            // Spaced repetition algorithm
            let intervals: [TimeInterval] = [
                60 * 60,        // 1 hour
                60 * 60 * 24,   // 1 day
                60 * 60 * 24 * 3,  // 3 days
                60 * 60 * 24 * 7,  // 1 week
                60 * 60 * 24 * 30  // 1 month
            ]
            
            let index = min(reviewCount - 1, intervals.count - 1)
            if index >= 0 {
                nextReview = Date().addingTimeInterval(intervals[index])
            }
            
            // Master after 5 successful reviews
            if reviewCount >= 5 {
                mastered = true
            }
        } else {
            // Reset on incorrect answer
            reviewCount = 0
            nextReview = Date() // Available immediately
            mastered = false
        }
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("beliefSystemId", .text).notNull()
            t.column("lessonId", .text)
            t.column("questionId", .text).notNull()
            t.column("incorrectAnswer", .text).notNull()
            t.column("correctAnswer", .text).notNull()
            t.column("reviewCount", .integer).notNull().defaults(to: 0)
            t.column("lastReviewed", .datetime)
            t.column("nextReview", .datetime)
            t.column("createdAt", .datetime).notNull()
            t.column("mastered", .boolean).notNull().defaults(to: false)
            
            t.foreignKey(["userId"], references: "users", columns: ["id"], onDelete: .cascade)
        }
    }
}

// MARK: - MistakeSession for tracking review sessions
struct MistakeSession: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var userId: String
    var beliefSystemId: String
    var startedAt: Date
    var completedAt: Date?
    var mistakeCount: Int
    var correctCount: Int
    var xpEarned: Int
    
    static let databaseTableName = "mistake_sessions"
    
    init(userId: String, beliefSystemId: String, mistakeCount: Int) {
        self.id = UUID().uuidString
        self.userId = userId
        self.beliefSystemId = beliefSystemId
        self.startedAt = Date()
        self.completedAt = nil
        self.mistakeCount = mistakeCount
        self.correctCount = 0
        self.xpEarned = 0
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        // Called after insert
    }
    
    mutating func complete(correctCount: Int, xpEarned: Int) {
        self.completedAt = Date()
        self.correctCount = correctCount
        self.xpEarned = xpEarned
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("userId", .text).notNull()
            t.column("beliefSystemId", .text).notNull()
            t.column("startedAt", .datetime).notNull()
            t.column("completedAt", .datetime)
            t.column("mistakeCount", .integer).notNull()
            t.column("correctCount", .integer).notNull().defaults(to: 0)
            t.column("xpEarned", .integer).notNull().defaults(to: 0)
            
            t.foreignKey(["userId"], references: "users", columns: ["id"], onDelete: .cascade)
        }
    }
}