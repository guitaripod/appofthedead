import UIKit

final class QuestionFeedbackView: UIView {
    
    private let containerView = UIView()
    private let iconLabel = UILabel()
    private let resultLabel = UILabel()
    private let explanationLabel = UILabel()
    private let xpLabel = UILabel()
    
    init(isCorrect: Bool, explanation: String, xpReward: Int) {
        super.init(frame: .zero)
        setupUI(isCorrect: isCorrect, explanation: explanation, xpReward: xpReward)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(isCorrect: Bool, explanation: String, xpReward: Int) {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = isCorrect ? UIColor.systemGreen.withAlphaComponent(0.95) : UIColor.systemRed.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        
        addSubview(containerView)
        
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = isCorrect ? "✓" : "✗"
        iconLabel.font = .systemFont(ofSize: 48, weight: .bold)
        iconLabel.textColor = .white
        iconLabel.textAlignment = .center
        
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.text = isCorrect ? "Correct!" : "Not quite right"
        resultLabel.font = .systemFont(ofSize: 24, weight: .bold)
        resultLabel.textColor = .white
        resultLabel.textAlignment = .center
        
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        explanationLabel.text = explanation
        explanationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        explanationLabel.textColor = .white
        explanationLabel.textAlignment = .center
        explanationLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [iconLabel, resultLabel, explanationLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        if isCorrect && xpReward > 0 {
            xpLabel.translatesAutoresizingMaskIntoConstraints = false
            xpLabel.text = "+\(xpReward) XP"
            xpLabel.font = .systemFont(ofSize: 20, weight: .semibold)
            xpLabel.textColor = .white
            xpLabel.textAlignment = .center
            stackView.addArrangedSubview(xpLabel)
        }
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32)
        ])
    }
}