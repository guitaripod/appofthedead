import Foundation
import GRDB

final class BookReaderViewModel {
    
    
    
    let book: Book
    private let userId: String
    private let databaseManager: DatabaseManager
    private var bookProgress: BookProgress
    var preferences: BookReadingPreferences
    
    var currentChapterIndex: Int = 0
    var currentChapter: Chapter? {
        guard currentChapterIndex < book.chapters.count else { return nil }
        return book.chapters[currentChapterIndex]
    }
    
    
    
    var onContentUpdate: (() -> Void)?
    var onProgressUpdate: (() -> Void)?
    var onPreferencesUpdate: (() -> Void)?
    
    
    
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
    
    // iPad support properties
    var chapterCount: Int {
        return book.chapters.count
    }
    
    var currentChapterText: String? {
        return currentChapter?.content
    }
    
    var chapters: [String] {
        return book.chapters.map { $0.content }
    }
    
    var hasBookmarkAtCurrentPosition: Bool {
        guard let chapterId = currentChapter?.id else { return false }
        return bookProgress.bookmarks.contains { $0.chapterId == chapterId }
    }
    
    var savedScrollPercentage: Double {
        return bookProgress.readingProgress
    }
    
    
    
    init(book: Book, userId: String, databaseManager: DatabaseManager = .shared) {
        self.book = book
        self.userId = userId
        self.databaseManager = databaseManager
        
        
        do {
            if let existingProgress = try databaseManager.getBookProgress(userId: userId, bookId: book.id) {
                self.bookProgress = existingProgress
                
                if let currentChapterId = existingProgress.currentChapterId,
                   let index = book.chapters.firstIndex(where: { $0.id == currentChapterId }) {
                    self.currentChapterIndex = index
                }
            } else {
                
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
        } catch {
            AppLogger.logError(error, context: "Loading book progress", logger: AppLogger.viewModel)
            
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
        }
        
        
        do {
            if let existingPrefs = try databaseManager.getBookReadingPreferences(userId: userId, bookId: book.id) {
                self.preferences = existingPrefs
            } else {
                self.preferences = BookReadingPreferences.defaultPreferences(userId: userId, bookId: book.id)
                
                if bookProgress.readingProgress > 0 {
                    
                    let chapterContribution = 1.0 / Double(book.chapters.count)
                    let progressInCurrentChapter = (bookProgress.readingProgress - (Double(currentChapterIndex) * chapterContribution)) / chapterContribution
                    self.preferences.scrollPosition = max(0, min(1, progressInCurrentChapter))
                }
                try databaseManager.saveBookReadingPreferences(preferences)
            }
        } catch {
            AppLogger.logError(error, context: "Loading reading preferences", logger: AppLogger.viewModel)
            
            self.preferences = BookReadingPreferences.defaultPreferences(userId: userId, bookId: book.id)
            
            
            if bookProgress.readingProgress > 0 {
                
                let chapterContribution = 1.0 / Double(book.chapters.count)
                let progressInCurrentChapter = (bookProgress.readingProgress - (Double(currentChapterIndex) * chapterContribution)) / chapterContribution
                self.preferences.scrollPosition = max(0, min(1, progressInCurrentChapter))
            }
        }
    }
    
    
    
    func loadBook() {
        loadCurrentChapter()
    }
    
    func loadCurrentChapter() {
        onContentUpdate?()
        
    }
    
    func goToPreviousChapter() {
        guard canGoPrevious else { return }
        currentChapterIndex -= 1
        bookProgress.currentChapterId = currentChapter?.id
        bookProgress.currentPosition = 0
        preferences.scrollPosition = 0
        
        onContentUpdate?()
        updateProgress()
    }
    
    func goToNextChapter() {
        guard canGoNext else { return }
        currentChapterIndex += 1
        bookProgress.currentChapterId = currentChapter?.id
        bookProgress.currentPosition = 0
        preferences.scrollPosition = 0
        
        onContentUpdate?()
        updateProgress()
    }
    
    func toggleBookmark() {
        guard let chapterId = currentChapter?.id else { return }
        
        if let index = bookProgress.bookmarks.firstIndex(where: { $0.chapterId == chapterId }) {
            
            bookProgress.bookmarks.remove(at: index)
        } else {
            
            let bookmark = Bookmark(
                id: UUID().uuidString,
                chapterId: chapterId,
                position: bookProgress.currentPosition,
                note: nil,
                createdAt: Date()
            )
            bookProgress.bookmarks.append(bookmark)
        }
        
        
    }
    
    func updateScrollPosition(_ position: Double) {
        preferences.scrollPosition = position
        updateCurrentPosition()
        updateProgress()
        
    }
    
    func updateCurrentChapter(_ chapterIndex: Int) {
        guard chapterIndex < book.chapters.count else { return }
        currentChapterIndex = chapterIndex
        bookProgress.currentChapterId = book.chapters[chapterIndex].id
        
    }
    
    func updateOverallProgress(_ overallProgress: Double) {
        
        bookProgress.readingProgress = overallProgress
        
        
        if overallProgress > 0.95 {
            if !bookProgress.isCompleted {
                bookProgress.isCompleted = true
                bookProgress.readingProgress = 1.0
                
                
                awardCompletionXP()
                
                saveProgress()
            }
        }
        
        
        onProgressUpdate?()
    }
    
    func updateFontSize(_ size: Double) {
        preferences.fontSize = size
        
        onPreferencesUpdate?()
    }
    
    
    func updatePreferences(with newPrefs: BookReadingPreferences) {
        self.preferences = newPrefs
        onPreferencesUpdate?()
    }
    
    func updateBrightness(_ brightness: Double) {
        preferences.brightness = brightness
        
    }
    
    func updateTTSSpeed(_ speed: Float) {
        preferences.ttsSpeed = Double(speed)
        
    }
    
    func updateAutoScrollSpeed(_ speed: Double) {
        preferences.autoScrollSpeed = speed
        
    }
    
    func incrementReadingTime() {
        bookProgress.totalReadingTime += 1
        
        
        if Int(bookProgress.totalReadingTime) % 10 == 0 {
            updateProgress()
        }
    }
    
    func saveProgress() {
        bookProgress.lastReadAt = Date()
        bookProgress.updatedAt = Date()
        
        do {
            try databaseManager.saveBookProgress(bookProgress)
        } catch {
            AppLogger.logError(error, context: "Saving book progress", logger: AppLogger.viewModel)
        }
    }
    
    func saveAll() {
        
        saveProgress()
        savePreferences()
        
    }
    
    
    
    private func updateProgress() {
        
        let totalChapters = Double(book.chapters.count)
        guard totalChapters > 0 else { return }
        
        
        let chaptersCompleted = Double(currentChapterIndex)
        
        
        let chapterProgress = max(0, min(1, preferences.scrollPosition))
        
        
        
        let progressPerChapter = 1.0 / totalChapters
        let totalProgress = (chaptersCompleted * progressPerChapter) + (chapterProgress * progressPerChapter)
        
        let newProgress = min(1.0, totalProgress)
        
        bookProgress.readingProgress = newProgress
        
        
        if currentChapterIndex == book.chapters.count - 1 && chapterProgress > 0.95 {
            if !bookProgress.isCompleted {
                bookProgress.isCompleted = true
                bookProgress.readingProgress = 1.0
                
                
                awardCompletionXP()
                
                saveProgress()
            }
        }
        
        
        
        onProgressUpdate?()
    }
    
    private func updateCurrentPosition() {
        
        
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
        let xpAmount = 500 

        do {
            guard let user = try databaseManager.getUser(by: userId) else {
                AppLogger.gamification.error("Failed to find user for book completion XP", metadata: ["userId": userId])
                return
            }
            try databaseManager.addXPToUser(user, xp: xpAmount)
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