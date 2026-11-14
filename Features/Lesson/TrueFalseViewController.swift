import UIKit

/// A true-or-false statement answered with two large cards side by side.
final class TrueFalseViewController: BaseQuestionViewController {

    private lazy var trueCard = QuizOptionCard(title: String(localized: "True"), badge: .symbol("checkmark"), accent: accent, layout: .tile)
    private lazy var falseCard = QuizOptionCard(title: String(localized: "False"), badge: .symbol("xmark"), accent: accent, layout: .tile)
    private var selectedAnswer: String?

    override var hintText: String? {
        String(localized: "True or false?")
    }

    override var revealFocusView: UIView? {
        [trueCard, falseCard].first { $0.mark == .correct }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        trueCard.addAction(UIAction { [weak self] _ in self?.select("true") }, for: .touchUpInside)
        falseCard.addAction(UIAction { [weak self] _ in self?.select("false") }, for: .touchUpInside)
        answersStack.addArrangedSubview(makeAdaptiveRow([trueCard, falseCard]))
    }

    private func card(for answer: String) -> QuizOptionCard {
        answer == "true" ? trueCard : falseCard
    }

    private func select(_ answer: String) {
        guard !isChecked else { return }
        if selectedAnswer != answer {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        selectedAnswer = answer
        trueCard.apply(answer == "true" ? .selected : .idle, animated: true)
        falseCard.apply(answer == "false" ? .selected : .idle, animated: true)
        setReadyToCheck(true)
    }

    override func checkSelectedAnswer() -> QuestionOutcome? {
        guard let selectedAnswer else { return nil }
        let outcome = viewModel.outcome(for: selectedAnswer)
        let chosen = card(for: selectedAnswer)
        let other = chosen === trueCard ? falseCard : trueCard
        [trueCard, falseCard].forEach { $0.isEnabled = false }
        if outcome.isCorrect {
            chosen.apply(.correct, animated: true)
            chosen.pop()
            other.apply(.dimmed, animated: true)
        } else {
            chosen.apply(.incorrect, animated: true)
            chosen.shake()
            other.apply(.correct, animated: true)
        }
        return outcome
    }

    override func handleKeyInput(_ input: String) -> Bool {
        guard !isChecked else { return false }
        switch input.lowercased() {
        case "t", "1":
            select("true")
            return true
        case "f", "2":
            select("false")
            return true
        default:
            return false
        }
    }

    #if DEBUG
    override func demoChooseAnswer(correctly: Bool) {
        let isTrue: Bool
        if case .string(let answer) = viewModel.question.correctAnswer.value {
            isTrue = answer.lowercased() == "true"
        } else {
            isTrue = true
        }
        select(isTrue == correctly ? "true" : "false")
    }
    #endif
}
