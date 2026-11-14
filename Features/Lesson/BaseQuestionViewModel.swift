import UIKit
import AppOfTheDeadCore

protocol QuestionViewModelDelegate: AnyObject {
    func questionViewModel(_ viewModel: BaseQuestionViewModel, didAnswerCorrectly: Bool)
    func questionViewModelDidRequestExit(_ viewModel: BaseQuestionViewModel)
}

class BaseQuestionViewModel {

    weak var delegate: QuestionViewModelDelegate?

    let question: Question
    let beliefSystem: BeliefSystem
    let currentQuestionIndex: Int
    let totalQuestions: Int

    /// The answer last checked, as given.
    private(set) var submittedAnswer: String?

    var questionText: String {
        question.question
    }

    var progress: Float {
        Float(currentQuestionIndex + 1) / Float(totalQuestions)
    }

    var beliefSystemColor: UIColor? {
        PapyrusDesignSystem.Colors.tradition(beliefSystem.color)
    }

    var xpReward: Int {
        10
    }

    /// "Question 3 of 6", for the eyebrow above the question.
    var positionText: String {
        String(localized: "Question \(currentQuestionIndex + 1) of \(totalQuestions)")
    }

    /// The right answer as people read it: True or False in the reader's language, the option's words otherwise.
    var correctAnswerText: String {
        switch question.correctAnswer.value {
        case .string(let answer):
            return displayText(for: answer)
        case .array(let answers):
            return answers.first.map(displayText(for:)) ?? ""
        }
    }

    /// The answer last checked as people read it, or an empty string before any check.
    var submittedAnswerText: String {
        submittedAnswer.map(displayText(for:)) ?? ""
    }

    init(question: Question, beliefSystem: BeliefSystem, currentQuestionIndex: Int, totalQuestions: Int) {
        self.question = question
        self.beliefSystem = beliefSystem
        self.currentQuestionIndex = currentQuestionIndex
        self.totalQuestions = totalQuestions
    }

    func checkAnswer(_ answer: String) -> (isCorrect: Bool, explanation: String) {
        submittedAnswer = answer
        let isCorrect: Bool
        switch question.correctAnswer.value {
        case .string(let correctAnswer):
            isCorrect = answer == correctAnswer
        case .array(let correctAnswers):
            isCorrect = correctAnswers.contains(answer)
        }
        return (isCorrect, question.explanation)
    }

    /// Checks `answer` and describes the result for the feedback panel and the results screen.
    func outcome(for answer: String) -> QuestionOutcome {
        let (isCorrect, explanation) = checkAnswer(answer)
        return QuestionOutcome(
            isCorrect: isCorrect,
            explanation: explanation,
            givenAnswer: submittedAnswerText,
            correctAnswer: correctAnswerText
        )
    }

    /// True or false answers are stored as `true` and `false`; people read them in their own language.
    func displayText(for answer: String) -> String {
        guard question.type == .trueFalse else { return answer }
        switch answer.lowercased() {
        case "true": return String(localized: "True")
        case "false": return String(localized: "False")
        default: return answer
        }
    }

    func exitQuiz() {
        delegate?.questionViewModelDidRequestExit(self)
    }
}
