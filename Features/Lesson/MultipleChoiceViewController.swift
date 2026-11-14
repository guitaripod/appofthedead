import UIKit

/// A multiple-choice question: one card per option with a letter badge. The chosen card glows; once checked the right
/// answer turns green, a wrong choice red, and the rest fade back.
final class MultipleChoiceViewController: BaseQuestionViewController {

    private static let letters = ["A", "B", "C", "D", "E", "F", "G", "H"]

    private var cards: [QuizOptionCard] = []
    private var selectedIndex: Int?

    private var multipleChoiceViewModel: MultipleChoiceViewModel {
        viewModel as! MultipleChoiceViewModel
    }

    override var hintText: String? {
        String(localized: "Choose one answer")
    }

    override var revealFocusView: UIView? {
        cards.first { $0.mark == .correct }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOptions()
    }

    private func setupOptions() {
        for (index, option) in multipleChoiceViewModel.options.enumerated() {
            let letter = Self.letters[index % Self.letters.count]
            let card = QuizOptionCard(title: option, badge: .letter(letter), accent: accent)
            card.addAction(UIAction { [weak self] _ in self?.select(index) }, for: .touchUpInside)
            cards.append(card)
            answersStack.addArrangedSubview(card)
        }
    }

    private func select(_ index: Int) {
        guard !isChecked, cards.indices.contains(index) else { return }
        if selectedIndex != index {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        selectedIndex = index
        for (offset, card) in cards.enumerated() {
            card.apply(offset == index ? .selected : .idle, animated: true)
        }
        setReadyToCheck(true)
    }

    override func checkSelectedAnswer() -> QuestionOutcome? {
        guard let selectedIndex, multipleChoiceViewModel.options.indices.contains(selectedIndex) else { return nil }
        let outcome = multipleChoiceViewModel.outcome(for: multipleChoiceViewModel.options[selectedIndex])
        markAnswers(selectedIndex: selectedIndex)
        return outcome
    }

    /// The right options turn green, the chosen wrong one red and shaken, the others dim.
    private func markAnswers(selectedIndex: Int) {
        for (index, card) in cards.enumerated() {
            card.isEnabled = false
            if isCorrectOption(at: index) {
                card.apply(.correct, animated: true)
                if index == selectedIndex { card.pop() }
            } else if index == selectedIndex {
                card.apply(.incorrect, animated: true)
                card.shake()
            } else {
                card.apply(.dimmed, animated: true)
            }
        }
    }

    private func isCorrectOption(at index: Int) -> Bool {
        let option = multipleChoiceViewModel.options[index]
        switch viewModel.question.correctAnswer.value {
        case .string(let answer): return option == answer
        case .array(let answers): return answers.contains(option)
        }
    }

    override func handleKeyInput(_ input: String) -> Bool {
        guard !isChecked else { return false }
        let key = input.uppercased()
        if let number = Int(key), (1...cards.count).contains(number) {
            select(number - 1)
            return true
        }
        if let index = Self.letters.prefix(cards.count).firstIndex(of: key) {
            select(index)
            return true
        }
        return false
    }

    #if DEBUG
    override func demoChooseAnswer(correctly: Bool) {
        guard let index = cards.indices.first(where: { isCorrectOption(at: $0) == correctly }) else { return }
        select(index)
    }
    #endif
}
