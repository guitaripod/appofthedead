import Foundation
import AppOfTheDeadCore

final class MatchingQuestionViewModel: BaseQuestionViewModel {

    struct Match: Equatable {
        let left: String
        let right: String
    }

    let leftItems: [String]
    let rightItems: [String]

    private let correctRightByLeft: [String: String]
    private var submittedMatches: [Match]?

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

    /// The item of the right column that belongs with `left`.
    func correctPartner(for left: String) -> String? {
        correctRightByLeft[left]
    }

    func checkMatches(_ matches: [Match]) -> (isCorrect: Bool, explanation: String) {
        submittedMatches = matches
        let isCorrect = matches.count == leftItems.count && matches.allSatisfy(isMatchCorrect)
        return (isCorrect, question.explanation)
    }

    /// Checks `matches` and describes the result, one pair per line in the order of the left column.
    func outcome(for matches: [Match]) -> QuestionOutcome {
        let (isCorrect, explanation) = checkMatches(matches)
        return QuestionOutcome(
            isCorrect: isCorrect,
            explanation: explanation,
            givenAnswer: submittedAnswerText,
            correctAnswer: correctAnswerText
        )
    }

    override var correctAnswerText: String {
        Self.lines(leftItems.compactMap { left in correctRightByLeft[left].map { Match(left: left, right: $0) } })
    }

    override var submittedAnswerText: String {
        guard let submittedMatches else { return "" }
        let ordered = leftItems.compactMap { left in submittedMatches.first { $0.left == left } }
        return Self.lines(ordered)
    }

    private static func lines(_ matches: [Match]) -> String {
        matches.map { "\($0.left) → \($0.right)" }.joined(separator: "\n")
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
