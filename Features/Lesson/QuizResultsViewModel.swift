import Foundation
import AppOfTheDeadCore

/// What a finished quiz comes to: the score, a verdict in words, the XP the session really earned and every question
/// with the answer given, the right answer and why.
struct QuizResultsViewModel {

    enum Kind: Equatable {
        case lesson(title: String)
        case mastery(requiredScore: Int)
        case review
    }

    enum Tier: Equatable {
        case flawless
        case strong
        case steady
        case struggling
    }

    struct ReviewItem: Equatable {
        let question: String
        let wasCorrect: Bool
        let givenAnswer: String
        let correctAnswer: String
        let explanation: String
    }

    let kind: Kind
    let pathName: String
    let traditionColor: String
    let correctCount: Int
    let totalCount: Int
    let xpEarned: Int
    let items: [ReviewItem]

    /// `bonusXP` is what finishing earned on top of the right answers: the lesson's reward, the mastery reward, or the
    /// mistake review's XP.
    init(kind: Kind, beliefSystem: BeliefSystem, results: [QuestionResult], bonusXP: Int) {
        self.kind = kind
        self.pathName = beliefSystem.name
        self.traditionColor = beliefSystem.color
        self.correctCount = results.filter(\.wasCorrect).count
        self.totalCount = results.count
        self.xpEarned = results.reduce(bonusXP) { $0 + $1.xpEarned }
        self.items = results.map { result in
            ReviewItem(
                question: result.question.question,
                wasCorrect: result.wasCorrect,
                givenAnswer: result.givenAnswer,
                correctAnswer: result.correctAnswer,
                explanation: result.question.explanation
            )
        }
    }

    /// The share of right answers in whole percent; the mastery test passes on the same number.
    var score: Int {
        guard totalCount > 0 else { return 100 }
        return Self.percent(correct: correctCount, of: totalCount)
    }

    /// `correct` out of `total` in whole percent, rounded to the nearest, so four of six reads 67%.
    static func percent(correct: Int, of total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total) * 100).rounded())
    }

    var fraction: Double {
        guard totalCount > 0 else { return 1 }
        return Double(correctCount) / Double(totalCount)
    }

    var mistakeCount: Int {
        totalCount - correctCount
    }

    /// Whether a mastery test passed; nil for anything else.
    var passed: Bool? {
        guard case .mastery(let requiredScore) = kind else { return nil }
        return score >= requiredScore
    }

    var tier: Tier {
        switch score {
        case 100...: return .flawless
        case 80..<100: return .strong
        case 50..<80: return .steady
        default: return .struggling
        }
    }

    var eyebrow: String {
        switch kind {
        case .lesson: return String(localized: "Lesson complete")
        case .mastery: return String(localized: "Mastery test")
        case .review: return String(localized: "Mistake review")
        }
    }

    var title: String {
        if let passed {
            return passed ? String(localized: "Mastered") : String(localized: "Not yet")
        }
        switch tier {
        case .flawless: return String(localized: "Flawless")
        case .strong: return String(localized: "Well done")
        case .steady: return String(localized: "Good effort")
        case .struggling: return String(localized: "Keep going")
        }
    }

    var subtitle: String {
        switch kind {
        case .lesson(let title):
            return title
        case .mastery(let requiredScore):
            if passed == true {
                return String(localized: "You have mastered \(pathName).")
            }
            return String(localized: "Passing takes \(requiredScore)%. Review what you missed and try again.")
        case .review:
            return pathName
        }
    }

    var correctValue: String {
        "\(correctCount)/\(totalCount)"
    }

    var xpValue: String {
        "+\(xpEarned)"
    }

    var scoreText: String {
        "\(score)%"
    }
}
