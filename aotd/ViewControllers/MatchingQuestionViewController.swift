import UIKit

final class MatchingQuestionViewController: BaseQuestionViewController {

    private let instructionLabel = UILabel()
    private let columnsScrollView = UIScrollView()
    private let columnsStackView = UIStackView()
    private let leftColumnStackView = UIStackView()
    private let rightColumnStackView = UIStackView()
    private var leftButtons: [UIButton] = []
    private var rightButtons: [UIButton] = []

    private var selectedLeftIndex: Int?
    private var selectedRightIndex: Int?
    private var matchedRightByLeft: [Int: Int] = [:]

    private static let pairPalette: [UIColor] = [
        UIColor.Papyrus.gold,
        UIColor.Papyrus.hieroglyphBlue,
        UIColor.Papyrus.mysticPurple,
        UIColor.Papyrus.scarabGreen,
        UIColor.Papyrus.burnishedGold
    ]

    private var matchingViewModel: MatchingQuestionViewModel {
        viewModel as! MatchingQuestionViewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubmitButton()
        setupMatchingUI()
    }

    private func setupMatchingUI() {
        instructionLabel.text = "Tap an item, then tap its match"
        instructionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        instructionLabel.textColor = UIColor.Papyrus.secondaryText
        contentStackView.addArrangedSubview(instructionLabel)

        columnsScrollView.translatesAutoresizingMaskIntoConstraints = false
        columnsScrollView.showsVerticalScrollIndicator = false
        columnsScrollView.alwaysBounceVertical = false
        view.addSubview(columnsScrollView)

        columnsStackView.translatesAutoresizingMaskIntoConstraints = false
        columnsStackView.axis = .horizontal
        columnsStackView.spacing = 12
        columnsStackView.alignment = .top
        columnsStackView.distribution = .fillEqually
        columnsScrollView.addSubview(columnsStackView)

        for columnStackView in [leftColumnStackView, rightColumnStackView] {
            columnStackView.axis = .vertical
            columnStackView.spacing = 12
            columnStackView.alignment = .fill
            columnsStackView.addArrangedSubview(columnStackView)
        }

        for (index, item) in matchingViewModel.leftItems.enumerated() {
            let button = createItemButton(title: item, tag: index, action: #selector(leftItemTapped(_:)))
            leftButtons.append(button)
            leftColumnStackView.addArrangedSubview(button)
        }

        for (index, item) in matchingViewModel.rightItems.enumerated() {
            let button = createItemButton(title: item, tag: index, action: #selector(rightItemTapped(_:)))
            rightButtons.append(button)
            rightColumnStackView.addArrangedSubview(button)
        }

        guard let submitButton else { return }
        NSLayoutConstraint.activate([
            columnsScrollView.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 24),
            columnsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            columnsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            columnsScrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -16),
            columnsStackView.topAnchor.constraint(equalTo: columnsScrollView.contentLayoutGuide.topAnchor),
            columnsStackView.leadingAnchor.constraint(equalTo: columnsScrollView.contentLayoutGuide.leadingAnchor),
            columnsStackView.trailingAnchor.constraint(equalTo: columnsScrollView.contentLayoutGuide.trailingAnchor),
            columnsStackView.bottomAnchor.constraint(equalTo: columnsScrollView.contentLayoutGuide.bottomAnchor),
            columnsStackView.widthAnchor.constraint(equalTo: columnsScrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func createItemButton(title: String, tag: Int, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = tag
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping

        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor.Papyrus.cardBackground
        configuration.baseForegroundColor = UIColor.Papyrus.primaryText
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12)
        configuration.cornerStyle = .large
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        button.configuration = configuration

        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.clear.cgColor
        button.layer.cornerRadius = 12

        button.accessibilityHint = "Tap to select, then tap an item in the other column to form a pair"
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func leftItemTapped(_ sender: UIButton) {
        UISelectionFeedbackGenerator().selectionChanged()
        let index = sender.tag

        if selectedLeftIndex == index {
            selectedLeftIndex = nil
            refreshButtonStyles()
            return
        }

        matchedRightByLeft.removeValue(forKey: index)
        selectedLeftIndex = index

        if let rightIndex = selectedRightIndex {
            formMatch(leftIndex: index, rightIndex: rightIndex)
        }
        refreshButtonStyles()
    }

    @objc private func rightItemTapped(_ sender: UIButton) {
        UISelectionFeedbackGenerator().selectionChanged()
        let index = sender.tag

        if selectedRightIndex == index {
            selectedRightIndex = nil
            refreshButtonStyles()
            return
        }

        if let pairedLeft = matchedRightByLeft.first(where: { $0.value == index })?.key {
            matchedRightByLeft.removeValue(forKey: pairedLeft)
        }
        selectedRightIndex = index

        if let leftIndex = selectedLeftIndex {
            formMatch(leftIndex: leftIndex, rightIndex: index)
        }
        refreshButtonStyles()
    }

    private func formMatch(leftIndex: Int, rightIndex: Int) {
        matchedRightByLeft[leftIndex] = rightIndex
        selectedLeftIndex = nil
        selectedRightIndex = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func refreshButtonStyles() {
        for (index, button) in leftButtons.enumerated() {
            if let rightIndex = matchedRightByLeft[index] {
                style(button, selected: selectedLeftIndex == index, pairColor: pairColor(forLeftIndex: index))
                button.accessibilityValue = "Matched with \(matchingViewModel.rightItems[rightIndex])"
            } else {
                style(button, selected: selectedLeftIndex == index, pairColor: nil)
                button.accessibilityValue = nil
            }
        }
        for (index, button) in rightButtons.enumerated() {
            if let pairedLeft = matchedRightByLeft.first(where: { $0.value == index })?.key {
                style(button, selected: selectedRightIndex == index, pairColor: pairColor(forLeftIndex: pairedLeft))
                button.accessibilityValue = "Matched with \(matchingViewModel.leftItems[pairedLeft])"
            } else {
                style(button, selected: selectedRightIndex == index, pairColor: nil)
                button.accessibilityValue = nil
            }
        }
        enableSubmitButton(matchedRightByLeft.count == matchingViewModel.leftItems.count)
    }

    private func pairColor(forLeftIndex index: Int) -> UIColor {
        Self.pairPalette[index % Self.pairPalette.count]
    }

    private func style(_ button: UIButton, selected: Bool, pairColor: UIColor?) {
        var configuration = button.configuration
        if selected {
            configuration?.baseBackgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.2)
            button.layer.borderColor = UIColor.Papyrus.gold.cgColor
        } else if let pairColor {
            configuration?.baseBackgroundColor = pairColor.withAlphaComponent(0.22)
            button.layer.borderColor = pairColor.cgColor
        } else {
            configuration?.baseBackgroundColor = UIColor.Papyrus.cardBackground
            button.layer.borderColor = UIColor.clear.cgColor
        }
        configuration?.baseForegroundColor = UIColor.Papyrus.primaryText
        button.configuration = configuration
    }

    override func submitAnswer() {
        let matches = matchedRightByLeft.map { leftIndex, rightIndex in
            MatchingQuestionViewModel.Match(
                left: matchingViewModel.leftItems[leftIndex],
                right: matchingViewModel.rightItems[rightIndex]
            )
        }
        let (isCorrect, explanation) = matchingViewModel.checkMatches(matches)

        submitButton?.isEnabled = false
        leftButtons.forEach { $0.isEnabled = false }
        rightButtons.forEach { $0.isEnabled = false }

        showMatchFeedback()

        showFeedback(isCorrect: isCorrect, explanation: explanation) { [weak self] in
            guard let self else { return }
            self.viewModel.delegate?.questionViewModel(self.viewModel, didAnswerCorrectly: isCorrect)
        }
    }

    private func showMatchFeedback() {
        for (leftIndex, rightIndex) in matchedRightByLeft {
            let match = MatchingQuestionViewModel.Match(
                left: matchingViewModel.leftItems[leftIndex],
                right: matchingViewModel.rightItems[rightIndex]
            )
            let isCorrect = matchingViewModel.isMatchCorrect(match)
            let feedbackColor = isCorrect ? UIColor.Papyrus.scarabGreen : UIColor.Papyrus.tombRed
            for button in [leftButtons[leftIndex], rightButtons[rightIndex]] {
                var configuration = button.configuration
                configuration?.baseBackgroundColor = feedbackColor.withAlphaComponent(0.3)
                configuration?.image = UIImage(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                configuration?.imagePlacement = .trailing
                configuration?.imagePadding = 6
                button.configuration = configuration
                button.layer.borderColor = feedbackColor.cgColor
            }
        }
    }
}
