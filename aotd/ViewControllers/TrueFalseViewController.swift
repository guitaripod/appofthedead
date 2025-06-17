import UIKit

final class TrueFalseViewController: BaseQuestionViewController {
    
    private let buttonsStackView = UIStackView()
    private var trueButton: UIButton!
    private var falseButton: UIButton!
    private var selectedAnswer: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTrueFalseButtons()
        setupSubmitButton()
    }
    
    private func setupTrueFalseButtons() {
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 16
        buttonsStackView.distribution = .fillEqually
        contentStackView.addArrangedSubview(buttonsStackView)
        
        trueButton = createTrueFalseButton(title: "True", isTrue: true)
        falseButton = createTrueFalseButton(title: "False", isTrue: false)
        
        buttonsStackView.addArrangedSubview(trueButton)
        buttonsStackView.addArrangedSubview(falseButton)
    }
    
    private func createTrueFalseButton(title: String, isTrue: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        
        let configuration = UIButton.Configuration.filled()
        var updatedConfiguration = configuration
        updatedConfiguration.title = title
        updatedConfiguration.baseBackgroundColor = UIColor.Papyrus.cardBackground
        updatedConfiguration.baseForegroundColor = UIColor.Papyrus.ink
        updatedConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: 24, trailing: 0)
        updatedConfiguration.cornerStyle = .large
        
        button.configuration = updatedConfiguration
        button.addTarget(self, action: #selector(trueFalseSelected(_:)), for: .touchUpInside)
        button.tag = isTrue ? 1 : 0
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return button
    }
    
    @objc private func trueFalseSelected(_ sender: UIButton) {
        UISelectionFeedbackGenerator().selectionChanged()
        
        selectedAnswer = sender.tag == 1 ? "true" : "false"
        
        let selectedButton = sender
        let otherButton = sender == trueButton ? falseButton : trueButton
        
        var selectedConfig = selectedButton.configuration
        selectedConfig?.baseBackgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.2)
        selectedConfig?.baseForegroundColor = UIColor.Papyrus.ink
        selectedButton.configuration = selectedConfig
        
        var otherConfig = otherButton?.configuration
        otherConfig?.baseBackgroundColor = UIColor.Papyrus.cardBackground
        otherConfig?.baseForegroundColor = UIColor.Papyrus.ink
        otherButton?.configuration = otherConfig
        
        enableSubmitButton(true)
    }
    
    override func submitAnswer() {
        guard let selectedAnswer = selectedAnswer else { return }
        
        let (isCorrect, explanation) = viewModel.checkAnswer(selectedAnswer)
        
        submitButton?.isEnabled = false
        trueButton.isEnabled = false
        falseButton.isEnabled = false
        
        showAnswerFeedback(selectedAnswer: selectedAnswer, isCorrect: isCorrect)
        
        showFeedback(isCorrect: isCorrect, explanation: explanation) { [weak self] in
            self?.viewModel.delegate?.questionViewModel(self!.viewModel, didAnswerCorrectly: isCorrect)
        }
    }
    
    private func showAnswerFeedback(selectedAnswer: String, isCorrect: Bool) {
        let correctAnswer: String
        switch viewModel.question.correctAnswer.value {
        case .string(let answer):
            correctAnswer = answer
        case .array(let answers):
            correctAnswer = answers.first ?? ""
        }
        
        for button in [trueButton!, falseButton!] {
            let buttonAnswer = button.tag == 1 ? "true" : "false"
            var config = button.configuration
            
            if buttonAnswer == correctAnswer {
                config?.baseBackgroundColor = UIColor.Papyrus.scarabGreen.withAlphaComponent(0.3)
                config?.baseForegroundColor = UIColor.Papyrus.beige
                config?.image = UIImage(systemName: "checkmark.circle.fill")
                config?.imagePlacement = .trailing
            } else if buttonAnswer == selectedAnswer && !isCorrect {
                config?.baseBackgroundColor = UIColor.Papyrus.tombRed.withAlphaComponent(0.3)
                config?.baseForegroundColor = UIColor.Papyrus.beige
                config?.image = UIImage(systemName: "xmark.circle.fill")
                config?.imagePlacement = .trailing
            }
            
            button.configuration = config
        }
    }
}