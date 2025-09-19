import XCTest
@testable import aotd

final class BookReaderViewModelAdvancedTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var sut: BookReaderViewModel!
    var testBook: Book!
    var testUserId: String!
    
    override func setUp() {
        super.setUp()
        
        
        databaseManager = DatabaseManager(inMemory: true)
        testUserId = "test-user-123"
        
        
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
    
    
    
    func testDeferredSavingDoesNotSaveOnEveryUpdate() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        let initialReadingTime = sut.totalReadingTime
        
        
        sut.updateScrollPosition(0.25)
        sut.updateFontSize(20.0)
        sut.incrementReadingTime()
        sut.incrementReadingTime()
        sut.updateBrightness(0.8)
        
        
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        XCTAssertEqual(newViewModel.preferences.scrollPosition, 0.0, "Scroll position should not be saved")
        XCTAssertEqual(newViewModel.preferences.fontSize, 18.0, "Font size should not be saved")
        XCTAssertEqual(newViewModel.totalReadingTime, initialReadingTime, "Reading time should not be saved")
        XCTAssertEqual(newViewModel.preferences.brightness, 1.0, "Brightness should not be saved")
    }
    
    func testSaveAllPersistsAllChanges() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        sut.updateScrollPosition(0.75)
        sut.updateFontSize(22.0)
        sut.updateBrightness(0.6)
        sut.updateTTSSpeed(1.5)
        sut.updateAutoScrollSpeed(75.0)
        for _ in 0..<120 { 
            sut.incrementReadingTime()
        }
        
        
        sut.saveAll()
        
        
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        XCTAssertEqual(newViewModel.preferences.scrollPosition, 0.75, accuracy: 0.01)
        XCTAssertEqual(newViewModel.preferences.fontSize, 22.0)
        XCTAssertEqual(newViewModel.preferences.brightness, 0.6)
        XCTAssertEqual(newViewModel.preferences.ttsSpeed, 1.5)
        XCTAssertEqual(newViewModel.preferences.autoScrollSpeed, 75.0)
        XCTAssertEqual(newViewModel.totalReadingTime, 120.0)
    }
    
    
    
    func testProgressRestorationWithMissingPreferences() {
        
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
        
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        XCTAssertEqual(sut.currentChapterIndex, 2, "Should restore to chapter 3")
        XCTAssertEqual(sut.readingProgress, 0.45, accuracy: 0.01)
        XCTAssertEqual(sut.totalReadingTime, 600.0)
        
        
        
        
        
        XCTAssertEqual(sut.preferences.scrollPosition, 0.25, accuracy: 0.1)
    }
    
    func testProgressRestorationWithCorruptedData() {
        
        do {
            
            let corruptProgress = BookProgress(
                id: UUID().uuidString,
                userId: testUserId,
                bookId: testBook.id,
                currentChapterId: "non-existent-chapter",
                currentPosition: 99999,
                readingProgress: 2.5, 
                totalReadingTime: -100, 
                lastReadAt: Date(),
                isCompleted: false,
                bookmarks: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            try databaseManager.saveBookProgress(corruptProgress)
        } catch {
            
        }
        
        
        let viewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        
        XCTAssertEqual(viewModel.currentChapterIndex, 0, "Should default to first chapter with invalid chapter ID")
        
        XCTAssertEqual(viewModel.readingProgress, 2.5, accuracy: 0.01, "Progress is stored as-is")
        
        XCTAssertEqual(viewModel.totalReadingTime, -100.0, "Reading time is preserved as-is")
    }
    
    
    
    func testComplexChapterNavigationWithProgress() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        sut.updateScrollPosition(0.8) 
        XCTAssertEqual(sut.readingProgress, 0.16, accuracy: 0.01) 
        
        sut.goToNextChapter()
        sut.updateScrollPosition(0.3) 
        XCTAssertEqual(sut.readingProgress, 0.26, accuracy: 0.01) 
        
        sut.goToNextChapter()
        sut.updateScrollPosition(0.5) 
        XCTAssertEqual(sut.readingProgress, 0.5, accuracy: 0.01) 
        
        
        sut.goToPreviousChapter()
        XCTAssertEqual(sut.currentChapterIndex, 1)
        XCTAssertEqual(sut.preferences.scrollPosition, 0.0) 
        
        
        sut.saveAll()
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        XCTAssertEqual(newViewModel.currentChapterIndex, 1)
        
        
        XCTAssertEqual(newViewModel.readingProgress, 0.2, accuracy: 0.01) 
    }
    
    func testChapterBoundaryConditions() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        XCTAssertFalse(sut.canGoPrevious)
        sut.goToPreviousChapter()
        XCTAssertEqual(sut.currentChapterIndex, 0) 
        
        
        for _ in 0..<4 {
            sut.goToNextChapter()
        }
        
        XCTAssertEqual(sut.currentChapterIndex, 4) 
        XCTAssertFalse(sut.canGoNext)
        
        
        sut.goToNextChapter()
        XCTAssertEqual(sut.currentChapterIndex, 4) 
    }
    
    
    
    func testBookCompletionWithXPAward() {
        
        do {
            let createdUser = try databaseManager.createUser(name: "testuser", email: "test@example.com")
            testUserId = createdUser.id
        } catch {
            XCTFail("Failed to create user: \(error)")
        }
        
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        for _ in 0..<4 {
            sut.goToNextChapter()
        }
        
        
        sut.updateScrollPosition(0.96)
        
        
        let updatedUser = try? databaseManager.getUser(by: testUserId)
        XCTAssertNotNil(updatedUser)
        XCTAssertEqual(updatedUser?.totalXP, 500, "Should award 500 XP for book completion")
        
        
        let savedProgress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        XCTAssertNotNil(savedProgress)
        XCTAssertTrue(savedProgress?.isCompleted ?? false)
        XCTAssertEqual(savedProgress?.readingProgress ?? 0, 1.0)
    }
    
    func testBookCompletionOnlyAwardsXPOnce() {
        
        do {
            var createdUser = try databaseManager.createUser(name: "testuser", email: "test@example.com")
            testUserId = createdUser.id
            
            
            createdUser.totalXP = 1000
            createdUser.currentLevel = 5
            try databaseManager.updateUser(createdUser)
        } catch {
            XCTFail("Failed to create user: \(error)")
        }
        
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        for _ in 0..<4 {
            sut.goToNextChapter()
        }
        sut.updateScrollPosition(0.96)
        
        
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        
        newViewModel.updateScrollPosition(0.95)
        newViewModel.updateScrollPosition(0.97)
        
        
        let finalUser = try? databaseManager.getUser(by: testUserId)
        XCTAssertEqual(finalUser?.totalXP, 1500, "Should only award XP once (1000 initial + 500 completion)")
    }
    
    
    
    func testBookmarkPersistenceAcrossChapters() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        sut.toggleBookmark() 
        
        sut.goToNextChapter()
        sut.toggleBookmark() 
        
        sut.goToNextChapter()
        sut.toggleBookmark() 
        
        
        sut.saveAll()
        
        
        let progress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.bookmarks.count ?? 0, 3, "Should have 3 bookmarks saved")
        
        
        
    }
    
    
    
    func testReadingTimeAccumulation() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        for _ in 0..<300 { 
            sut.incrementReadingTime()
        }
        
        sut.saveAll()
        
        
        let secondSession = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(secondSession.totalReadingTime, 300.0)
        
        for _ in 0..<180 { 
            secondSession.incrementReadingTime()
        }
        
        secondSession.saveAll()
        
        
        let finalSession = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(finalSession.totalReadingTime, 480.0) 
    }
    
    
    
    func testPreferenceUpdateCallbacks() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        var fontSizeUpdateCount = 0
        var preferencesUpdateCount = 0
        
        sut.onPreferencesUpdate = {
            preferencesUpdateCount += 1
        }
        
        
        sut.updateFontSize(24.0)
        sut.updateBrightness(0.7)
        sut.updateTTSSpeed(1.2)
        sut.updateAutoScrollSpeed(60.0)
        
        
        XCTAssertEqual(preferencesUpdateCount, 1) 
    }
    
    
    
    func testEmptyBookHandling() {
        
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
        
        
        sut = BookReaderViewModel(book: emptyBook, userId: testUserId, databaseManager: databaseManager)
        
        
        XCTAssertNil(sut.currentChapter)
        XCTAssertEqual(sut.currentContent, "")
        XCTAssertEqual(sut.currentChapterTitle, "")
        XCTAssertFalse(sut.canGoPrevious)
        XCTAssertFalse(sut.canGoNext)
    }
    
    func testVeryLongReadingSession() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        for _ in 0..<36000 {
            sut.incrementReadingTime()
        }
        
        sut.saveAll()
        
        
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(newViewModel.totalReadingTime, 36000.0) 
    }
    
    func testProgressUpdateFrequency() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        var progressUpdateCount = 0
        sut.onProgressUpdate = {
            progressUpdateCount += 1
        }
        
        
        for i in 1...15 {
            sut.incrementReadingTime()
            
            
            if i % 10 == 0 {
                XCTAssertEqual(progressUpdateCount, i / 10)
            }
        }
    }
    
    
    
    func testOverallProgressUpdate() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        sut.updateOverallProgress(0.33)
        
        
        XCTAssertEqual(sut.readingProgress, 0.33, accuracy: 0.01)
        
        
        sut.updateOverallProgress(0.96)
        
        
        let progress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        XCTAssertTrue(progress?.isCompleted ?? false)
        XCTAssertEqual(progress?.readingProgress ?? 0, 1.0)
    }
}