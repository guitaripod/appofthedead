import XCTest
@testable import aotd

final class BookReaderEdgeCaseTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        databaseManager = DatabaseManager(inMemory: true)
    }
    
    override func tearDown() {
        databaseManager = nil
        super.tearDown()
    }
    
    
    
    func testBookWithEmptyChapters() {
        
        let bookId = UUID().uuidString
        let emptyChapters = [
            Chapter(id: "ch1", bookId: bookId, chapterNumber: 1, title: "", content: "", wordCount: 0),
            Chapter(id: "ch2", bookId: bookId, chapterNumber: 2, title: "Title Only", content: "", wordCount: 0),
            Chapter(id: "ch3", bookId: bookId, chapterNumber: 3, title: "Spaces Only", content: "   \n\n   ", wordCount: 0)
        ]
        
        let emptyBook = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Empty Content Book",
            author: "Nobody",
            coverImageName: nil,
            chapters: emptyChapters,
            totalWords: 0,
            estimatedReadingTime: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(emptyBook)
        
        
        let viewModel = BookReaderViewModel(book: emptyBook, userId: "test-user", databaseManager: databaseManager)
        
        
        XCTAssertEqual(viewModel.currentContent, "")
        XCTAssertEqual(viewModel.currentChapterTitle, "")
        
        
        viewModel.goToNextChapter()
        XCTAssertEqual(viewModel.currentChapterTitle, "Title Only")
        XCTAssertEqual(viewModel.currentContent, "")
        
        viewModel.goToNextChapter()
        XCTAssertEqual(viewModel.currentChapterTitle, "Spaces Only")
        XCTAssertEqual(viewModel.currentContent.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }
    
    func testBookWithVeryLongChapterTitles() {
        
        let bookId = UUID().uuidString
        let longTitle = String(repeating: "Very Long Title ", count: 100)
        
        let chapters = [
            Chapter(
                id: "ch1",
                bookId: bookId,
                chapterNumber: 1,
                title: longTitle,
                content: "Short content",
                wordCount: 2
            )
        ]
        
        let book = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Book with Long Titles",
            author: "Test",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 2,
            estimatedReadingTime: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(book)
        
        
        let viewModel = BookReaderViewModel(book: book, userId: "test-user", databaseManager: databaseManager)
        
        
        XCTAssertEqual(viewModel.currentChapterTitle, longTitle)
        XCTAssertGreaterThan(viewModel.currentChapterTitle.count, 1000)
    }
    
    
    
    func testProgressWithSingleCharacterChapter() {
        
        let bookId = UUID().uuidString
        let chapters = [
            Chapter(id: "ch1", bookId: bookId, chapterNumber: 1, title: "One", content: "A", wordCount: 1),
            Chapter(id: "ch2", bookId: bookId, chapterNumber: 2, title: "Two", content: "B", wordCount: 1)
        ]
        
        let minimalBook = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Minimal Book",
            author: "Test",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 2,
            estimatedReadingTime: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(minimalBook)
        
        
        let viewModel = BookReaderViewModel(book: minimalBook, userId: "test-user", databaseManager: databaseManager)
        
        
        viewModel.updateScrollPosition(1.0) 
        
        
        XCTAssertEqual(viewModel.readingProgress, 0.5, accuracy: 0.01) 
        
        
        viewModel.goToNextChapter()
        viewModel.updateScrollPosition(0.5)
        
        XCTAssertEqual(viewModel.readingProgress, 0.75, accuracy: 0.01) 
    }
    
    func testProgressWithInvalidScrollPositions() {
        
        let book = createTestBook()
        let viewModel = BookReaderViewModel(book: book, userId: "test-user", databaseManager: databaseManager)
        
        
        viewModel.updateScrollPosition(-0.5) 
        XCTAssertEqual(viewModel.preferences.scrollPosition, -0.5) 
        
        viewModel.updateScrollPosition(2.5) 
        XCTAssertEqual(viewModel.preferences.scrollPosition, 2.5) 
        
        
        let progress = viewModel.readingProgress
        XCTAssertGreaterThanOrEqual(progress, 0.0)
        XCTAssertLessThanOrEqual(progress, 1.0)
    }
    
    
    
    func testConcurrentBookmarkOperations() {
        
        let book = createTestBook()
        let viewModel = BookReaderViewModel(book: book, userId: "test-user", databaseManager: databaseManager)
        
        
        
        for _ in 0..<10 {
            viewModel.toggleBookmark()
        }
        
        
        
        XCTAssertFalse(viewModel.hasBookmarkAtCurrentPosition, "Even number of toggles should result in no bookmark")
    }
    
    
    
    func testVeryLargeChapterContent() {
        
        let bookId = UUID().uuidString
        let hugeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 10000) 
        
        let chapters = [
            Chapter(
                id: "huge-ch",
                bookId: bookId,
                chapterNumber: 1,
                title: "Huge Chapter",
                content: hugeContent,
                wordCount: 50000
            )
        ]
        
        let hugeBook = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Huge Content Book",
            author: "Test",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 50000,
            estimatedReadingTime: 200,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(hugeBook)
        
        
        let viewModel = BookReaderViewModel(book: hugeBook, userId: "test-user", databaseManager: databaseManager)
        
        
        XCTAssertGreaterThan(viewModel.currentContent.count, 250000)
        
        
        viewModel.updateScrollPosition(0.5)
        XCTAssertEqual(viewModel.readingProgress, 0.5, accuracy: 0.01)
    }
    
    
    
    func testBooksWithSpecialCharacters() {
        
        let bookId = UUID().uuidString
        let chapters = [
            Chapter(
                id: "special-ch",
                bookId: bookId,
                chapterNumber: 1,
                title: "Special Characters: émojis 😀🎉, symbols ©®™, math ∑∏∫",
                content: """
                Unicode test: 你好世界 🌍
                Right-to-left: العربية עברית
                Combining marks: é (e + ́) vs é
                Zero-width chars: a‌b‍c
                Control chars: \u{200B}\u{200C}\u{200D}
                """,
                wordCount: 20
            )
        ]
        
        let specialBook = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Special 📚 Book",
            author: "Test 👤",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 20,
            estimatedReadingTime: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(specialBook)
        
        
        let viewModel = BookReaderViewModel(book: specialBook, userId: "test-user", databaseManager: databaseManager)
        
        
        XCTAssertTrue(viewModel.currentChapterTitle.contains("😀"))
        XCTAssertTrue(viewModel.currentContent.contains("🌍"))
        XCTAssertTrue(viewModel.currentContent.contains("العربية"))
        
        
        viewModel.toggleBookmark()
        XCTAssertTrue(viewModel.hasBookmarkAtCurrentPosition)
    }
    
    
    
    func testRapidChapterNavigation() {
        
        let book = createMultiChapterBook(chapterCount: 10)
        let viewModel = BookReaderViewModel(book: book, userId: "test-user", databaseManager: databaseManager)
        
        
        for _ in 0..<5 {
            viewModel.goToNextChapter()
        }
        for _ in 0..<3 {
            viewModel.goToPreviousChapter()
        }
        
        
        XCTAssertEqual(viewModel.currentChapterIndex, 2) 
        
        
        for _ in 0..<20 {
            viewModel.goToPreviousChapter() 
        }
        XCTAssertEqual(viewModel.currentChapterIndex, 0)
        
        for _ in 0..<20 {
            viewModel.goToNextChapter() 
        }
        XCTAssertEqual(viewModel.currentChapterIndex, 9) 
    }
    
    func testCompletionEdgeCases() {
        
        let userId: String
        do {
            let user = try databaseManager.createAnonymousUser()
            userId = user.id
        } catch {
            XCTFail("Failed to create user: \(error)")
            return
        }
        
        let book = createTestBook()
        let viewModel = BookReaderViewModel(book: book, userId: userId, databaseManager: databaseManager)
        
        
        viewModel.goToNextChapter() 
        viewModel.updateScrollPosition(0.96)
        
        
        let progress = try? databaseManager.getBookProgress(userId: userId, bookId: book.id)
        XCTAssertTrue(progress?.isCompleted ?? false, "Book should be marked as completed")
        
        
        let finalUser = try? databaseManager.getUser(by: userId)
        XCTAssertEqual(finalUser?.totalXP, 500, "Should award 500 XP for book completion")
    }
    
    
    
    private func createTestBook() -> Book {
        let bookId = UUID().uuidString
        let chapters = [
            Chapter(id: "ch1", bookId: bookId, chapterNumber: 1, title: "Chapter 1", content: "Content 1", wordCount: 100),
            Chapter(id: "ch2", bookId: bookId, chapterNumber: 2, title: "Chapter 2", content: "Content 2", wordCount: 100)
        ]
        
        let book = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Test Book",
            author: "Test Author",
            coverImageName: nil,
            chapters: chapters,
            totalWords: 200,
            estimatedReadingTime: 2,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(book)
        return book
    }
    
    private func createMultiChapterBook(chapterCount: Int) -> Book {
        let bookId = UUID().uuidString
        let chapters = (1...chapterCount).map { num in
            Chapter(
                id: "ch\(num)",
                bookId: bookId,
                chapterNumber: num,
                title: "Chapter \(num)",
                content: "Content for chapter \(num)",
                wordCount: 100
            )
        }
        
        let book = Book(
            id: bookId,
            beliefSystemId: "test",
            title: "Multi-Chapter Book",
            author: "Test Author",
            coverImageName: nil,
            chapters: chapters,
            totalWords: chapterCount * 100,
            estimatedReadingTime: chapterCount * 2,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try? databaseManager.saveBook(book)
        return book
    }
}