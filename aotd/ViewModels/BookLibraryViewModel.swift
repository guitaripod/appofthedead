import Foundation

final class BookLibraryViewModel {
    
    
    
    let userId: String
    private let databaseManager: DatabaseManager
    private let contentLoader: ContentLoader
    private var beliefSystems: [BeliefSystem] = []
    private var user: User?
    
    private(set) var availableBooks: [Book] = []
    private(set) var readingBooks: [(book: Book, progress: BookProgress, isUnlocked: Bool)] = []
    private(set) var completedBooks: [(book: Book, progress: BookProgress, isUnlocked: Bool)] = []
    
    
    
    var onBooksUpdate: (() -> Void)?
    
    
    
    init(userId: String, databaseManager: DatabaseManager = .shared, contentLoader: ContentLoader = ContentLoader()) {
        self.userId = userId
        self.databaseManager = databaseManager
        self.contentLoader = contentLoader
        
        
        self.beliefSystems = contentLoader.loadBeliefSystems()
    }
    
    
    
    func loadBooks() {
        
        user = databaseManager.fetchUser()
        
        do {
            
            let userBooks = try databaseManager.getUserBooks(userId: userId)
            
            
            var available: [Book] = []
            var reading: [(Book, BookProgress, Bool)] = []
            var completed: [(Book, BookProgress, Bool)] = []
            
            for (book, progress) in userBooks {
                let isUnlocked = checkIfBookUnlocked(book)
                
                if let progress = progress {
                    if progress.isCompleted {
                        completed.append((book, progress, isUnlocked))
                    } else {
                        reading.append((book, progress, isUnlocked))
                    }
                } else {
                    available.append(book)
                }
            }
            
            
            self.availableBooks = available.sorted { book1, book2 in
                let unlocked1 = checkIfBookUnlocked(book1)
                let unlocked2 = checkIfBookUnlocked(book2)
                
                
                if unlocked1 != unlocked2 {
                    return unlocked1
                }
                
                return book1.title < book2.title
            }
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
    
    func isBookUnlocked(_ book: Book) -> Bool {
        return checkIfBookUnlocked(book)
    }
    
    
    
    private func checkIfBookUnlocked(_ book: Book) -> Bool {
        
        
        if StoreManager.shared.hasPathAccess(book.beliefSystemId) {
            return true
        }
        
        
        guard let user = user else { return false }
        return user.hasPathAccess(beliefSystemId: book.beliefSystemId)
    }
}