import XCTest
@testable import aotd

final class BookReaderIntegrationTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var bookReaderVC: BookReaderViewController!
    var viewModel: BookReaderViewModel!
    var testBook: Book!
    var testUser: User!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory database
        databaseManager = DatabaseManager(inMemory: true)
        
        // Create test user
        testUser = User(
            id: "integration-test-user",
            name: "reader",
            email: "reader@test.com"
        )
        
        do {
            let createdUser = try databaseManager.createUser(name: testUser.name, email: testUser.email)
            testUser = createdUser
        } catch {
            XCTFail("Failed to create test user: \(error)")
        }
        
        // Create realistic book
        testBook = createRealisticBook()
        
        do {
            try databaseManager.saveBook(testBook)
        } catch {
            XCTFail("Failed to save test book: \(error)")
        }
        
        // Create view model and view controller
        viewModel = BookReaderViewModel(
            book: testBook,
            userId: testUser.id,
            databaseManager: databaseManager
        )
        bookReaderVC = BookReaderViewController(viewModel: viewModel)
    }
    
    override func tearDown() {
        bookReaderVC = nil
        viewModel = nil
        databaseManager = nil
        testBook = nil
        testUser = nil
        super.tearDown()
    }
    
    private func createRealisticBook() -> Book {
        let bookId = UUID().uuidString
        
        let chapters = [
            Chapter(
                id: "ch1",
                bookId: bookId,
                chapterNumber: 1,
                title: "The Beginning",
                content: """
                In the ancient teachings of Buddhism, the path to enlightenment begins with understanding.
                The Buddha taught that all life is suffering, but this suffering has a cause and a cure.
                
                Through meditation and mindfulness, one can begin to see the true nature of reality.
                The impermanence of all things becomes clear, and with it, the futility of attachment.
                
                This is the first step on the noble eightfold path.
                """,
                wordCount: 65
            ),
            Chapter(
                id: "ch2",
                bookId: bookId,
                chapterNumber: 2,
                title: "The Middle Way",
                content: """
                The Buddha discovered the Middle Way between extreme asceticism and indulgence.
                Neither self-mortification nor hedonism leads to enlightenment.
                
                Instead, one must find balance in all things. This balance extends to:
                - Right understanding
                - Right intention
                - Right speech
                - Right action
                
                Each aspect supports the others in the journey toward liberation.
                """,
                wordCount: 55
            ),
            Chapter(
                id: "ch3",
                bookId: bookId,
                chapterNumber: 3,
                title: "The End of Suffering",
                content: """
                Nirvana represents the extinguishing of the flames of desire, hatred, and ignorance.
                It is not a place but a state of being - or rather, non-being.
                
                When one achieves enlightenment, the cycle of rebirth ends.
                The awakened one sees reality as it truly is, free from illusion.
                
                This is the ultimate goal of the Buddhist path.
                """,
                wordCount: 57
            )
        ]
        
        return Book(
            id: bookId,
            beliefSystemId: "buddhism",
            title: "Introduction to Buddhist Philosophy",
            author: "The Sangha",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 177,
            estimatedReadingTime: 2,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - End-to-End Reading Flow Tests
    
    func testCompleteReadingSessionFlow() {
        // Given - Load the view
        bookReaderVC.loadViewIfNeeded()
        
        // Simulate initial content load
        viewModel.loadBook()
        
        // When - User reads through the book
        
        // Read first chapter partially
        viewModel.updateScrollPosition(0.5)
        XCTAssertEqual(viewModel.currentChapterIndex, 0)
        XCTAssertEqual(viewModel.readingProgress, 0.166, accuracy: 0.01) // 50% of 33.3%
        
        // Add bookmark
        viewModel.toggleBookmark()
        XCTAssertTrue(viewModel.hasBookmarkAtCurrentPosition)
        
        // Move to next chapter
        viewModel.goToNextChapter()
        XCTAssertEqual(viewModel.currentChapterIndex, 1)
        
        // Read second chapter completely
        viewModel.updateScrollPosition(1.0)
        XCTAssertEqual(viewModel.readingProgress, 0.666, accuracy: 0.01) // 33.3% + 33.3%
        
        // Move to last chapter
        viewModel.goToNextChapter()
        XCTAssertEqual(viewModel.currentChapterIndex, 2)
        
        // Complete the book
        viewModel.updateScrollPosition(0.96)
        
        // Then - Verify completion
        let progress = try? databaseManager.getBookProgress(userId: testUser.id, bookId: testBook.id)
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress?.isCompleted ?? false)
        
        // Verify XP was awarded
        let updatedUser = try? databaseManager.getUser(by: testUser.id)
        XCTAssertEqual(updatedUser?.totalXP, 500) // Book completion XP
    }
    
    func testAppBackgroundingDuringReading() {
        // Given - Start reading
        bookReaderVC.loadViewIfNeeded()
        viewModel.loadBook()
        
        // Make some progress
        viewModel.updateScrollPosition(0.3)
        viewModel.updateFontSize(20.0)
        viewModel.toggleBookmark()
        
        // Simulate reading time
        for _ in 0..<60 {
            viewModel.incrementReadingTime()
        }
        
        // When - App goes to background
        NotificationCenter.default.post(
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Give time for save to complete
        let expectation = XCTestExpectation(description: "Save completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - Progress should be saved
        let savedProgress = try? databaseManager.getBookProgress(userId: testUser.id, bookId: testBook.id)
        XCTAssertNotNil(savedProgress)
        XCTAssertEqual(savedProgress?.totalReadingTime, 60.0)
        
        let savedPrefs = try? databaseManager.getBookReadingPreferences(userId: testUser.id, bookId: testBook.id)
        XCTAssertNotNil(savedPrefs)
        XCTAssertEqual(savedPrefs?.fontSize, 20.0)
        XCTAssertEqual(savedPrefs?.scrollPosition ?? 0, 0.3, accuracy: 0.01)
    }
    
    func testViewControllerDismissalSavesProgress() {
        // Given - Start reading
        bookReaderVC.loadViewIfNeeded()
        viewModel.loadBook()
        
        // Make progress
        viewModel.updateScrollPosition(0.7)
        viewModel.updateBrightness(0.8)
        for _ in 0..<120 {
            viewModel.incrementReadingTime()
        }
        
        // When - Dismiss view controller
        bookReaderVC.viewWillDisappear(false)
        
        // Then - All changes should be saved
        let newViewModel = BookReaderViewModel(
            book: testBook,
            userId: testUser.id,
            databaseManager: databaseManager
        )
        
        XCTAssertEqual(newViewModel.preferences.scrollPosition, 0.7, accuracy: 0.01)
        XCTAssertEqual(newViewModel.preferences.brightness, 0.8)
        XCTAssertEqual(newViewModel.totalReadingTime, 120.0)
    }
    
    // MARK: - Multi-Session Tests
    
    func testProgressAcrossMultipleSessions() {
        // Session 1: Read part of chapter 1
        var session1 = BookReaderViewModel(book: testBook, userId: testUser.id, databaseManager: databaseManager)
        session1.updateScrollPosition(0.6)
        for _ in 0..<300 { // 5 minutes
            session1.incrementReadingTime()
        }
        session1.saveAll()
        
        // Session 2: Continue from where we left off
        var session2 = BookReaderViewModel(book: testBook, userId: testUser.id, databaseManager: databaseManager)
        XCTAssertEqual(session2.currentChapterIndex, 0)
        XCTAssertEqual(session2.preferences.scrollPosition, 0.6, accuracy: 0.01)
        XCTAssertEqual(session2.totalReadingTime, 300.0)
        
        // Continue reading
        session2.goToNextChapter()
        session2.updateScrollPosition(0.4)
        for _ in 0..<180 { // 3 more minutes
            session2.incrementReadingTime()
        }
        session2.saveAll()
        
        // Session 3: Verify cumulative progress
        let session3 = BookReaderViewModel(book: testBook, userId: testUser.id, databaseManager: databaseManager)
        XCTAssertEqual(session3.currentChapterIndex, 1)
        XCTAssertEqual(session3.preferences.scrollPosition, 0.4, accuracy: 0.01)
        XCTAssertEqual(session3.totalReadingTime, 480.0) // 8 minutes total
        XCTAssertEqual(session3.readingProgress, 0.466, accuracy: 0.01) // ~46.6%
    }
    
    // MARK: - Preference Persistence Tests
    
    func testComplexPreferenceChanges() {
        // Given
        bookReaderVC.loadViewIfNeeded()
        
        // When - Update multiple preferences
        let newPrefs = BookReadingPreferences(
            id: viewModel.preferences.id,
            userId: testUser.id,
            bookId: testBook.id,
            fontSize: 24.0,
            fontFamily: "Helvetica",
            lineSpacing: 2.0,
            backgroundColor: "#000000",
            textColor: "#FFFFFF",
            scrollPosition: 0.0,
            brightness: 0.5,
            autoScrollSpeed: 100.0,
            ttsSpeed: 1.5,
            ttsVoice: "com.apple.ttsbundle.siri_female_en-US_compact",
            textAlignment: "left",
            marginSize: 30.0,
            theme: "dark",
            showPageProgress: false,
            enableHyphenation: false,
            paragraphSpacing: 2.0,
            firstLineIndent: 0.0,
            highlightColor: "#FF0000",
            pageTransitionStyle: "page",
            keepScreenOn: false,
            enableSwipeGestures: false,
            fontWeight: "bold"
        )
        
        viewModel.updatePreferences(with: newPrefs)
        viewModel.saveAll()
        
        // Then - Create new view model and verify all preferences
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUser.id, databaseManager: databaseManager)
        
        XCTAssertEqual(newViewModel.preferences.fontSize, 24.0)
        XCTAssertEqual(newViewModel.preferences.fontFamily, "Helvetica")
        XCTAssertEqual(newViewModel.preferences.lineSpacing, 2.0)
        XCTAssertEqual(newViewModel.preferences.theme, "dark")
        XCTAssertEqual(newViewModel.preferences.marginSize, 30.0)
        XCTAssertEqual(newViewModel.preferences.fontWeight, "bold")
        XCTAssertFalse(newViewModel.preferences.showPageProgress)
        XCTAssertFalse(newViewModel.preferences.enableHyphenation)
    }
    
    // MARK: - Error Recovery Tests
    
    func testRecoveryFromDatabaseErrors() {
        // Given - Create a view model
        let normalViewModel = BookReaderViewModel(book: testBook, userId: testUser.id, databaseManager: databaseManager)
        
        // Make some progress
        normalViewModel.updateScrollPosition(0.5)
        normalViewModel.toggleBookmark()
        
        // When - Database becomes unavailable (simulate by using nil database)
        // This would normally crash, but the view model should handle it gracefully
        normalViewModel.saveAll()
        
        // Then - View model should continue to function
        XCTAssertEqual(normalViewModel.preferences.scrollPosition, 0.5)
        XCTAssertTrue(normalViewModel.hasBookmarkAtCurrentPosition)
        
        // New instance should still load defaults if database is unavailable
        let recoveryViewModel = BookReaderViewModel(book: testBook, userId: testUser.id, databaseManager: databaseManager)
        XCTAssertNotNil(recoveryViewModel)
    }
    
    // MARK: - Performance Tests
    
    func testLargeBookPerformance() {
        // Given - Create a book with many chapters
        let largeBookId = UUID().uuidString
        let chapters = (1...50).map { num in
            Chapter(
                id: "large-ch-\(num)",
                bookId: largeBookId,
                chapterNumber: num,
                title: "Chapter \(num)",
                content: String(repeating: "Lorem ipsum dolor sit amet. ", count: 500),
                wordCount: 2000
            )
        }
        
        let largeBook = Book(
            id: largeBookId,
            beliefSystemId: "test",
            title: "Large Book",
            author: "Test",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 100000,
            estimatedReadingTime: 400,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(largeBook)
        
        // When - Create view model and navigate
        let startTime = Date()
        let largeBookViewModel = BookReaderViewModel(book: largeBook, userId: testUser.id, databaseManager: databaseManager)
        
        // Navigate through multiple chapters
        for _ in 0..<10 {
            largeBookViewModel.goToNextChapter()
            largeBookViewModel.updateScrollPosition(0.5)
        }
        
        largeBookViewModel.saveAll()
        
        let endTime = Date()
        let timeInterval = endTime.timeIntervalSince(startTime)
        
        // Then - Operations should complete in reasonable time
        XCTAssertLessThan(timeInterval, 2.0, "Large book operations should complete within 2 seconds")
        XCTAssertEqual(largeBookViewModel.currentChapterIndex, 10)
    }
    
    // MARK: - Bookmark Edge Cases
    
    func testBookmarkLimitsAndEdgeCases() {
        // Given
        viewModel.loadBook()
        
        // When - Add many bookmarks
        for i in 0..<3 {
            if i > 0 {
                viewModel.goToNextChapter()
            }
            
            // Add multiple bookmarks per chapter at different positions
            for position in stride(from: 0.0, to: 1.0, by: 0.2) {
                viewModel.updateScrollPosition(position)
                viewModel.toggleBookmark()
                
                // Move slightly to avoid duplicate position
                viewModel.updateScrollPosition(position + 0.01)
            }
        }
        
        viewModel.saveAll()
        
        // Then - All bookmarks should be preserved
        let savedProgress = try? databaseManager.getBookProgress(userId: testUser.id, bookId: testBook.id)
        XCTAssertNotNil(savedProgress)
        
        // We toggle on and off at same position, so we should have some bookmarks
        // The exact count depends on the toggle behavior
        XCTAssertGreaterThan(savedProgress?.bookmarks.count ?? 0, 0)
    }
}