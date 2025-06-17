import UIKit

final class AchievementNotificationView: UIView {
    
    private let achievementImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let backgroundView = UIView()
    
    init(achievement: Achievement) {
        super.init(frame: .zero)
        setupUI()
        configure(with: achievement)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.3
        clipsToBounds = false
        
        backgroundView.backgroundColor = UIColor.Papyrus.cardBackground
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.borderWidth = 2
        backgroundView.layer.borderColor = UIColor.Papyrus.gold.cgColor
        backgroundView.clipsToBounds = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        
        let contentView = backgroundView
        
        // Setup achievement image
        achievementImageView.contentMode = .scaleAspectFit
        achievementImageView.image = UIImage(systemName: "star.fill")
        achievementImageView.tintColor = UIColor.Papyrus.gold
        achievementImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(achievementImageView)
        
        // Setup title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor.Papyrus.ink
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Setup description
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        descriptionLabel.textColor = UIColor.Papyrus.secondaryText
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            achievementImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            achievementImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            achievementImageView.widthAnchor.constraint(equalToConstant: 40),
            achievementImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: achievementImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    private func configure(with achievement: Achievement) {
        titleLabel.text = achievement.name
        descriptionLabel.text = achievement.description
        
        // Use different icons based on achievement type
        let iconName: String
        switch achievement.criteria.type {
        case .totalXP:
            iconName = "star.fill"
        case .correctQuestions:
            iconName = "checkmark.circle.fill"
        case .completePath:
            iconName = "flag.fill"
        case .completeMultiplePaths, .completeAllPaths:
            iconName = "crown.fill"
        case .perfectMasteryTest:
            iconName = "medal.fill"
        case .completeLesson:
            iconName = "book.fill"
        }
        
        achievementImageView.image = UIImage(systemName: iconName)
    }
    
    // MARK: - Animation Methods
    
    func showAnimated(in parentView: UIView, completion: @escaping () -> Void) {
        translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20),
            topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // Initial state
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -100)
        
        // Animate in
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.alpha = 1
            self.transform = .identity
        }) { _ in
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.hideAnimated(completion: completion)
            }
        }
        
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func hideAnimated(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -50)
        }) { _ in
            self.removeFromSuperview()
            completion()
        }
    }
}