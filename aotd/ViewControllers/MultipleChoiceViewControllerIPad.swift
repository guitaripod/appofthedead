import UIKit
final class MultipleChoiceViewControllerIPad: BaseQuestionViewController {
    private let mainContainer = UIView()
    private let leftPanel = UIView()
    private let rightPanel = UIView()
    private let lessonContentView = UITextView()
    private let contextLabel = UILabel()
    private let optionsStackView = UIStackView()
    private var optionButtons: [UIButton] = []
    private var selectedOption: String?
    private let illustrationImageView = UIImageView()
    private var multipleChoiceViewModel: MultipleChoiceViewModel {
        viewModel as! MultipleChoiceViewModel
    }
    private let adaptiveLayoutManager = AdaptiveLayoutManager.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubmitButton()
        setupSplitLayout()
        setupOptionsUI()
        loadLessonContent()
    }
    private func setupSplitLayout() {
        guard adaptiveLayoutManager.isIPad && adaptiveLayoutManager.isRegularWidth(traitCollection) else {
            setupStandardLayout()
            return
        }
        questionLabel.isHidden = true
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        leftPanel.translatesAutoresizingMaskIntoConstraints = false
        leftPanel.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        leftPanel.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        leftPanel.layer.borderWidth = 1
        leftPanel.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        mainContainer.addSubview(leftPanel)
        rightPanel.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.background
        mainContainer.addSubview(rightPanel)
        lessonContentView.translatesAutoresizingMaskIntoConstraints = false
        lessonContentView.backgroundColor = .clear
        lessonContentView.font = PapyrusDesignSystem.Typography.body(for: traitCollection)
        lessonContentView.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        lessonContentView.isEditable = false
        lessonContentView.isSelectable = true
        lessonContentView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        leftPanel.addSubview(lessonContentView)
        illustrationImageView.translatesAutoresizingMaskIntoConstraints = false
        illustrationImageView.contentMode = .scaleAspectFit
        illustrationImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf.withAlphaComponent(0.3)
        leftPanel.addSubview(illustrationImageView)
        contextLabel.translatesAutoresizingMaskIntoConstraints = false
        contextLabel.font = PapyrusDesignSystem.Typography.callout(for: traitCollection)
        contextLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        contextLabel.numberOfLines = 0
        contextLabel.text = "Review the lesson content on the left, then answer the question below."
        rightPanel.addSubview(contextLabel)
        questionLabel.removeFromSuperview()
        questionLabel.isHidden = false
        questionLabel.font = PapyrusDesignSystem.Typography.title2(for: traitCollection)
        rightPanel.addSubview(questionLabel)
        let spacing = adaptiveLayoutManager.spacing(for: .large, traitCollection: traitCollection)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: spacing),
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: spacing),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -spacing),
            mainContainer.bottomAnchor.constraint(equalTo: submitButton!.topAnchor, constant: -spacing),
            leftPanel.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            leftPanel.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            leftPanel.widthAnchor.constraint(equalTo: mainContainer.widthAnchor, multiplier: 0.4),
            leftPanel.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
            rightPanel.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            rightPanel.leadingAnchor.constraint(equalTo: leftPanel.trailingAnchor, constant: spacing),
            rightPanel.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            rightPanel.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
            lessonContentView.topAnchor.constraint(equalTo: leftPanel.topAnchor),
            lessonContentView.leadingAnchor.constraint(equalTo: leftPanel.leadingAnchor),
            lessonContentView.trailingAnchor.constraint(equalTo: leftPanel.trailingAnchor),
            lessonContentView.bottomAnchor.constraint(equalTo: illustrationImageView.topAnchor, constant: -spacing),
            illustrationImageView.leadingAnchor.constraint(equalTo: leftPanel.leadingAnchor, constant: spacing),
            illustrationImageView.trailingAnchor.constraint(equalTo: leftPanel.trailingAnchor, constant: -spacing),
            illustrationImageView.bottomAnchor.constraint(equalTo: leftPanel.bottomAnchor, constant: -spacing),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 120),
            contextLabel.topAnchor.constraint(equalTo: rightPanel.topAnchor, constant: spacing),
            contextLabel.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor, constant: spacing),
            contextLabel.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor, constant: -spacing),
            questionLabel.topAnchor.constraint(equalTo: contextLabel.bottomAnchor, constant: spacing * 1.5),
            questionLabel.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor, constant: spacing),
            questionLabel.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor, constant: -spacing)
        ])
    }
    private func setupStandardLayout() {
        setupOptionsUI()
    }
    private func setupOptionsUI() {
        if adaptiveLayoutManager.isIPad && adaptiveLayoutManager.isRegularWidth(traitCollection) {
            optionsStackView.translatesAutoresizingMaskIntoConstraints = false
            optionsStackView.axis = .vertical
            optionsStackView.spacing = adaptiveLayoutManager.spacing(for: .medium, traitCollection: traitCollection)
            optionsStackView.alignment = .fill
            rightPanel.addSubview(optionsStackView)
            NSLayoutConstraint.activate([
                optionsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 32),
                optionsStackView.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor, constant: 20),
                optionsStackView.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor, constant: -20)
            ])
        } else {
            optionsStackView.axis = .vertical
            optionsStackView.spacing = 16
            optionsStackView.alignment = .fill
            contentStackView.addArrangedSubview(optionsStackView)
        }
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
    private func loadLessonContent() {
        guard adaptiveLayoutManager.isIPad && adaptiveLayoutManager.isRegularWidth(traitCollection) else { return }
        let sampleContent = """
        📜 Lesson Context
        Ancient Wisdom
        This question relates to the beliefs and practices discussed in the previous lesson. Consider what you've learned about the spiritual traditions and their unique perspectives on the afterlife.
        Key Points to Remember:
        • Each tradition has unique beliefs
        • Common themes exist across cultures
        • Historical context shapes understanding
        • Modern interpretations vary
        """
        lessonContentView.text = sampleContent
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .thin)
        illustrationImageView.image = UIImage(systemName: "book.pages", withConfiguration: config)
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
           traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            view.subviews.forEach { $0.removeFromSuperview() }
            viewDidLoad()
        }
    }
}