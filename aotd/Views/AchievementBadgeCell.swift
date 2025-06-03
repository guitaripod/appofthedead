import UIKit

final class AchievementBadgeCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressView = UIProgressView()
    private let overlayView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        // Container
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Progress
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)
        
        // Overlay for locked achievements
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlayView.layer.cornerRadius = 12
        overlayView.isHidden = true
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func configure(with achievement: Achievement, userAchievement: UserAchievement) {
        titleLabel.text = achievement.name
        progressView.progress = Float(userAchievement.progress)
        
        // Set icon based on achievement type
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
        iconImageView.image = UIImage(systemName: iconName)
        
        // Update appearance based on completion status
        if userAchievement.isCompleted {
            // Completed achievement
            containerView.layer.borderColor = UIColor.systemYellow.cgColor
            iconImageView.tintColor = .systemYellow
            progressView.progressTintColor = .systemYellow
            titleLabel.textColor = .label
            overlayView.isHidden = true
            
            // Add shine effect for completed achievements
            containerView.backgroundColor = .systemYellow.withAlphaComponent(0.1)
        } else if userAchievement.progress > 0 {
            // In progress achievement
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            iconImageView.tintColor = .systemBlue
            progressView.progressTintColor = .systemBlue
            titleLabel.textColor = .label
            overlayView.isHidden = true
            containerView.backgroundColor = .secondarySystemBackground
        } else {
            // Locked achievement
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            iconImageView.tintColor = .systemGray3
            progressView.progressTintColor = .systemGray4
            titleLabel.textColor = .secondaryLabel
            overlayView.isHidden = false
            containerView.backgroundColor = .secondarySystemBackground
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        progressView.progress = 0
        overlayView.isHidden = true
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.backgroundColor = .secondarySystemBackground
    }
}