import Foundation
import GRDB

/// The reading position and preferences of each book, kept beside the rest of the store so a book's
/// screen never reaches into the manager's migration code.
extension DatabaseManager {

    func getBookProgress(userId: String, bookId: String) throws -> BookProgress? {
        return try dbQueue.read { db in
            try BookProgress
                .filter(Column("userId") == userId)
                .filter(Column("bookId") == bookId)
                .fetchOne(db)
        }
    }
    
    func saveBookProgress(_ progress: BookProgress) throws {
        var mutableProgress = progress
        try dbQueue.write { db in
            
            if let existing = try BookProgress
                .filter(Column("userId") == progress.userId)
                .filter(Column("bookId") == progress.bookId)
                .fetchOne(db) {
                
                mutableProgress.id = existing.id
                try mutableProgress.update(db)
            } else {
                
                try mutableProgress.insert(db)
            }
        }
    }
    
    func updateBookProgress(_ progress: BookProgress) throws {
        var mutableProgress = progress
        mutableProgress.updatedAt = Date()
        try dbQueue.write { db in
            try mutableProgress.update(db)
        }
    }
    
    func getBookReadingPreferences(userId: String, bookId: String) throws -> BookReadingPreferences? {
        return try dbQueue.read { db in
            try BookReadingPreferences
                .filter(Column("userId") == userId)
                .filter(Column("bookId") == bookId)
                .fetchOne(db)
        }
    }
    
    func saveBookReadingPreferences(_ preferences: BookReadingPreferences) throws {
        var mutablePrefs = preferences
        try dbQueue.write { db in
            
            if let existing = try BookReadingPreferences
                .filter(Column("userId") == preferences.userId)
                .filter(Column("bookId") == preferences.bookId)
                .fetchOne(db) {
                
                mutablePrefs.id = existing.id
                try mutablePrefs.update(db)
            } else {
                
                try mutablePrefs.insert(db)
            }
        }
    }
    
    func updateBookReadingPreferences(_ preferences: BookReadingPreferences) throws {
        try saveBookReadingPreferences(preferences)
    }
}
