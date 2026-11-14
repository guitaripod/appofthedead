import UIKit

/// A matching question: tap an item in one column, then its partner in the other. Each pair takes a color of its own;
/// once checked, right pairs turn green and each wrong one red, with the partner it belongs with written under it.
final class MatchingQuestionViewController: BaseQuestionViewController {

    private var leftCards: [QuizOptionCard] = []
    private var rightCards: [QuizOptionCard] = []
    private var selectedLeftIndex: Int?
    private var selectedRightIndex: Int?
    private var matchedRightByLeft: [Int: Int] = [:]

    private static let pairPalette: [UIColor] = [
        PapyrusDesignSystem.Colors.Core.goldLeaf,
        PapyrusDesignSystem.Colors.Core.hieroglyphBlue,
        PapyrusDesignSystem.Colors.Core.mysticPurple,
        UIColor(hex: 0x4FB6B0),
        PapyrusDesignSystem.Colors.Core.burnishedGold,
    ]

    private var matchingViewModel: MatchingQuestionViewModel {
        viewModel as! MatchingQuestionViewModel
    }

    override var hintText: String? {
        String(localized: "Tap an item, then tap its match")
    }

    override var revealFocusView: UIView? {
        leftCards.first { $0.mark == .incorrect } ?? leftCards.last
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupColumns()
    }

    private func setupColumns() {
        let leftColumn = UIStackView()
        let rightColumn = UIStackView()
        for column in [leftColumn, rightColumn] {
            column.axis = .vertical
            column.spacing = 10
        }
        for (index, item) in matchingViewModel.leftItems.enumerated() {
            let card = makeCard(title: item) { [weak self] in self?.leftTapped(index) }
            leftCards.append(card)
            leftColumn.addArrangedSubview(card)
        }
        for (index, item) in matchingViewModel.rightItems.enumerated() {
            let card = makeCard(title: item) { [weak self] in self?.rightTapped(index) }
            rightCards.append(card)
            rightColumn.addArrangedSubview(card)
        }
        let columns = makeAdaptiveRow([leftColumn, rightColumn])
        columns.alignment = .top
        answersStack.addArrangedSubview(columns)
    }

    private func makeCard(title: String, action: @escaping () -> Void) -> QuizOptionCard {
        let card = QuizOptionCard(title: title, badge: .none, accent: accent, layout: .compact)
        card.accessibilityHint = String(localized: "Tap to select, then tap an item in the other column to form a pair")
        card.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return card
    }

    private func leftTapped(_ index: Int) {
        guard !isChecked else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        if selectedLeftIndex == index {
            selectedLeftIndex = nil
            refreshCards()
            return
        }
        matchedRightByLeft.removeValue(forKey: index)
        selectedLeftIndex = index
        if let rightIndex = selectedRightIndex {
            formMatch(leftIndex: index, rightIndex: rightIndex)
        }
        refreshCards()
    }

    private func rightTapped(_ index: Int) {
        guard !isChecked else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        if selectedRightIndex == index {
            selectedRightIndex = nil
            refreshCards()
            return
        }
        if let pairedLeft = leftIndex(pairedWith: index) {
            matchedRightByLeft.removeValue(forKey: pairedLeft)
        }
        selectedRightIndex = index
        if let leftIndex = selectedLeftIndex {
            formMatch(leftIndex: leftIndex, rightIndex: index)
        }
        refreshCards()
    }

    private func leftIndex(pairedWith rightIndex: Int) -> Int? {
        matchedRightByLeft.first { $0.value == rightIndex }?.key
    }

    private func formMatch(leftIndex: Int, rightIndex: Int) {
        matchedRightByLeft[leftIndex] = rightIndex
        selectedLeftIndex = nil
        selectedRightIndex = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func refreshCards() {
        for (index, card) in leftCards.enumerated() {
            if selectedLeftIndex == index {
                card.apply(.selected, animated: true)
            } else if let rightIndex = matchedRightByLeft[index] {
                card.apply(.paired(pairColor(forLeftIndex: index)), animated: true)
                card.accessibilityValue = String(localized: "Matched with \(matchingViewModel.rightItems[rightIndex])")
            } else {
                card.apply(.idle, animated: true)
            }
        }
        for (index, card) in rightCards.enumerated() {
            if selectedRightIndex == index {
                card.apply(.selected, animated: true)
            } else if let pairedLeft = leftIndex(pairedWith: index) {
                card.apply(.paired(pairColor(forLeftIndex: pairedLeft)), animated: true)
                card.accessibilityValue = String(localized: "Matched with \(matchingViewModel.leftItems[pairedLeft])")
            } else {
                card.apply(.idle, animated: true)
            }
        }
        setReadyToCheck(matchedRightByLeft.count == matchingViewModel.leftItems.count)
    }

    private func pairColor(forLeftIndex index: Int) -> UIColor {
        Self.pairPalette[index % Self.pairPalette.count]
    }

    override func checkSelectedAnswer() -> QuestionOutcome? {
        let matches = matchedRightByLeft.sorted { $0.key < $1.key }.map { leftIndex, rightIndex in
            MatchingQuestionViewModel.Match(
                left: matchingViewModel.leftItems[leftIndex],
                right: matchingViewModel.rightItems[rightIndex]
            )
        }
        let outcome = matchingViewModel.outcome(for: matches)
        markPairs()
        return outcome
    }

    /// Right pairs turn green; a wrong pair turns red and its left item names the partner it belongs with.
    private func markPairs() {
        (leftCards + rightCards).forEach { $0.isEnabled = false }
        for (leftIndex, rightIndex) in matchedRightByLeft {
            let left = matchingViewModel.leftItems[leftIndex]
            let match = MatchingQuestionViewModel.Match(left: left, right: matchingViewModel.rightItems[rightIndex])
            let isCorrect = matchingViewModel.isMatchCorrect(match)
            leftCards[leftIndex].apply(isCorrect ? .correct : .incorrect, animated: true)
            rightCards[rightIndex].apply(isCorrect ? .correct : .incorrect, animated: true)
            if !isCorrect, let partner = matchingViewModel.correctPartner(for: left) {
                leftCards[leftIndex].subtitle = String(localized: "Belongs with \(partner)")
                leftCards[leftIndex].shake()
            }
        }
    }

    #if DEBUG
    override func demoChooseAnswer(correctly: Bool) {
        for (leftIndex, left) in matchingViewModel.leftItems.enumerated() {
            guard let partner = matchingViewModel.correctPartner(for: left),
                  let rightIndex = matchingViewModel.rightItems.firstIndex(of: partner) else { continue }
            matchedRightByLeft[leftIndex] = rightIndex
        }
        if !correctly, matchedRightByLeft.count > 1, let first = matchedRightByLeft[0], let second = matchedRightByLeft[1] {
            matchedRightByLeft[0] = second
            matchedRightByLeft[1] = first
        }
        refreshCards()
    }
    #endif
}
