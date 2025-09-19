import XCTest
@testable import aotd

final class BookReaderViewModelTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var sut: BookReaderViewModel!
    var testBook: Book!
    var testUserId: String!
    
    override func setUp() {
        super.setUp()
        
        
        databaseManager = DatabaseManager(inMemory: true)
        testUserId = "test-user-123"
        
        
        let bookId = UUID().uuidString
        let chapters = [
            Chapter(
                id: UUID().uuidString,
                bookId: bookId,
                chapterNumber: 1,
                title: "Chapter 1",
                content: String(repeating: "Lorem ipsum dolor sit amet. ", count: 100),
                wordCount: 400
            ),
            Chapter(
                id: UUID().uuidString,
                bookId: bookId,
                chapterNumber: 2,
                title: "Chapter 2",
                content: String(repeating: "Consectetur adipiscing elit. ", count: 100),
                wordCount: 400
            )
        ]
        
        testBook = Book(
            id: bookId,
            beliefSystemId: "buddhism",
            title: "Test Book",
            author: "Test Author",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 800,
            estimatedReadingTime: 5,
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
    
    func testInitialBookProgressCreation() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        XCTAssertEqual(sut.currentChapterIndex, 0)
        XCTAssertEqual(sut.readingProgress, 0.0)
        XCTAssertEqual(sut.totalReadingTime, 0.0)
        XCTAssertFalse(sut.hasBookmarkAtCurrentPosition)
    }
    
    func testDeferredScrollPositionPersistence() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(sut.preferences.scrollPosition, 0.0, "Initial scroll position should be 0")
        
        
        sut.updateScrollPosition(0.5)
        XCTAssertEqual(sut.preferences.scrollPosition, 0.5, "Scroll position should be updated in memory")
        
        
        let newViewModelBeforeSave = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(newViewModelBeforeSave.preferences.scrollPosition, 0.0, "Scroll position should NOT be persisted without saveAll()")
        
        
        sut.saveAll()
        
        
        let newViewModelAfterSave = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(newViewModelAfterSave.preferences.scrollPosition, 0.5, "Scroll position should be persisted after saveAll()")
    }
    
    func testChapterNavigationResetsScrollPosition() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        sut.updateScrollPosition(0.5)
        
        
        sut.goToNextChapter()
        
        
        XCTAssertEqual(sut.currentChapterIndex, 1)
        XCTAssertEqual(sut.preferences.scrollPosition, 0.0)
    }
    
    func testReadingProgressCalculation() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        sut.updateScrollPosition(0.5)
        
        
        XCTAssertEqual(sut.readingProgress, 0.25, accuracy: 0.01)
        
        
        sut.goToNextChapter()
        sut.updateScrollPosition(0.5)
        
        
        XCTAssertEqual(sut.readingProgress, 0.75, accuracy: 0.01)
    }
    
    func testBookmarkToggle() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        sut.toggleBookmark()
        
        
        XCTAssertTrue(sut.hasBookmarkAtCurrentPosition)
        
        
        sut.toggleBookmark()
        
        
        XCTAssertFalse(sut.hasBookmarkAtCurrentPosition)
    }
    
    func testDeferredReadingTimePersistence() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        for _ in 0..<60 {
            sut.incrementReadingTime()
        }
        
        
        XCTAssertEqual(sut.totalReadingTime, 60.0)
        
        
        let newViewModelBeforeSave = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(newViewModelBeforeSave.totalReadingTime, 0.0, "Reading time should NOT be persisted without saveAll()")
        
        
        sut.saveAll()
        
        
        let newViewModelAfterSave = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        XCTAssertEqual(newViewModelAfterSave.totalReadingTime, 60.0, "Reading time should be persisted after saveAll()")
    }
    
    func testBookCompletionImmediateSave() {
        
        sut = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        
        
        do {
            _ = try databaseManager.createUser(name: "test", email: "test@test.com")
        } catch {
            
        }
        
        
        sut.goToNextChapter()
        sut.updateScrollPosition(0.96)
        
        
        let newViewModel = BookReaderViewModel(book: testBook, userId: testUserId, databaseManager: databaseManager)
        let progress = try? databaseManager.getBookProgress(userId: testUserId, bookId: testBook.id)
        
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress?.isCompleted ?? false, "Book completion should be saved immediately")
        XCTAssertEqual(progress?.readingProgress ?? 0, 1.0, accuracy: 0.01)
    }
}