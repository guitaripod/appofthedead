import Foundation
import GRDB

final class BookReaderViewModel {
    
    // MARK: - Properties
    
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
    
    var savedScrollPercentage: Double {
        return bookProgress.readingProgress
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
        } catch {
            AppLogger.logError(error, context: "Loading book progress", logger: AppLogger.viewModel)
            // Fallback to default progress
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
        
        // Load or create preferences separately
        do {
            if let existingPrefs = try databaseManager.getBookReadingPreferences(userId: userId, bookId: book.id) {
                self.preferences = existingPrefs
            } else {
                self.preferences = BookReadingPreferences.defaultPreferences(userId: userId, bookId: book.id)
                // Calculate initial scroll position from book progress
                if bookProgress.readingProgress > 0 {
                    // Estimate scroll position within current chapter based on overall progress
                    let chapterContribution = 1.0 / Double(book.chapters.count)
                    let progressInCurrentChapter = (bookProgress.readingProgress - (Double(currentChapterIndex) * chapterContribution)) / chapterContribution
                    self.preferences.scrollPosition = max(0, min(1, progressInCurrentChapter))
                }
                try databaseManager.saveBookReadingPreferences(preferences)
            }
        } catch {
            AppLogger.logError(error, context: "Loading reading preferences", logger: AppLogger.viewModel)
            // Fallback to default preferences but preserve scroll position from progress
            self.preferences = BookReadingPreferences.defaultPreferences(userId: userId, bookId: book.id)
            
            // Calculate scroll position from book progress when preferences fail to load
            if bookProgress.readingProgress > 0 {
                // Estimate scroll position within current chapter based on overall progress
                let chapterContribution = 1.0 / Double(book.chapters.count)
                let progressInCurrentChapter = (bookProgress.readingProgress - (Double(currentChapterIndex) * chapterContribution)) / chapterContribution
                self.preferences.scrollPosition = max(0, min(1, progressInCurrentChapter))
            }
        }
    }
    
    // MARK: - Public Methods
    
    func loadBook() {
        loadCurrentChapter()
    }
    
    func loadCurrentChapter() {
        onContentUpdate?()
        // Don't update progress here - let it be triggered after UI is ready
    }
    
    func goToPreviousChapter() {
        guard canGoPrevious else { return }
        currentChapterIndex -= 1
        bookProgress.currentChapterId = currentChapter?.id
        bookProgress.currentPosition = 0
        preferences.scrollPosition = 0
        // Removed immediate save - will save on background/dismiss
        onContentUpdate?()
        updateProgress()
    }
    
    func goToNextChapter() {
        guard canGoNext else { return }
        currentChapterIndex += 1
        bookProgress.currentChapterId = currentChapter?.id
        bookProgress.currentPosition = 0
        preferences.scrollPosition = 0
        // Removed immediate save - will save on background/dismiss
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
        
        // Removed immediate save - will save on background/dismiss
    }
    
    func updateScrollPosition(_ position: Double) {
        preferences.scrollPosition = position
        updateCurrentPosition()
        updateProgress()
        // Removed immediate save - will save on background/dismiss
    }
    
    func updateCurrentChapter(_ chapterIndex: Int) {
        guard chapterIndex < book.chapters.count else { return }
        currentChapterIndex = chapterIndex
        bookProgress.currentChapterId = book.chapters[chapterIndex].id
        // Don't reset scroll position - it will be updated by scrollViewDidScroll
    }
    
    func updateOverallProgress(_ overallProgress: Double) {
        // Directly update the book progress based on overall scroll position
        bookProgress.readingProgress = overallProgress
        
        // Check if book is completed
        if overallProgress > 0.95 {
            if !bookProgress.isCompleted {
                bookProgress.isCompleted = true
                bookProgress.readingProgress = 1.0
                
                // Award XP for completing the book
                awardCompletionXP()
                // Save immediately on completion to ensure XP is awarded
                saveProgress()
            }
        }
        
        // Removed immediate save for regular progress updates
        onProgressUpdate?()
    }
    
    func updateFontSize(_ size: Double) {
        preferences.fontSize = size
        // Removed immediate save - will save on background/dismiss
        onPreferencesUpdate?()
    }
    
    // Add methods to directly update preferences without saving
    func updatePreferences(with newPrefs: BookReadingPreferences) {
        self.preferences = newPrefs
        onPreferencesUpdate?()
    }
    
    func updateBrightness(_ brightness: Double) {
        preferences.brightness = brightness
        // Removed immediate save - will save on background/dismiss
    }
    
    func updateTTSSpeed(_ speed: Float) {
        preferences.ttsSpeed = Double(speed)
        // Removed immediate save - will save on background/dismiss
    }
    
    func updateAutoScrollSpeed(_ speed: Double) {
        preferences.autoScrollSpeed = speed
        // Removed immediate save - will save on background/dismiss
    }
    
    func incrementReadingTime() {
        bookProgress.totalReadingTime += 1
        
        // Update progress UI every 10 seconds, but don't save to DB
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
        // Save both progress and preferences together
        saveProgress()
        savePreferences()
        
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
        
        let newProgress = min(1.0, totalProgress)
        
        bookProgress.readingProgress = newProgress
        
        // Check if book is completed
        if currentChapterIndex == book.chapters.count - 1 && chapterProgress > 0.95 {
            if !bookProgress.isCompleted {
                bookProgress.isCompleted = true
                bookProgress.readingProgress = 1.0
                
                // Award XP for completing the book
                awardCompletionXP()
                // Save immediately on completion to ensure XP is awarded
                saveProgress()
            }
        }
        
        // Removed automatic save on progress change
        
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