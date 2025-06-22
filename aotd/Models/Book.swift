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
    
    // GRDB database columns
    enum Columns: String, ColumnExpression {
        case id, beliefSystemId, title, author, coverImageName, chapters
        case totalWords, estimatedReadingTime, createdAt, updatedAt
    }
    
    // Standard initializer
    init(id: String, beliefSystemId: String, title: String, author: String,
         coverImageName: String? = nil, chapters: [Chapter], totalWords: Int,
         estimatedReadingTime: Int, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.beliefSystemId = beliefSystemId
        self.title = title
        self.author = author
        self.coverImageName = coverImageName
        self.chapters = chapters
        self.totalWords = totalWords
        self.estimatedReadingTime = estimatedReadingTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom encoding/decoding for chapters blob
    init(row: Row) throws {
        id = row[Columns.id]
        beliefSystemId = row[Columns.beliefSystemId]
        title = row[Columns.title]
        author = row[Columns.author]
        coverImageName = row[Columns.coverImageName]
        totalWords = row[Columns.totalWords]
        estimatedReadingTime = row[Columns.estimatedReadingTime]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        
        // Decode chapters from JSON blob
        let chaptersData: Data = row[Columns.chapters]
        chapters = try JSONDecoder().decode([Chapter].self, from: chaptersData)
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.beliefSystemId] = beliefSystemId
        container[Columns.title] = title
        container[Columns.author] = author
        container[Columns.coverImageName] = coverImageName
        container[Columns.totalWords] = totalWords
        container[Columns.estimatedReadingTime] = estimatedReadingTime
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        
        // Encode chapters to JSON blob
        container[Columns.chapters] = try JSONEncoder().encode(chapters)
    }
    
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
    
    // GRDB database columns
    enum Columns: String, ColumnExpression {
        case id, userId, bookId, currentChapterId, currentPosition
        case readingProgress, totalReadingTime, lastReadAt, isCompleted
        case bookmarks, createdAt, updatedAt
    }
    
    // Standard initializer
    init(id: String, userId: String, bookId: String, currentChapterId: String? = nil,
         currentPosition: Int = 0, readingProgress: Double = 0.0,
         totalReadingTime: TimeInterval = 0, lastReadAt: Date? = nil,
         isCompleted: Bool = false, bookmarks: [Bookmark] = [],
         createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.currentChapterId = currentChapterId
        self.currentPosition = currentPosition
        self.readingProgress = readingProgress
        self.totalReadingTime = totalReadingTime
        self.lastReadAt = lastReadAt
        self.isCompleted = isCompleted
        self.bookmarks = bookmarks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom encoding/decoding for bookmarks blob
    init(row: Row) throws {
        id = row[Columns.id]
        userId = row[Columns.userId]
        bookId = row[Columns.bookId]
        currentChapterId = row[Columns.currentChapterId]
        currentPosition = row[Columns.currentPosition]
        readingProgress = row[Columns.readingProgress]
        totalReadingTime = row[Columns.totalReadingTime]
        lastReadAt = row[Columns.lastReadAt]
        isCompleted = row[Columns.isCompleted]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        
        // Decode bookmarks from JSON blob
        let bookmarksData: Data = row[Columns.bookmarks]
        bookmarks = try JSONDecoder().decode([Bookmark].self, from: bookmarksData)
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.bookId] = bookId
        container[Columns.currentChapterId] = currentChapterId
        container[Columns.currentPosition] = currentPosition
        container[Columns.readingProgress] = readingProgress
        container[Columns.totalReadingTime] = totalReadingTime
        container[Columns.lastReadAt] = lastReadAt
        container[Columns.isCompleted] = isCompleted
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        
        // Encode bookmarks to JSON blob
        container[Columns.bookmarks] = try JSONEncoder().encode(bookmarks)
    }
    
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