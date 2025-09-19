import Foundation
import GRDB
import UIKit

struct Book: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var beliefSystemId: String
    var title: String
    var author: String
    var coverImageName: String?
    var chapters: [Chapter]
    var totalWords: Int
    var estimatedReadingTime: Int 
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "books"
    
    
    enum Columns: String, ColumnExpression {
        case id, beliefSystemId, title, author, coverImageName, chapters
        case totalWords, estimatedReadingTime, createdAt, updatedAt
    }
    
    
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
        
        
        container[Columns.chapters] = try JSONEncoder().encode(chapters)
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("beliefSystemId", .text).notNull()
            t.column("title", .text).notNull()
            t.column("author", .text).notNull()
            t.column("coverImageName", .text)
            t.column("chapters", .blob).notNull() 
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
    var currentPosition: Int 
    var readingProgress: Double 
    var totalReadingTime: TimeInterval 
    var lastReadAt: Date?
    var isCompleted: Bool
    var bookmarks: [Bookmark]
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "book_progress"
    
    
    enum Columns: String, ColumnExpression {
        case id, userId, bookId, currentChapterId, currentPosition
        case readingProgress, totalReadingTime, lastReadAt, isCompleted
        case bookmarks, createdAt, updatedAt
    }
    
    
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
            t.column("bookmarks", .blob).notNull() 
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


struct BookHighlight: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var userId: String
    var bookId: String
    var chapterId: String
    var startPosition: Int
    var endPosition: Int
    var highlightedText: String
    var color: String
    var note: String?
    var oracleConsultationId: String? 
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "book_highlights"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("userId", .text).notNull()
            t.column("bookId", .text).notNull()
            t.column("chapterId", .text).notNull()
            t.column("startPosition", .integer).notNull()
            t.column("endPosition", .integer).notNull()
            t.column("highlightedText", .text).notNull()
            t.column("color", .text).notNull()
            t.column("note", .text)
            t.column("oracleConsultationId", .text)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            
            t.foreignKey(["userId"], references: "users", columns: ["id"])
            t.foreignKey(["bookId"], references: "books", columns: ["id"])
            t.foreignKey(["oracleConsultationId"], references: "oracle_consultations", columns: ["id"])
        }
    }
}


struct ReadingTheme {
    let name: String
    let backgroundColor: UIColor
    let textColor: UIColor
    let highlightColor: UIColor
    let secondaryTextColor: UIColor
    let isDark: Bool
    
    static let themes: [String: ReadingTheme] = [
        "papyrus": ReadingTheme(
            name: "Papyrus",
            backgroundColor: UIColor(hex: "#FEFDF5")!,
            textColor: UIColor(hex: "#2C1810")!,
            highlightColor: UIColor(hex: "#FFD700")!,
            secondaryTextColor: UIColor(hex: "#5D4E37")!,
            isDark: false
        ),
        "sepia": ReadingTheme(
            name: "Sepia",
            backgroundColor: UIColor(hex: "#F4E8D0")!,
            textColor: UIColor(hex: "#3C2F26")!,
            highlightColor: UIColor(hex: "#E6A85C")!,
            secondaryTextColor: UIColor(hex: "#7A6A57")!,
            isDark: false
        ),
        "dark": ReadingTheme(
            name: "Dark",
            backgroundColor: UIColor(hex: "#1E1E1E")!,
            textColor: UIColor(hex: "#E0E0E0")!,
            highlightColor: UIColor(hex: "#4A90E2")!,
            secondaryTextColor: UIColor(hex: "#A0A0A0")!,
            isDark: true
        ),
        "midnight": ReadingTheme(
            name: "Midnight",
            backgroundColor: UIColor(hex: "#0F1419")!,
            textColor: UIColor(hex: "#EFEFEF")!,
            highlightColor: UIColor(hex: "#6B5CE6")!,
            secondaryTextColor: UIColor(hex: "#8899A6")!,
            isDark: true
        ),
        "cream": ReadingTheme(
            name: "Cream",
            backgroundColor: UIColor(hex: "#FFF8E7")!,
            textColor: UIColor(hex: "#333333")!,
            highlightColor: UIColor(hex: "#FFA500")!,
            secondaryTextColor: UIColor(hex: "#666666")!,
            isDark: false
        )
    ]
}


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
    var ttsSpeed: Double
    var ttsVoice: String?
    var textAlignment: String 
    var marginSize: Double 
    var theme: String 
    var showPageProgress: Bool
    var enableHyphenation: Bool
    var paragraphSpacing: Double
    var firstLineIndent: Double
    var highlightColor: String
    var pageTransitionStyle: String 
    var keepScreenOn: Bool
    var enableSwipeGestures: Bool
    var fontWeight: String 
    
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
            t.column("textAlignment", .text).notNull().defaults(to: "justified")
            t.column("marginSize", .double).notNull().defaults(to: 20.0)
            t.column("theme", .text).notNull().defaults(to: "papyrus")
            t.column("showPageProgress", .boolean).notNull().defaults(to: true)
            t.column("enableHyphenation", .boolean).notNull().defaults(to: true)
            t.column("paragraphSpacing", .double).notNull().defaults(to: 1.2)
            t.column("firstLineIndent", .double).notNull().defaults(to: 30.0)
            t.column("highlightColor", .text).notNull().defaults(to: "#FFD700")
            t.column("pageTransitionStyle", .text).notNull().defaults(to: "scroll")
            t.column("keepScreenOn", .boolean).notNull().defaults(to: true)
            t.column("enableSwipeGestures", .boolean).notNull().defaults(to: true)
            t.column("fontWeight", .text).notNull().defaults(to: "regular")
            
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
            backgroundColor: "#FEFDF5", 
            textColor: "#2C1810",
            scrollPosition: 0.0,
            brightness: 1.0,
            autoScrollSpeed: nil,
            ttsSpeed: 1.0,
            ttsVoice: nil,
            textAlignment: "justified",
            marginSize: 20.0,
            theme: "papyrus",
            showPageProgress: true,
            enableHyphenation: true,
            paragraphSpacing: 1.2,
            firstLineIndent: 30.0,
            highlightColor: "#FFD700",
            pageTransitionStyle: "scroll",
            keepScreenOn: true,
            enableSwipeGestures: true,
            fontWeight: "regular"
        )
    }
}
