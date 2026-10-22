import Foundation
import Testing

@testable import aotd

/// The book generation at launch runs on a background queue. These run the same types off the main thread, where
/// a type that slipped back onto the main actor traps instead of passing.
struct OffMainThreadTests {
    @Test func contentLoaderLoadsOffTheMainThread() async {
        let count = await Task.detached { ContentLoader().loadBeliefSystems().count }.value
        #expect(count > 0)
    }

    @Test func booksAreGeneratedAndSavedOffTheMainThread() async throws {
        let saved = try await Task.detached {
            let database = DatabaseManager(inMemory: true)
            let loader = ContentLoader()
            database.setContentLoader(loader)
            let generator = BookContentGenerator(databaseManager: database, contentLoader: loader)
            let beliefSystem = try #require(loader.loadBeliefSystems().first)
            let book = try generator.generateBook(for: beliefSystem)
            try database.saveBook(book)
            return book.beliefSystemId
        }.value
        #expect(!saved.isEmpty)
    }
}
