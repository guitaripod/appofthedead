import XCTest
@testable import aotd

final class BookLibraryViewModelTests: XCTestCase {
    
    private var viewModel: BookLibraryViewModel!
    private var databaseManager: DatabaseManager!
    private var contentLoader: ContentLoader!
    
    override func setUp() {
        super.setUp()
        
        // Create test database
        databaseManager = try! DatabaseManager(inMemory: true)
        
        // Create test user
        var user = User(id: "test-user", name: "Test User", email: "test@example.com")
        try! databaseManager.dbQueue.write { db in
            try user.save(db)
        }
        
        contentLoader = ContentLoader()
        viewModel = BookLibraryViewModel(userId: user.id, databaseManager: databaseManager, contentLoader: contentLoader)
    }
    
    override func tearDown() {
        viewModel = nil
        databaseManager = nil
        contentLoader = nil
        super.tearDown()
    }
    
    func testBookUnlockStatusCheck() {
        // Given
        let chapter = Chapter(
            id: "ch1",
            bookId: "test-book",
            chapterNumber: 1,
            title: "Chapter 1",
            content: "Test content",
            wordCount: 100
        )
        
        let book = Book(
            id: "test-book",
            beliefSystemId: "christianity", // This should be locked by default
            title: "Test Book",
            author: "Test Author",
            chapters: [chapter],
            totalWords: 100,
            estimatedReadingTime: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        let isUnlocked = viewModel.isBookUnlocked(book)
        
        // Then
        XCTAssertFalse(isUnlocked, "Book for paid path should be locked")
    }
    
    func testFreePathBooksAreUnlocked() {
        // Given
        let chapter = Chapter(
            id: "ch1",
            bookId: "test-book",
            chapterNumber: 1,
            title: "Chapter 1",
            content: "Test content",
            wordCount: 100
        )
        
        let book = Book(
            id: "test-book",
            beliefSystemId: "judaism", // Judaism is free
            title: "Test Book",
            author: "Test Author",
            chapters: [chapter],
            totalWords: 100,
            estimatedReadingTime: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        let isUnlocked = viewModel.isBookUnlocked(book)
        
        // Then
        XCTAssertTrue(isUnlocked, "Book for free path should be unlocked")
    }
    
    func testLoadBooksCategorizesCorrectly() {
        // Given
        let expectation = expectation(description: "Books loaded")
        var booksLoaded = false
        
        viewModel.onBooksUpdate = {
            booksLoaded = true
            expectation.fulfill()
        }
        
        // Add some test books
        let chapter1 = Chapter(
            id: "ch1",
            bookId: "book1",
            chapterNumber: 1,
            title: "Chapter 1",
            content: "Test content",
            wordCount: 100
        )
        
        var book1 = Book(
            id: "book1",
            beliefSystemId: "judaism", // Free
            title: "Book 1",
            author: "Author 1",
            chapters: [chapter1],
            totalWords: 100,
            estimatedReadingTime: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let chapter2 = Chapter(
            id: "ch2",
            bookId: "book2",
            chapterNumber: 1,
            title: "Chapter 1",
            content: "Test content",
            wordCount: 150
        )
        
        var book2 = Book(
            id: "book2",
            beliefSystemId: "christianity", // Locked
            title: "Book 2",
            author: "Author 2",
            chapters: [chapter2],
            totalWords: 150,
            estimatedReadingTime: 45,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try! databaseManager.dbQueue.write { db in
            try book1.save(db)
            try book2.save(db)
        }
        
        // When
        viewModel.loadBooks()
        
        // Then
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            XCTAssertTrue(booksLoaded)
            
            // Available books should be sorted with unlocked first
            XCTAssertEqual(self.viewModel.availableBooks.count, 2)
            XCTAssertEqual(self.viewModel.availableBooks.first?.beliefSystemId, "judaism", "Unlocked book should be first")
            XCTAssertEqual(self.viewModel.availableBooks.last?.beliefSystemId, "christianity", "Locked book should be last")
        }
    }
    
    func testReadingBooksIncludeUnlockStatus() {
        // Given
        let expectation = expectation(description: "Books loaded")
        
        viewModel.onBooksUpdate = {
            expectation.fulfill()
        }
        
        // Add a book with progress
        let chapter = Chapter(
            id: "ch1",
            bookId: "book1",
            chapterNumber: 1,
            title: "Chapter 1",
            content: "Test content",
            wordCount: 100
        )
        
        var book = Book(
            id: "book1",
            beliefSystemId: "christianity", // Locked
            title: "Book 1",
            author: "Author 1",
            chapters: [chapter],
            totalWords: 100,
            estimatedReadingTime: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try! databaseManager.dbQueue.write { db in
            try book.save(db)
        }
        
        // Add reading progress
        var progress = BookProgress(
            id: UUID().uuidString,
            userId: "test-user",
            bookId: book.id,
            currentChapterId: chapter.id,
            currentPosition: 50,
            readingProgress: 0.5,
            totalReadingTime: 300,
            lastReadAt: Date(),
            isCompleted: false,
            bookmarks: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        try! databaseManager.dbQueue.write { db in
            try progress.save(db)
        }
        
        // When
        viewModel.loadBooks()
        
        // Then
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            
            XCTAssertEqual(self.viewModel.readingBooks.count, 1)
            let readingBook = self.viewModel.readingBooks.first
            XCTAssertNotNil(readingBook)
            XCTAssertEqual(readingBook?.book.id, book.id)
            XCTAssertFalse(readingBook?.isUnlocked ?? true, "Reading book for locked path should show as locked")
        }
    }
}