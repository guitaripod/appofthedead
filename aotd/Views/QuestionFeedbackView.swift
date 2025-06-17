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
        containerView.backgroundColor = isCorrect ? UIColor.Papyrus.scarabGreen : UIColor.Papyrus.tombRed
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.25
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 12
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = isCorrect ? UIColor.Papyrus.gold.cgColor : UIColor.Papyrus.aged.cgColor
        
        addSubview(containerView)
        
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = isCorrect ? "✓" : "✗"
        iconLabel.font = .systemFont(ofSize: 48, weight: .bold)
        iconLabel.textColor = UIColor.Papyrus.beige
        iconLabel.textAlignment = .center
        
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.text = isCorrect ? "Correct!" : "Not quite right"
        resultLabel.font = .systemFont(ofSize: 24, weight: .bold)
        resultLabel.textColor = UIColor.Papyrus.beige
        resultLabel.textAlignment = .center
        
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        explanationLabel.text = explanation
        explanationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        explanationLabel.textColor = UIColor.Papyrus.beige
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
            xpLabel.font = .systemFont(ofSize: 20, weight: .bold)
            xpLabel.textColor = UIColor.Papyrus.gold
            xpLabel.layer.shadowColor = UIColor.black.cgColor
            xpLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
            xpLabel.layer.shadowOpacity = 0.3
            xpLabel.layer.shadowRadius = 2
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