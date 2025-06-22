import Foundation
import GRDB

struct Book: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var beliefSystemId: String
    var title: String
    var author: String
    var coverImageName: String?
    var chapters: [Chapter]
    var totalWords: Int
    var estimatedReadingTime: Int // in minutes
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "books"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("beliefSystemId", .text).notNull()
            t.column("title", .text).notNull()
            t.column("author", .text).notNull()
            t.column("coverImageName", .text)
            t.column("chapters", .blob).notNull() // JSON encoded
            t.column("totalWords", .integer).notNull()
            t.column("estimatedReadingTime", .integer).notNull()
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}

struct Chapter: Codable {
    var id: String
    var bookId: String
    var chapterNumber: Int
    var title: String
    var content: String
    var wordCount: Int
}

struct BookProgress: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var userId: String
    var bookId: String
    var currentChapterId: String?
    var currentPosition: Int // Character position within chapter
    var readingProgress: Double // 0.0 to 1.0
    var totalReadingTime: TimeInterval // Total time spent reading
    var lastReadAt: Date?
    var isCompleted: Bool
    var bookmarks: [Bookmark]
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "book_progress"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("userId", .text).notNull()
            t.column("bookId", .text).notNull()
            t.column("currentChapterId", .text)
            t.column("currentPosition", .integer).notNull().defaults(to: 0)
            t.column("readingProgress", .double).notNull().defaults(to: 0.0)
            t.column("totalReadingTime", .double).notNull().defaults(to: 0.0)
            t.column("lastReadAt", .datetime)
            t.column("isCompleted", .boolean).notNull().defaults(to: false)
            t.column("bookmarks", .blob).notNull() // JSON encoded
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            
            t.uniqueKey(["userId", "bookId"])
        }
    }
}

struct Bookmark: Codable {
    var id: String
    var chapterId: String
    var position: Int
    var note: String?
    var createdAt: Date
}

// Reading preferences per book
struct BookReadingPreferences: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var userId: String
    var bookId: String
    var fontSize: Double
    var fontFamily: String
    var lineSpacing: Double
    var backgroundColor: String
    var textColor: String
    var scrollPosition: Double
    var brightness: Double
    var autoScrollSpeed: Double?
    var ttsSpeed: Float
    var ttsVoice: String?
    
    static let databaseTableName = "book_reading_preferences"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("userId", .text).notNull()
            t.column("bookId", .text).notNull()
            t.column("fontSize", .double).notNull()
            t.column("fontFamily", .text).notNull()
            t.column("lineSpacing", .double).notNull()
            t.column("backgroundColor", .text).notNull()
            t.column("textColor", .text).notNull()
            t.column("scrollPosition", .double).notNull().defaults(to: 0.0)
            t.column("brightness", .double).notNull().defaults(to: 1.0)
            t.column("autoScrollSpeed", .double)
            t.column("ttsSpeed", .double).notNull().defaults(to: 1.0)
            t.column("ttsVoice", .text)
            
            t.uniqueKey(["userId", "bookId"])
        }
    }
    
    static func defaultPreferences(userId: String, bookId: String) -> BookReadingPreferences {
        return BookReadingPreferences(
            id: UUID().uuidString,
            userId: userId,
            bookId: bookId,
            fontSize: 18.0,
            fontFamily: "Georgia",
            lineSpacing: 1.5,
            backgroundColor: "#FEFDF5", // Papyrus color
            textColor: "#2C1810",
            scrollPosition: 0.0,
            brightness: 1.0,
            autoScrollSpeed: nil,
            ttsSpeed: 1.0,
            ttsVoice: nil
        )
    }
}