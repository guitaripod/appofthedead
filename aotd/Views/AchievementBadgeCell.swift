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
        
        
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.Papyrus.hieroglyphBlue
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        
        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        
        progressView.progressTintColor = UIColor.Papyrus.hieroglyphBlue
        progressView.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)
        
        
        overlayView.backgroundColor = UIColor.Papyrus.ink.withAlphaComponent(0.7)
        overlayView.layer.cornerRadius = 16
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

        iconImageView.image = UIImage(systemName: achievement.icon)
        
        
        if userAchievement.isCompleted {
            
            containerView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            containerView.layer.borderWidth = 2.5
            iconImageView.tintColor = UIColor.Papyrus.gold
            progressView.progressTintColor = UIColor.Papyrus.gold
            titleLabel.textColor = UIColor.Papyrus.primaryText
            overlayView.isHidden = true
            
            
            containerView.backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.15)
            containerView.layer.shadowColor = UIColor.Papyrus.gold.cgColor
            containerView.layer.shadowOpacity = 0.3
        } else if userAchievement.progress > 0 {
            
            containerView.layer.borderColor = UIColor.Papyrus.hieroglyphBlue.cgColor
            iconImageView.tintColor = UIColor.Papyrus.hieroglyphBlue
            progressView.progressTintColor = UIColor.Papyrus.hieroglyphBlue
            titleLabel.textColor = UIColor.Papyrus.primaryText
            overlayView.isHidden = true
            containerView.backgroundColor = UIColor.Papyrus.cardBackground
        } else {
            
            containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            iconImageView.tintColor = UIColor.Papyrus.tertiaryText
            progressView.progressTintColor = UIColor.Papyrus.aged
            titleLabel.textColor = UIColor.Papyrus.tertiaryText
            overlayView.isHidden = false
            containerView.backgroundColor = UIColor.Papyrus.cardBackground
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        progressView.progress = 0
        overlayView.isHidden = true
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
    }
}