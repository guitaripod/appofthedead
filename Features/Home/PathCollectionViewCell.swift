import UIKit
final class PathCollectionViewCell: UICollectionViewCell {
    private var pathPreview: PathPreview?
    private var isShowingPreview = false
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        return view
    }()
    private lazy var iconWell: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 30
        view.widthAnchor.constraint(equalToConstant: 60).isActive = true
        view.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return view
    }()
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.Papyrus.primaryText
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        return imageView
    }()
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.serif(16, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        view.heightAnchor.constraint(equalToConstant: 6).isActive = true
        return view
    }()
    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.Papyrus.secondaryText
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
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
        imageView.tintColor = PapyrusDesignSystem.Colors.Core.ink
        return imageView
    }()
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconWell, nameLabel, progressView, xpLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        stack.setCustomSpacing(10, after: nameLabel)
        stack.setCustomSpacing(4, after: progressView)
        return stack
    }()
    private lazy var lockOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
        view.layer.cornerRadius = 13
        view.isHidden = true
        return view
    }()
    private lazy var lockIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        return imageView
    }()
    private lazy var previewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.Papyrus.aged.withAlphaComponent(0.15)
        view.layer.cornerRadius = 8
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    private lazy var previewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = UIColor.Papyrus.secondaryText
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    private lazy var mistakeBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemRed
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    private lazy var mistakeCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        iconWell.addSubview(iconImageView)
        containerView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIconImageView)
        containerView.addSubview(statusBadge)
        statusBadge.addSubview(statusIcon)
        containerView.addSubview(previewContainer)
        previewContainer.addSubview(previewLabel)
        containerView.addSubview(mistakeBadge)
        mistakeBadge.addSubview(mistakeCountLabel)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor, constant: 12),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            progressView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -16),
            nameLabel.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -8),
            iconImageView.centerXAnchor.constraint(equalTo: iconWell.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),
            lockOverlay.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            lockOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            lockOverlay.widthAnchor.constraint(equalToConstant: 26),
            lockOverlay.heightAnchor.constraint(equalToConstant: 26),
            lockIconImageView.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIconImageView.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            statusBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            statusBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            statusBadge.widthAnchor.constraint(equalToConstant: 24),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),
            statusIcon.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusIcon.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),
            previewContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            previewContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            previewContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 4),
            previewLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -4),
            previewLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 4),
            previewLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -4),
            mistakeBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            mistakeBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            mistakeBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            mistakeBadge.heightAnchor.constraint(equalToConstant: 20),
            mistakeCountLabel.centerXAnchor.constraint(equalTo: mistakeBadge.centerXAnchor),
            mistakeCountLabel.centerYAnchor.constraint(equalTo: mistakeBadge.centerYAnchor),
            mistakeCountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: mistakeBadge.leadingAnchor, constant: 4),
            mistakeCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: mistakeBadge.trailingAnchor, constant: -4)
        ])
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
    }
    func configure(with item: PathItem, preview: PathPreview? = nil) {
        self.pathPreview = preview
        iconImageView.image = IconProvider.beliefSystemIcon(for: item.icon, color: item.color, size: 28)
        nameLabel.text = item.name
        containerView.backgroundColor = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.88)
        iconWell.backgroundColor = item.color.withAlphaComponent(item.isUnlocked ? 0.16 : 0.08)
        progressView.trackTintColor = PapyrusDesignSystem.Colors.Component.Progress.track
        if item.isUnlocked {
            containerView.layer.borderColor = item.color.withAlphaComponent(0.35).cgColor
            nameLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
            progressView.progressTintColor = item.color
            iconImageView.tintColor = item.color
            iconImageView.alpha = 1
        } else {
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
            nameLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
            progressView.progressTintColor = item.color.withAlphaComponent(0.5)
            iconImageView.tintColor = item.color
            iconImageView.alpha = 0.55
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = item.isUnlocked
            ? String(localized: "\(item.name), \(item.currentXP) of \(item.totalXP) XP")
            : String(localized: "\(item.name), locked")
        progressView.progress = item.progress
        xpLabel.text = String(localized: "\(item.currentXP) / \(item.totalXP) XP")
        lockOverlay.isHidden = item.isUnlocked
        switch item.status {
        case .completed:
            statusBadge.isHidden = false
            statusBadge.backgroundColor = item.color
            statusIcon.image = UIImage(systemName: "checkmark")
        case .mastered:
            statusBadge.isHidden = false
            statusBadge.backgroundColor = PapyrusDesignSystem.Colors.Core.goldLeaf
            statusIcon.image = UIImage(systemName: "crown.fill")
        default:
            statusBadge.isHidden = true
        }
        setNeedsLayout()
        layoutIfNeeded()
        if let preview = preview, item.isUnlocked {
            let topicsText = preview.keyTopics.prefix(2).joined(separator: " • ")
            previewLabel.text = topicsText
        }
        if item.mistakeCount > 0 && item.isUnlocked {
            mistakeBadge.isHidden = false
            mistakeCountLabel.text = "\(item.mistakeCount)"
        } else {
            mistakeBadge.isHidden = true
        }
    }
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, pathPreview != nil else { return }
        togglePreview()
    }
    private func togglePreview() {
        isShowingPreview.toggle()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.previewContainer.isHidden = !self.isShowingPreview
            self.previewContainer.alpha = self.isShowingPreview ? 1 : 0
            if self.isShowingPreview {
                self.contentStackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } else {
                self.contentStackView.transform = .identity
            }
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
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
        statusBadge.isHidden = true
        statusIcon.image = nil
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        iconImageView.alpha = 1
        previewContainer.isHidden = true
        previewContainer.alpha = 0
        isShowingPreview = false
        contentStackView.transform = .identity
        pathPreview = nil
        mistakeBadge.isHidden = true
        mistakeCountLabel.text = nil
    }
}
