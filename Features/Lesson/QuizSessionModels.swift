import Foundation
import AppOfTheDeadCore

/// What checking one answer showed: whether it was right, why, what was given and what was expected, both written
/// for people to read.
struct QuestionOutcome: Equatable {
    let isCorrect: Bool
    let explanation: String
    let givenAnswer: String
    let correctAnswer: String
}

/// One answered question of a quiz session, with the XP it really earned.
struct QuestionResult {
    let question: Question
    let wasCorrect: Bool
    let givenAnswer: String
    let correctAnswer: String
    let xpEarned: Int

    init(question: Question, outcome: QuestionOutcome, xpEarned: Int) {
        self.question = question
        self.wasCorrect = outcome.isCorrect
        self.givenAnswer = outcome.givenAnswer
        self.correctAnswer = outcome.correctAnswer
        self.xpEarned = xpEarned
    }
}

/// The XP a right answer earns: the question's base reward raised by the learner's streak.
enum QuizXP {
    static func perCorrectAnswer(base: Int, streakDays: Int) -> Int {
        Int(Double(base) * streakMultiplier(streakDays: streakDays))
    }

    static func streakMultiplier(streakDays: Int) -> Double {
        switch streakDays {
        case ..<3: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.25
        case 14...29: return 1.5
        default: return 2.0
        }
    }
}
