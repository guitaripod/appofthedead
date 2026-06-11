import Foundation

final class MatchingQuestionViewModel: BaseQuestionViewModel {

    struct Match: Equatable {
        let left: String
        let right: String
    }

    let leftItems: [String]
    let rightItems: [String]

    private let correctRightByLeft: [String: String]

    init(
        question: Question,
        beliefSystem: BeliefSystem,
        currentQuestionIndex: Int,
        totalQuestions: Int,
        shuffler: ([String]) -> [String] = { $0.shuffled() }
    ) {
        let pairs = question.pairs ?? []
        self.leftItems = pairs.map(\.left)
        self.correctRightByLeft = Dictionary(
            pairs.map { ($0.left, $0.right) },
            uniquingKeysWith: { first, _ in first }
        )
        self.rightItems = Self.shuffledAvoidingSolvedOrder(pairs.map(\.right), shuffler: shuffler)
        super.init(
            question: question,
            beliefSystem: beliefSystem,
            currentQuestionIndex: currentQuestionIndex,
            totalQuestions: totalQuestions
        )
    }

    func isMatchCorrect(_ match: Match) -> Bool {
        correctRightByLeft[match.left] == match.right
    }

    func checkMatches(_ matches: [Match]) -> (isCorrect: Bool, explanation: String) {
        let isCorrect = matches.count == leftItems.count && matches.allSatisfy(isMatchCorrect)
        return (isCorrect, question.explanation)
    }

    /// A presented right column identical to the solved order would let users pass
    /// by tapping straight down both columns, so reshuffle until it differs and
    /// fall back to a deterministic swap for stubborn random streaks.
    private static func shuffledAvoidingSolvedOrder(
        _ items: [String],
        shuffler: ([String]) -> [String]
    ) -> [String] {
        guard items.count > 1 else { return items }
        var attempts = 0
        var result = shuffler(items)
        while result == items && attempts < 10 {
            result = shuffler(items)
            attempts += 1
        }
        if result == items {
            result.swapAt(0, 1)
        }
        return result
    }
}
