import Foundation
@testable import aotd

@MainActor enum FreePathExpectation {
    /// Judaism is free forever; the Dia de los Muertos event path joins it only while `FreePaths` reports it open, so the expected set follows the event window instead of freezing a date in the tests.
    static func unlockedIds() -> Set<String> {
        var ids: Set<String> = ["judaism"]
        let eventPathId = PathGiftEvent.diaDeLosMuertos2026.beliefSystemId
        if FreePaths.shared.isOpen(eventPathId) {
            ids.insert(eventPathId)
        }
        return ids
    }
}
