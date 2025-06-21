import UIKit

final class PathListCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    private var isShowingPreview = false
    private var pathPreview: PathPreview?
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.Papyrus.aged.cgColor
        return view
    }()
    
    private lazy var iconContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        if let papyrusFont = UIFont(name: "Papyrus", size: 17) {
            label.font = papyrusFont
        } else {
            label.font = .systemFont(ofSize: 17, weight: .semibold)
        }
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.Papyrus.secondaryText
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        return view
    }()
    
    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textAlignment = .right
        label.textColor = UIColor.Papyrus.secondaryText
        return label
    }()
    
    private lazy var statusBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.backgroundColor = UIColor.systemGreen
        view.isHidden = true
        return view
    }()
    
    private lazy var statusIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var lockIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = UIColor.Papyrus.aged
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor.Papyrus.tertiaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var previewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.Papyrus.aged.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    
    private lazy var previewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.Papyrus.secondaryText
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.tintColor = UIColor.Papyrus.secondaryText
        button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Stack Views
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()
    
    private lazy var progressStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [progressView, xpLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        return stack
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
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        iconContainerView.addSubview(iconImageView)
        
        containerView.addSubview(iconContainerView)
        containerView.addSubview(textStackView)
        containerView.addSubview(progressStackView)
        containerView.addSubview(statusBadge)
        containerView.addSubview(lockIconImageView)
        containerView.addSubview(chevronImageView)
        containerView.addSubview(infoButton)
        containerView.addSubview(previewContainer)
        
        previewContainer.addSubview(previewLabel)
        
        statusBadge.addSubview(statusIcon)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Icon container
            iconContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 40),
            iconContainerView.heightAnchor.constraint(equalToConstant: 40),
            
            // Icon
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Text stack
            textStackView.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 12),
            textStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -8),
            
            // Progress stack
            progressStackView.leadingAnchor.constraint(equalTo: textStackView.leadingAnchor),
            progressStackView.topAnchor.constraint(equalTo: textStackView.bottomAnchor, constant: 8),
            progressStackView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            // Status badge
            statusBadge.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            statusBadge.centerYAnchor.constraint(equalTo: textStackView.centerYAnchor),
            statusBadge.widthAnchor.constraint(equalToConstant: 24),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Status icon
            statusIcon.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusIcon.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Lock icon
            lockIconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            lockIconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            lockIconImageView.widthAnchor.constraint(equalToConstant: 20),
            lockIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Info button
            infoButton.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            infoButton.centerYAnchor.constraint(equalTo: textStackView.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 22),
            infoButton.heightAnchor.constraint(equalToConstant: 22),
            
            // Chevron
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Preview container
            previewContainer.leadingAnchor.constraint(equalTo: textStackView.leadingAnchor),
            previewContainer.topAnchor.constraint(equalTo: progressStackView.bottomAnchor, constant: 8),
            previewContainer.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            // Preview label
            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 8),
            previewLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -8),
            previewLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 6),
            previewLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -6)
        ])
        
        // Add flexible bottom constraint with priority
        let bottomConstraint = previewContainer.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
        
        // Add progress view height constraint with priority
        let progressHeightConstraint = progressView.heightAnchor.constraint(equalToConstant: 6)
        progressHeightConstraint.priority = .defaultHigh
        progressHeightConstraint.isActive = true
    }
    
    // MARK: - Configuration
    
    func configure(with item: PathItem, preview: PathPreview? = nil) {
        nameLabel.text = item.name
        self.pathPreview = preview
        
        // Set description based on status
        switch item.status {
        case .notStarted:
            descriptionLabel.text = "Ready to begin your journey"
        case .inProgress:
            let percentage = Int(item.progress * 100)
            descriptionLabel.text = "\(percentage)% complete"
        case .completed:
            descriptionLabel.text = "Path completed"
        case .mastered:
            descriptionLabel.text = "Path mastered"
        }
        
        if item.isUnlocked {
            containerView.backgroundColor = UIColor.Papyrus.cardBackground
            containerView.layer.borderColor = item.color.withAlphaComponent(0.5).cgColor
            containerView.layer.borderWidth = 1.5
            nameLabel.textColor = UIColor.Papyrus.primaryText
            progressView.progressTintColor = item.color
            chevronImageView.tintColor = UIColor.Papyrus.secondaryText
            
            // Set icon with color background
            iconContainerView.backgroundColor = item.color.withAlphaComponent(0.9)
            iconImageView.image = IconProvider.beliefSystemIcon(for: item.icon, color: .white)
            iconImageView.tintColor = .white
            iconImageView.isHidden = false
            lockIconImageView.isHidden = true
            infoButton.isHidden = false
        } else {
            containerView.backgroundColor = UIColor.Papyrus.aged.withAlphaComponent(0.2)
            containerView.layer.borderColor = UIColor.Papyrus.aged.withAlphaComponent(0.5).cgColor
            containerView.layer.borderWidth = 1
            nameLabel.textColor = UIColor.Papyrus.tertiaryText
            descriptionLabel.text = "Locked"
            progressView.progressTintColor = UIColor.Papyrus.aged
            chevronImageView.tintColor = UIColor.Papyrus.aged
            
            // Show lock icon
            iconContainerView.backgroundColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
            iconImageView.isHidden = true
            lockIconImageView.isHidden = false
            infoButton.isHidden = true
        }
        
        progressView.progress = item.progress
        xpLabel.text = "\(item.currentXP) / \(item.totalXP) XP"
        
        // Configure status badge
        switch item.status {
        case .completed:
            statusBadge.isHidden = false
            statusBadge.backgroundColor = item.color
            statusIcon.image = UIImage(systemName: "checkmark")
        case .mastered:
            statusBadge.isHidden = false
            statusBadge.backgroundColor = UIColor.systemYellow
            statusIcon.image = UIImage(systemName: "crown.fill")
        default:
            statusBadge.isHidden = true
        }
        
        // Adjust shadow opacity
        containerView.layer.shadowOpacity = item.isUnlocked ? 0.1 : 0.05
        
        // Configure preview if available
        if let preview = preview {
            let topicsText = preview.keyTopics.prefix(3).joined(separator: " • ")
            previewLabel.text = topicsText
        }
    }
    
    // MARK: - Actions
    
    @objc private func infoButtonTapped() {
        togglePreview()
    }
    
    private func togglePreview() {
        isShowingPreview.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.previewContainer.isHidden = !self.isShowingPreview
            self.previewContainer.alpha = self.isShowingPreview ? 1 : 0
            
            // Animate info button rotation
            let rotation = self.isShowingPreview ? CGFloat.pi : 0
            self.infoButton.transform = CGAffineTransform(rotationAngle: rotation)
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        iconImageView.isHidden = false
        lockIconImageView.isHidden = true
        nameLabel.text = nil
        descriptionLabel.text = nil
        progressView.progress = 0
        xpLabel.text = nil
        statusBadge.isHidden = true
        statusIcon.image = nil
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.borderWidth = 1
        previewContainer.isHidden = true
        previewContainer.alpha = 0
        isShowingPreview = false
        infoButton.transform = .identity
        infoButton.isHidden = false
        pathPreview = nil
    }
    
    // MARK: - Touch Feedback
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.1) {
                    self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                    self.containerView.layer.shadowOpacity = 0.15
                }
            } else {
                UIView.animate(withDuration: 0.1) {
                    self.containerView.transform = .identity
                    self.containerView.layer.shadowOpacity = 0.1
                }
            }
        }
    }
}