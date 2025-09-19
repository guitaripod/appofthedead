import XCTest
@testable import aotd

final class BookLibraryViewModelTests: XCTestCase {
    
    private var viewModel: BookLibraryViewModel!
    private var databaseManager: DatabaseManager!
    private var contentLoader: ContentLoader!
    
    override func setUp() {
        super.setUp()
        
        
        databaseManager = try! DatabaseManager(inMemory: true)
        
        
        var user = User()
        user.id = "test-user"
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
            beliefSystemId: "christianity", 
            title: "Test Book",
            author: "Test Author",
            chapters: [chapter],
            totalWords: 100,
            estimatedReadingTime: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        
        let isUnlocked = viewModel.isBookUnlocked(book)
        
        
        XCTAssertFalse(isUnlocked, "Book for paid path should be locked")
    }
    
    func testFreePathBooksAreUnlocked() {
        
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
            beliefSystemId: "judaism", 
            title: "Test Book",
            author: "Test Author",
            chapters: [chapter],
            totalWords: 100,
            estimatedReadingTime: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        
        let isUnlocked = viewModel.isBookUnlocked(book)
        
        
        XCTAssertTrue(isUnlocked, "Book for free path should be unlocked")
    }
    
    func testLoadBooksCategorizesCorrectly() {
        
        let expectation = expectation(description: "Books loaded")
        var booksLoaded = false
        
        viewModel.onBooksUpdate = {
            booksLoaded = true
            expectation.fulfill()
        }
        
        
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
            beliefSystemId: "judaism", 
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
            beliefSystemId: "christianity", 
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
        
        
        viewModel.loadBooks()
        
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            XCTAssertTrue(booksLoaded)
            
            
            XCTAssertEqual(self.viewModel.availableBooks.count, 2)
            XCTAssertEqual(self.viewModel.availableBooks.first?.beliefSystemId, "judaism", "Unlocked book should be first")
            XCTAssertEqual(self.viewModel.availableBooks.last?.beliefSystemId, "christianity", "Locked book should be last")
        }
    }
    
    func testReadingBooksIncludeUnlockStatus() {
        
        let expectation = expectation(description: "Books loaded")
        
        viewModel.onBooksUpdate = {
            expectation.fulfill()
        }
        
        
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
            beliefSystemId: "christianity", 
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
        
        
        viewModel.loadBooks()
        
        
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