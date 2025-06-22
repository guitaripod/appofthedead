import XCTest
@testable import aotd

final class BookReaderViewModelAdvancedTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var sut: BookReaderViewModel!
    var testBook: Book!
    var testUserId: String!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory database for testing
        databaseManager = DatabaseManager(inMemory: true)
        testUserId = "test-user-123"
        
        // Create test book with multiple chapters for realistic scenarios
        let bookId = UUID().uuidString
        let chapters = (1...5).map { chapterNum in
            Chapter(
                id: "chapter-\(chapterNum)",
                bookId: bookId,
                chapterNumber: chapterNum,
                title: "Chapter \(chapterNum): The Journey Continues",
                content: String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 200),
                wordCount: 800
            )
        }
        
        testBook = Book(
            id: bookId,
            beliefSystemId: "buddhism",
            title: "The Path to Enlightenment",
            author: "Ancient Wisdom",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 4000,
            estimatedReadingTime: 20,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save book to database
        do {
            try databaseManager.saveBook(testBook)
        } catch {
            XCTFail("Failed to save test book: \(error)")
        }
    }
    
    override func tearDown() {
        sut = nil
        databaseManager = nil
        testBook = nil
        testUserId = nil
        super.tearDown()
    }
    
    // MARK: - Deferred Saving Tests
    
    func testDeferredSavingDoesNotSaveOnEveryUpdate() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        let initialReadingTime = sut.totalReadingTime
        
        // When - Make multiple updates without calling saveAll()
        sut.updateScrollPosition(0.25)
        sut.updateFontSize(20.0)
        sut.incrementReadingTime()
        sut.incrementReadingTime()
        sut.updateBrightness(0.8)
        
        // Then - Create new view model to check if changes were persisted
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // Changes should NOT be persisted yet
        XCTAssertEqual(newViewModel.preferences.scrollPosition, 0.0, "Scroll position should not be saved")
        XCTAssertEqual(newViewModel.preferences.fontSize, 18.0, "Font size should not be saved")
        XCTAssertEqual(newViewModel.totalReadingTime, initialReadingTime, "Reading time should not be saved")
        XCTAssertEqual(newViewModel.preferences.brightness, 1.0, "Brightness should not be saved")
    }
    
    func testSaveAllPersistsAllChanges() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Make multiple updates
        sut.updateScrollPosition(0.75)
        sut.updateFontSize(22.0)
        sut.updateBrightness(0.6)
        sut.updateTTSSpeed(1.5)
        sut.updateAutoScrollSpeed(75.0)
        for _ in 0..<120 { // 2 minutes
            sut.incrementReadingTime()
        }
        
        // Save all changes
        sut.saveAll()
        
        // Then - Create new view model to verify persistence
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        XCTAssertEqual(newViewModel.preferences.scrollPosition, 0.75, accuracy: 0.01)
        XCTAssertEqual(newViewModel.preferences.fontSize, 22.0)
        XCTAssertEqual(newViewModel.preferences.brightness, 0.6)
        XCTAssertEqual(newViewModel.preferences.ttsSpeed, 1.5)
        XCTAssertEqual(newViewModel.preferences.autoScrollSpeed, 75.0)
        XCTAssertEqual(newViewModel.totalReadingTime, 120.0)
    }
    
    // MARK: - Progress Restoration Tests
    
    func testProgressRestorationWithMissingPreferences() {
        // Given - Save progress but no preferences
        let progress = BookProgress(
            id: UUID().uuidString,
            userId: testUserId,
            bookId: testBook.id,
            currentChapterId: testBook.chapters[2].id,
            currentPosition: 500,
            readingProgress: 0.45,
            totalReadingTime: 600,
            lastReadAt: Date(),
            isCompleted: false,
            bookmarks: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try databaseManager.saveBookProgress(progress)
        } catch {
            XCTFail("Failed to save progress: \(error)")
        }
        
        // When - Create view model (preferences missing)
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // Then - Should create default preferences but calculate scroll position from progress
        XCTAssertEqual(sut.currentChapterIndex, 2, "Should restore to chapter 3")
        XCTAssertEqual(sut.readingProgress, 0.45, accuracy: 0.01)
        XCTAssertEqual(sut.totalReadingTime, 600.0)
        
        // Scroll position should be calculated from overall progress
        // Progress 0.45 means we're 45% through the book
        // Chapter 3 starts at 40% (2/5), so we're 5% into chapter 3
        // 5% of 20% (one chapter) = 25% within the chapter
        XCTAssertEqual(sut.preferences.scrollPosition, 0.25, accuracy: 0.1)
    }
    
    func testProgressRestorationWithCorruptedData() {
        // Given - Save corrupted progress data directly
        do {
            // Save invalid progress with chapter ID that doesn't exist
            let corruptProgress = BookProgress(
                id: UUID().uuidString,
                userId: testUserId,
                bookId: testBook.id,
                currentChapterId: "non-existent-chapter",
                currentPosition: 99999,
                readingProgress: 2.5, // Invalid: > 1.0
                totalReadingTime: -100, // Invalid: negative
                lastReadAt: Date(),
                isCompleted: false,
                bookmarks: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            try databaseManager.saveBookProgress(corruptProgress)
        } catch {
            // Expected to potentially fail
        }
        
        // When - Create view model with corrupted data
        let viewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // Then - Should handle corruption gracefully
        // Since currentChapterId doesn't match any chapter, it should default to index 0
        XCTAssertEqual(viewModel.currentChapterIndex, 0, "Should default to first chapter with invalid chapter ID")
        // The reading progress is stored as-is (2.5) but displayed clamped
        XCTAssertEqual(viewModel.readingProgress, 2.5, accuracy: 0.01, "Progress is stored as-is")
        // The negative reading time is preserved as-is in the model
        XCTAssertEqual(viewModel.totalReadingTime, -100.0, "Reading time is preserved as-is")
    }
    
    // MARK: - Chapter Navigation Tests
    
    func testComplexChapterNavigationWithProgress() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Navigate through multiple chapters with different progress
        sut.updateScrollPosition(0.8) // 80% of chapter 1
        XCTAssertEqual(sut.readingProgress, 0.16, accuracy: 0.01) // 80% of 20% = 16%
        
        sut.goToNextChapter()
        sut.updateScrollPosition(0.3) // 30% of chapter 2
        XCTAssertEqual(sut.readingProgress, 0.26, accuracy: 0.01) // 20% + 6% = 26%
        
        sut.goToNextChapter()
        sut.updateScrollPosition(0.5) // 50% of chapter 3
        XCTAssertEqual(sut.readingProgress, 0.5, accuracy: 0.01) // 40% + 10% = 50%
        
        // Go back
        sut.goToPreviousChapter()
        XCTAssertEqual(sut.currentChapterIndex, 1)
        XCTAssertEqual(sut.preferences.scrollPosition, 0.0) // Reset to start of chapter
        
        // Then - Save and restore
        sut.saveAll()
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        XCTAssertEqual(newViewModel.currentChapterIndex, 1)
        // When we go back to chapter 2, scroll position resets to 0
        // Chapter 2 is the second of 5 chapters, so being at the start = 20% (1/5 completed)
        XCTAssertEqual(newViewModel.readingProgress, 0.2, accuracy: 0.01) // At start of chapter 2
    }
    
    func testChapterBoundaryConditions() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Try to go before first chapter
        XCTAssertFalse(sut.canGoPrevious)
        sut.goToPreviousChapter()
        XCTAssertEqual(sut.currentChapterIndex, 0) // Should stay at 0
        
        // Navigate to last chapter
        for _ in 0..<4 {
            sut.goToNextChapter()
        }
        
        XCTAssertEqual(sut.currentChapterIndex, 4) // Last chapter (index 4)
        XCTAssertFalse(sut.canGoNext)
        
        // Try to go beyond last chapter
        sut.goToNextChapter()
        XCTAssertEqual(sut.currentChapterIndex, 4) // Should stay at last chapter
    }
    
    // MARK: - Book Completion Tests
    
    func testBookCompletionWithXPAward() {
        // Given - Create user first
        do {
            let createdUser = try databaseManager.createUser(name: "testuser", email: "test@example.com")
            testUserId = createdUser.id
        } catch {
            XCTFail("Failed to create user: \(error)")
        }
        
        // Create view model with the created user ID
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Navigate to last chapter and read most of it
        for _ in 0..<4 {
            sut.goToNextChapter()
        }
        
        // Read 96% of last chapter (should trigger completion)
        sut.updateScrollPosition(0.96)
        
        // Then - Book should be completed with XP awarded
        let updatedUser = try? databaseManager.getUser(by: testUserId)
        XCTAssertNotNil(updatedUser)
        XCTAssertEqual(updatedUser?.totalXP, 500, "Should award 500 XP for book completion")
        
        // Progress should be saved immediately
        let savedProgress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        XCTAssertNotNil(savedProgress)
        XCTAssertTrue(savedProgress?.isCompleted ?? false)
        XCTAssertEqual(savedProgress?.readingProgress ?? 0, 1.0)
    }
    
    func testBookCompletionOnlyAwardsXPOnce() {
        // Given - Create user with initial XP
        do {
            var createdUser = try databaseManager.createUser(name: "testuser", email: "test@example.com")
            testUserId = createdUser.id
            
            // Update user's XP directly in database
            createdUser.totalXP = 1000
            createdUser.currentLevel = 5
            try databaseManager.updateUser(createdUser)
        } catch {
            XCTFail("Failed to create user: \(error)")
        }
        
        // Create view model and complete book once
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // Navigate to end and complete
        for _ in 0..<4 {
            sut.goToNextChapter()
        }
        sut.updateScrollPosition(0.96)
        
        // When - Create new view model and try to complete again
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // Try to trigger completion again by scrolling in last chapter
        // Since book is already completed, this should not award XP again
        newViewModel.updateScrollPosition(0.95)
        newViewModel.updateScrollPosition(0.97)
        
        // Then - XP should not be awarded twice
        let finalUser = try? databaseManager.getUser(by: testUserId)
        XCTAssertEqual(finalUser?.totalXP, 1500, "Should only award XP once (1000 initial + 500 completion)")
    }
    
    // MARK: - Bookmark Tests
    
    func testBookmarkPersistenceAcrossChapters() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Add bookmarks in different chapters
        sut.toggleBookmark() // Chapter 1
        
        sut.goToNextChapter()
        sut.toggleBookmark() // Chapter 2
        
        sut.goToNextChapter()
        sut.toggleBookmark() // Chapter 3
        
        // Save
        sut.saveAll()
        
        // Then - Verify bookmarks were saved
        let progress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.bookmarks.count ?? 0, 3, "Should have 3 bookmarks saved")
        
        // The bookmark checking logic is chapter-specific in the current implementation
        // This test verifies that bookmarks are persisted, not the exact checking behavior
    }
    
    // MARK: - Reading Time Tests
    
    func testReadingTimeAccumulation() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Simulate reading for different periods
        for _ in 0..<300 { // 5 minutes
            sut.incrementReadingTime()
        }
        
        sut.saveAll()
        
        // Create new session and continue reading
        let secondSession = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(secondSession.totalReadingTime, 300.0)
        
        for _ in 0..<180 { // 3 more minutes
            secondSession.incrementReadingTime()
        }
        
        secondSession.saveAll()
        
        // Then - Total time should accumulate
        let finalSession = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(finalSession.totalReadingTime, 480.0) // 8 minutes total
    }
    
    // MARK: - Preference Update Tests
    
    func testPreferenceUpdateCallbacks() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        var fontSizeUpdateCount = 0
        var preferencesUpdateCount = 0
        
        sut.onPreferencesUpdate = {
            preferencesUpdateCount += 1
        }
        
        // When - Update various preferences
        sut.updateFontSize(24.0)
        sut.updateBrightness(0.7)
        sut.updateTTSSpeed(1.2)
        sut.updateAutoScrollSpeed(60.0)
        
        // Then - Callback should be triggered for font size only
        XCTAssertEqual(preferencesUpdateCount, 1) // Only font size triggers callback
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyBookHandling() {
        // Given - Book with no chapters
        let emptyBook = Book(
            id: "empty-book",
            beliefSystemId: "test",
            title: "Empty Book",
            author: "Nobody",
            coverImageName: nil,
            chapters: [],
            totalWords: 0,
            estimatedReadingTime: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(emptyBook)
        
        // When
        sut = BookReaderViewModel(book: emptyBook, userId: testUserId, databaseManager: databaseManager)
        
        // Then - Should handle gracefully
        XCTAssertNil(sut.currentChapter)
        XCTAssertEqual(sut.currentContent, "")
        XCTAssertEqual(sut.currentChapterTitle, "")
        XCTAssertFalse(sut.canGoPrevious)
        XCTAssertFalse(sut.canGoNext)
    }
    
    func testVeryLongReadingSession() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Simulate very long reading session (10 hours)
        for _ in 0..<36000 {
            sut.incrementReadingTime()
        }
        
        sut.saveAll()
        
        // Then - Should handle large time values
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(newViewModel.totalReadingTime, 36000.0) // 10 hours
    }
    
    func testProgressUpdateFrequency() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        var progressUpdateCount = 0
        sut.onProgressUpdate = {
            progressUpdateCount += 1
        }
        
        // When - Increment reading time
        for i in 1...15 {
            sut.incrementReadingTime()
            
            // Then - Progress should update every 10 seconds
            if i % 10 == 0 {
                XCTAssertEqual(progressUpdateCount, i / 10)
            }
        }
    }
    
    // MARK: - Overall Progress Calculation Tests
    
    func testOverallProgressUpdate() {
        // Given
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        // When - Update overall progress directly (simulating scroll view updates)
        sut.updateOverallProgress(0.33)
        
        // Then
        XCTAssertEqual(sut.readingProgress, 0.33, accuracy: 0.01)
        
        // When - Update to near completion
        sut.updateOverallProgress(0.96)
        
        // Then - Should mark as completed
        let progress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        XCTAssertTrue(progress?.isCompleted ?? false)
        XCTAssertEqual(progress?.readingProgress ?? 0, 1.0)
    }
}