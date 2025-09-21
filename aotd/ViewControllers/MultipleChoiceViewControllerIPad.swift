import UIKit
final class MultipleChoiceViewControllerIPad: BaseQuestionViewController {
    private let optionsStackView = UIStackView()
    private var optionButtons: [UIButton] = []
    private var selectedOption: String?
    private var multipleChoiceViewModel: MultipleChoiceViewModel {
        viewModel as! MultipleChoiceViewModel
    }
    private let adaptiveLayoutManager = AdaptiveLayoutManager.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubmitButton()
        setupOptionsUI()
    }
    private func setupOptionsUI() {
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.axis = .vertical
        optionsStackView.spacing = adaptiveLayoutManager.spacing(for: .medium, traitCollection: traitCollection)
        optionsStackView.alignment = .fill
        contentStackView.addArrangedSubview(optionsStackView)

        for (index, option) in multipleChoiceViewModel.options.enumerated() {
            let button = createOptionButton(option: option, tag: index)
            optionButtons.append(button)
            optionsStackView.addArrangedSubview(button)
        }
    }
    private func createOptionButton(option: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = tag
        button.contentHorizontalAlignment = .leading
        let config = UIButton.Configuration.filled()
        var updatedConfig = config
        updatedConfig.title = option
        updatedConfig.baseBackgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        updatedConfig.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        let touchSize = adaptiveLayoutManager.touchTargetSize(for: traitCollection)
        let insets = adaptiveLayoutManager.isIPad ? 
            NSDirectionalEdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24) :
            NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        updatedConfig.contentInsets = insets
        updatedConfig.cornerStyle = .large
        updatedConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var outgoing = incoming
            outgoing.font = PapyrusDesignSystem.Typography.headline(for: self?.traitCollection)
            return outgoing
        }
        if adaptiveLayoutManager.isIPad {
            let circleConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            updatedConfig.image = UIImage(systemName: "circle", withConfiguration: circleConfig)
            updatedConfig.imagePlacement = .leading
            updatedConfig.imagePadding = 12
        }
        button.configuration = updatedConfig
        button.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: touchSize).isActive = true
        return button
    }
    @objc private func optionSelected(_ sender: UIButton) {
        UISelectionFeedbackGenerator().selectionChanged()
        selectedOption = multipleChoiceViewModel.options[sender.tag]
        for (index, button) in optionButtons.enumerated() {
            var config = button.configuration
            if index == sender.tag {
                config?.baseBackgroundColor = PapyrusDesignSystem.Colors.goldLeaf.withAlphaComponent(0.2)
                config?.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
                if adaptiveLayoutManager.isIPad {
                    let circleConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                    config?.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: circleConfig)
                    config?.imageColorTransformer = UIConfigurationColorTransformer { _ in
                        PapyrusDesignSystem.Colors.goldLeaf
                    }
                }
            } else {
                config?.baseBackgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
                config?.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
                if adaptiveLayoutManager.isIPad {
                    let circleConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                    config?.image = UIImage(systemName: "circle", withConfiguration: circleConfig)
                    config?.imageColorTransformer = UIConfigurationColorTransformer { _ in
                        PapyrusDesignSystem.Colors.Dynamic.tertiaryText
                    }
                }
            }
            button.configuration = config
        }
        enableSubmitButton(true)
    }
    override func submitAnswer() {
        guard let selectedOption = selectedOption else { return }
        let (isCorrect, explanation) = viewModel.checkAnswer(selectedOption)
        submitButton?.isEnabled = false
        optionButtons.forEach { $0.isEnabled = false }
        showAnswerFeedback(selectedAnswer: selectedOption, isCorrect: isCorrect)
        showFeedback(isCorrect: isCorrect, explanation: explanation) { [weak self] in
            self?.viewModel.delegate?.questionViewModel(self!.viewModel, didAnswerCorrectly: isCorrect)
        }
    }
    private func showAnswerFeedback(selectedAnswer: String, isCorrect: Bool) {
        let correctAnswer: String
        switch multipleChoiceViewModel.question.correctAnswer.value {
        case .string(let answer):
            correctAnswer = answer
        case .array(let answers):
            correctAnswer = answers.first ?? ""
        }
        for (index, button) in optionButtons.enumerated() {
            let option = multipleChoiceViewModel.options[index]
            var config = button.configuration
            if option == correctAnswer {
                config?.baseBackgroundColor = PapyrusDesignSystem.Colors.scarabGreen.withAlphaComponent(0.3)
                config?.baseForegroundColor = PapyrusDesignSystem.Colors.beige
                if adaptiveLayoutManager.isIPad {
                    let checkConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                    config?.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig)
                    config?.imageColorTransformer = UIConfigurationColorTransformer { _ in
                        PapyrusDesignSystem.Colors.scarabGreen
                    }
                } else {
                    config?.image = UIImage(systemName: "checkmark.circle.fill")
                    config?.imagePlacement = .trailing
                }
            } else if option == selectedAnswer && !isCorrect {
                config?.baseBackgroundColor = PapyrusDesignSystem.Colors.tombRed.withAlphaComponent(0.3)
                config?.baseForegroundColor = PapyrusDesignSystem.Colors.beige
                if adaptiveLayoutManager.isIPad {
                    let xConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                    config?.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: xConfig)
                    config?.imageColorTransformer = UIConfigurationColorTransformer { _ in
                        PapyrusDesignSystem.Colors.tombRed
                    }
                } else {
                    config?.image = UIImage(systemName: "xmark.circle.fill")
                    config?.imagePlacement = .trailing
                }
            }
            button.configuration = config
        }
    }
}