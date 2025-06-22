import Foundation
import GRDB

final class BookReaderViewModel {
    
    // MARK: - Properties
    
    let book: Book
    private let userId: String
    private let databaseManager: DatabaseManager
    private var bookProgress: BookProgress
    private(set) var preferences: BookReadingPreferences
    
    var currentChapterIndex: Int = 0
    var currentChapter: Chapter? {
        guard currentChapterIndex < book.chapters.count else { return nil }
        return book.chapters[currentChapterIndex]
    }
    
    // MARK: - Callbacks
    
    var onContentUpdate: (() -> Void)?
    var onProgressUpdate: (() -> Void)?
    var onPreferencesUpdate: (() -> Void)?
    
    // MARK: - Computed Properties
    
    var currentContent: String {
        return currentChapter?.content ?? ""
    }
    
    var currentChapterTitle: String {
        return currentChapter?.title ?? ""
    }
    
    var readingProgress: Double {
        return bookProgress.readingProgress
    }
    
    var totalReadingTime: TimeInterval {
        return bookProgress.totalReadingTime
    }
    
    var canGoPrevious: Bool {
        return currentChapterIndex > 0
    }
    
    var canGoNext: Bool {
        return currentChapterIndex < book.chapters.count - 1
    }
    
    var hasBookmarkAtCurrentPosition: Bool {
        guard let chapterId = currentChapter?.id else { return false }
        return bookProgress.bookmarks.contains { $0.chapterId == chapterId }
    }
    
    // MARK: - Initialization
    
    init(book: Book, userId: String, databaseManager: DatabaseManager = .shared) {
        self.book = book
        self.userId = userId
        self.databaseManager = databaseManager
        
        // Load or create progress
        do {
            if let existingProgress = try databaseManager.getBookProgress(userId: userId, bookId: book.id) {
                self.bookProgress = existingProgress
                // Find current chapter index
                if let currentChapterId = existingProgress.currentChapterId,
                   let index = book.chapters.firstIndex(where: { $0.id == currentChapterId }) {
                    self.currentChapterIndex = index
                }
            } else {
                // Create new progress
                self.bookProgress = BookProgress(
                    id: UUID().uuidString,
                    userId: userId,
                    bookId: book.id,
                    currentChapterId: book.chapters.first?.id,
                    currentPosition: 0,
                    readingProgress: 0.0,
                    totalReadingTime: 0,
                    lastReadAt: nil,
                    isCompleted: false,
                    bookmarks: [],
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try databaseManager.saveBookProgress(bookProgress)
            }
            
            // Load or create preferences
            if let existingPrefs = try databaseManager.getBookReadingPreferences(userId: userId, bookId: book.id) {
                self.preferences = existingPrefs
            } else {
                self.preferences = BookReadingPreferences.defaultPreferences(userId: userId, bookId: book.id)
                try databaseManager.saveBookReadingPreferences(preferences)
            }
        } catch {
            AppLogger.logError(error, context: "Loading book progress", logger: AppLogger.viewModel)
            // Fallback to default values
            self.bookProgress = BookProgress(
                id: UUID().uuidString,
                userId: userId,
                bookId: book.id,
                currentChapterId: book.chapters.first?.id,
                currentPosition: 0,
                readingProgress: 0.0,
                totalReadingTime: 0,
                lastReadAt: nil,
                isCompleted: false,
                bookmarks: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            self.preferences = BookReadingPreferences.defaultPreferences(userId: userId, bookId: book.id)
        }
    }
    
    // MARK: - Public Methods
    
    func loadCurrentChapter() {
        onContentUpdate?()
        updateProgress()
    }
    
    func goToPreviousChapter() {
        guard canGoPrevious else { return }
        currentChapterIndex -= 1
        bookProgress.currentChapterId = currentChapter?.id
        bookProgress.currentPosition = 0
        saveProgress()
        onContentUpdate?()
        updateProgress()
    }
    
    func goToNextChapter() {
        guard canGoNext else { return }
        currentChapterIndex += 1
        bookProgress.currentChapterId = currentChapter?.id
        bookProgress.currentPosition = 0
        saveProgress()
        onContentUpdate?()
        updateProgress()
    }
    
    func toggleBookmark() {
        guard let chapterId = currentChapter?.id else { return }
        
        if let index = bookProgress.bookmarks.firstIndex(where: { $0.chapterId == chapterId }) {
            // Remove bookmark
            bookProgress.bookmarks.remove(at: index)
        } else {
            // Add bookmark
            let bookmark = Bookmark(
                id: UUID().uuidString,
                chapterId: chapterId,
                position: bookProgress.currentPosition,
                note: nil,
                createdAt: Date()
            )
            bookProgress.bookmarks.append(bookmark)
        }
        
        saveProgress()
    }
    
    func updateScrollPosition(_ position: Double) {
        preferences.scrollPosition = position
        updateCurrentPosition()
    }
    
    func updateFontSize(_ size: Double) {
        preferences.fontSize = size
        savePreferences()
        onPreferencesUpdate?()
    }
    
    func updateBrightness(_ brightness: Double) {
        preferences.brightness = brightness
        savePreferences()
    }
    
    func updateTTSSpeed(_ speed: Float) {
        preferences.ttsSpeed = speed
        savePreferences()
    }
    
    func updateAutoScrollSpeed(_ speed: Double) {
        preferences.autoScrollSpeed = speed
        savePreferences()
    }
    
    func incrementReadingTime() {
        bookProgress.totalReadingTime += 1
        
        // Update progress every 10 seconds
        if Int(bookProgress.totalReadingTime) % 10 == 0 {
            updateProgress()
        }
    }
    
    func saveProgress() {
        bookProgress.lastReadAt = Date()
        bookProgress.updatedAt = Date()
        
        do {
            try databaseManager.updateBookProgress(bookProgress)
        } catch {
            AppLogger.logError(error, context: "Saving book progress", logger: AppLogger.viewModel)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateProgress() {
        // Calculate overall reading progress
        let totalChapters = Double(book.chapters.count)
        guard totalChapters > 0 else { return }
        
        // Calculate how many full chapters have been read
        let chaptersCompleted = Double(currentChapterIndex)
        
        // Calculate progress within current chapter (0 to 1)
        let chapterProgress = max(0, min(1, preferences.scrollPosition))
        
        // Calculate total progress
        // Each chapter contributes 1/totalChapters to the overall progress
        let progressPerChapter = 1.0 / totalChapters
        let totalProgress = (chaptersCompleted * progressPerChapter) + (chapterProgress * progressPerChapter)
        
        bookProgress.readingProgress = min(1.0, totalProgress)
        
        // Check if book is completed
        if currentChapterIndex == book.chapters.count - 1 && chapterProgress > 0.95 {
            if !bookProgress.isCompleted {
                bookProgress.isCompleted = true
                bookProgress.readingProgress = 1.0
                
                // Award XP for completing the book
                awardCompletionXP()
            }
        }
        
        onProgressUpdate?()
    }
    
    private func updateCurrentPosition() {
        // This would calculate character position based on scroll position
        // For now, we'll use a simple percentage-based approach
        if let content = currentChapter?.content {
            let position = Int(Double(content.count) * preferences.scrollPosition)
            bookProgress.currentPosition = position
        }
    }
    
    private func savePreferences() {
        do {
            try databaseManager.updateBookReadingPreferences(preferences)
        } catch {
            AppLogger.logError(error, context: "Saving reading preferences", logger: AppLogger.viewModel)
        }
    }
    
    private func awardCompletionXP() {
        let xpAmount = 500 // Large XP reward for completing a book
        
        do {
            try databaseManager.addXPToUser(userId: userId, xp: xpAmount)
            try databaseManager.addXPToProgress(userId: userId, beliefSystemId: book.beliefSystemId, xp: xpAmount)
            
            AppLogger.gamification.info("Awarded XP for book completion", metadata: [
                "bookId": book.id,
                "xpAmount": xpAmount
            ])
        } catch {
            AppLogger.logError(error, context: "Awarding book completion XP", logger: AppLogger.gamification)
        }
    }
}