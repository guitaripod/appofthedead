import Foundation

final class BookLibraryViewModel {
    
    // MARK: - Properties
    
    let userId: String
    private let databaseManager: DatabaseManager
    private let contentLoader: ContentLoader
    private var beliefSystems: [BeliefSystem] = []
    
    private(set) var availableBooks: [Book] = []
    private(set) var readingBooks: [(book: Book, progress: BookProgress)] = []
    private(set) var completedBooks: [(book: Book, progress: BookProgress)] = []
    
    // MARK: - Callbacks
    
    var onBooksUpdate: (() -> Void)?
    
    // MARK: - Initialization
    
    init(userId: String, databaseManager: DatabaseManager = .shared, contentLoader: ContentLoader = ContentLoader()) {
        self.userId = userId
        self.databaseManager = databaseManager
        self.contentLoader = contentLoader
        
        // Load belief systems
        self.beliefSystems = contentLoader.loadBeliefSystems()
    }
    
    // MARK: - Public Methods
    
    func loadBooks() {
        do {
            // Get all books with user progress
            let userBooks = try databaseManager.getUserBooks(userId: userId)
            
            // Categorize books
            var available: [Book] = []
            var reading: [(Book, BookProgress)] = []
            var completed: [(Book, BookProgress)] = []
            
            for (book, progress) in userBooks {
                if let progress = progress {
                    if progress.isCompleted {
                        completed.append((book, progress))
                    } else {
                        reading.append((book, progress))
                    }
                } else {
                    available.append(book)
                }
            }
            
            // Sort by various criteria
            self.availableBooks = available.sorted { $0.title < $1.title }
            self.readingBooks = reading.sorted { $0.1.lastReadAt ?? Date.distantPast > $1.1.lastReadAt ?? Date.distantPast }
            self.completedBooks = completed.sorted { $0.1.updatedAt > $1.1.updatedAt }
            
            onBooksUpdate?()
            
            AppLogger.viewModel.info("Loaded books", metadata: [
                "available": availableBooks.count,
                "reading": readingBooks.count,
                "completed": completedBooks.count
            ])
            
        } catch {
            AppLogger.logError(error, context: "Loading books", logger: AppLogger.viewModel)
        }
    }
    
    func refreshBooks() {
        loadBooks()
    }
    
    func beliefSystem(for book: Book) -> BeliefSystem? {
        return beliefSystems.first { $0.id == book.beliefSystemId }
    }
}