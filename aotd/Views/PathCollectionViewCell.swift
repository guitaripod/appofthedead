import UIKit

final class PathCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.Papyrus.aged.cgColor
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.Papyrus.primaryText
        imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        if let papyrusFont = UIFont(name: "Papyrus", size: 17) {
            label.font = papyrusFont
        } else {
            label.font = .systemFont(ofSize: 17, weight: .semibold)
        }
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        view.heightAnchor.constraint(equalToConstant: 8).isActive = true
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        return view
    }()
    
    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.Papyrus.secondaryText
        return label
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconImageView, nameLabel, progressView, xpLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        stack.setCustomSpacing(12, after: nameLabel)
        stack.setCustomSpacing(4, after: progressView)
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    private lazy var lockOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.Papyrus.ink.withAlphaComponent(0.7)
        view.layer.cornerRadius = 16
        view.isHidden = true
        return view
    }()
    
    private lazy var lockIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return imageView
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        containerView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIconImageView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            lockOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            lockIconImageView.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIconImageView.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with item: PathItem) {
        // Set icon using IconProvider
        iconImageView.image = IconProvider.beliefSystemIcon(for: item.icon, color: item.color)
        
        nameLabel.text = item.name
        
        if item.isUnlocked {
            containerView.backgroundColor = UIColor.Papyrus.cardBackground
            containerView.layer.borderColor = item.color.cgColor
            containerView.layer.borderWidth = 2
            nameLabel.textColor = UIColor.Papyrus.primaryText
            progressView.progressTintColor = item.color
            iconImageView.tintColor = item.color
        } else {
            containerView.backgroundColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
            containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            containerView.layer.borderWidth = 1.5
            nameLabel.textColor = UIColor.Papyrus.tertiaryText
            progressView.progressTintColor = UIColor.Papyrus.aged
            iconImageView.tintColor = UIColor.Papyrus.aged
        }
        
        progressView.progress = item.progress
        xpLabel.text = "\(item.currentXP) / \(item.totalXP) XP"
        
        lockOverlay.isHidden = item.isUnlocked
        
        if !item.isUnlocked {
            containerView.layer.shadowOpacity = 0.08
        } else {
            containerView.layer.shadowOpacity = 0.15
        }
        
        // Force layout update to ensure proper alignment
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        iconImageView.tintColor = UIColor.Papyrus.primaryText
        nameLabel.text = nil
        nameLabel.textColor = UIColor.Papyrus.primaryText
        progressView.progress = 0
        progressView.progressTintColor = UIColor.Papyrus.hieroglyphBlue
        xpLabel.text = nil
        lockOverlay.isHidden = true
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.borderWidth = 1.5
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
    }
}