import UIKit

final class MultipleChoiceViewController: BaseQuestionViewController {
    
    private let optionsStackView = UIStackView()
    private var optionButtons: [UIButton] = []
    private var selectedOption: String?
    
    private var multipleChoiceViewModel: MultipleChoiceViewModel {
        viewModel as! MultipleChoiceViewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOptionsUI()
        setupSubmitButton()
    }
    
    private func setupOptionsUI() {
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 16
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
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        
        let configuration = UIButton.Configuration.filled()
        var updatedConfiguration = configuration
        updatedConfiguration.title = option
        updatedConfiguration.baseBackgroundColor = .secondarySystemFill
        updatedConfiguration.baseForegroundColor = .label
        updatedConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        updatedConfiguration.cornerStyle = .medium
        
        button.configuration = updatedConfiguration
        button.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func optionSelected(_ sender: UIButton) {
        UISelectionFeedbackGenerator().selectionChanged()
        
        selectedOption = multipleChoiceViewModel.options[sender.tag]
        
        for (index, button) in optionButtons.enumerated() {
            var config = button.configuration
            if index == sender.tag {
                config?.baseBackgroundColor = viewModel.beliefSystemColor?.withAlphaComponent(0.2)
                config?.baseForegroundColor = viewModel.beliefSystemColor
            } else {
                config?.baseBackgroundColor = .secondarySystemFill
                config?.baseForegroundColor = .label
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
                config?.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
                config?.baseForegroundColor = .systemGreen
            } else if option == selectedAnswer && !isCorrect {
                config?.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
                config?.baseForegroundColor = .systemRed
            }
            
            button.configuration = config
        }
    }
}