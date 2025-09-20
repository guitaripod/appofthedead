import UIKit
extension ProfileViewController {
    func updateLayoutForIPad() {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        if AdaptiveLayoutManager.shared.isRegularWidth(traitCollection) {
            setupIPadLayout()
            enhanceVisualElements()
            addPointerInteractions()
        }
    }
    private func setupIPadLayout() {
        let layoutManager = AdaptiveLayoutManager.shared
        let insets = layoutManager.contentInsets(for: traitCollection)
        scrollView.contentInset = UIEdgeInsets(
            top: insets.top,
            left: 0,
            bottom: insets.bottom,
            right: 0
        )
        if layoutManager.screenWidth > 1024 {
            let maxWidth: CGFloat = 800
            let horizontalPadding = (layoutManager.screenWidth - maxWidth) / 2
            contentStackView.constraints.forEach { constraint in
                if constraint.firstAttribute == .leading {
                    constraint.constant = max(20, horizontalPadding)
                } else if constraint.firstAttribute == .trailing {
                    constraint.constant = min(-20, -horizontalPadding)
                }
            }
        }
        contentStackView.spacing = layoutManager.spacing(for: .extraLarge, traitCollection: traitCollection)
        if let layout = achievementsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let columns = layoutManager.gridColumnCount(for: traitCollection)
            let spacing = layoutManager.spacing(for: .medium, traitCollection: traitCollection)
            let width = (layoutManager.screenWidth - (spacing * CGFloat(columns + 1))) / CGFloat(columns)
            layout.itemSize = CGSize(width: width, height: width * 1.2)
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.sectionInset = UIEdgeInsets(
                top: spacing,
                left: spacing,
                bottom: spacing,
                right: spacing
            )
        }
    }
    private func enhanceVisualElements() {
        let layoutManager = AdaptiveLayoutManager.shared
        if layoutManager.isIPad {
            for constraint in avatarImageView.superview?.constraints ?? [] {
                if (constraint.firstItem as? UIView) == avatarImageView {
                    if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                        constraint.constant = 120 
                    }
                }
            }
            avatarImageView.layer.cornerRadius = 60
        }
        for view in [profileHeaderView, statsContainerView] {
            let shadow = PapyrusDesignSystem.Shadow.elevated()
            view.layer.shadowColor = shadow.color
            view.layer.shadowOpacity = shadow.opacity
            view.layer.shadowOffset = shadow.offset
            view.layer.shadowRadius = shadow.radius
        }
        updateFontsForIPad()
    }
    private func updateFontsForIPad() {
        nameLabel.font = PapyrusDesignSystem.Typography.largeTitle(for: traitCollection)
        levelLabel.font = PapyrusDesignSystem.Typography.title2(for: traitCollection)
        xpLabel.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
        achievementsHeaderLabel.font = PapyrusDesignSystem.Typography.title1(for: traitCollection)
        statsStackView.arrangedSubviews.forEach { statCard in
            if let stackView = statCard as? UIStackView {
                stackView.arrangedSubviews.forEach { view in
                    if let label = view as? UILabel {
                        if label.font.pointSize > 20 {
                            label.font = PapyrusDesignSystem.Typography.largeTitle(for: traitCollection)
                        } else {
                            label.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
                        }
                    }
                }
            }
        }
    }
    private func addPointerInteractions() {
        if #available(iOS 13.4, *) {
            statsStackView.arrangedSubviews.forEach { view in
                view.addCardPointerInteraction()
            }
            achievementsCollectionView.visibleCells.forEach { cell in
                cell.addCardPointerInteraction()
            }
            profileHeaderView.addCardPointerInteraction()
        }
    }
    func updateForTraitCollection() {
        updateLayoutForIPad()
    }
}
final class AchievementBadgeCellIPad: UICollectionViewCell {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let progressView = UIProgressView()
    private let progressLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    private let layoutManager = AdaptiveLayoutManager.shared
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        contentView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        containerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        containerView.layer.borderWidth = 2
        contentView.addSubview(containerView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
        nameLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        containerView.addSubview(nameLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = PapyrusDesignSystem.Typography.footnote(for: traitCollection)
        descriptionLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2
        descriptionLabel.isHidden = !layoutManager.isIPad
        containerView.addSubview(descriptionLabel)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = PapyrusDesignSystem.Colors.goldLeaf
        progressView.trackTintColor = PapyrusDesignSystem.Colors.aged.withAlphaComponent(0.3)
        containerView.addSubview(progressView)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = PapyrusDesignSystem.Typography.caption2(for: traitCollection)
        progressLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        progressLabel.textAlignment = .center
        containerView.addSubview(progressLabel)
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.image = UIImage(systemName: "checkmark.seal.fill")
        checkmarkImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        checkmarkImageView.isHidden = true
        containerView.addSubview(checkmarkImageView)
        let spacing = layoutManager.spacing(for: .small, traitCollection: traitCollection)
        let iconSize: CGFloat = layoutManager.isIPad ? 60 : 50
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: spacing),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: spacing),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            progressView.bottomAnchor.constraint(equalTo: progressLabel.topAnchor, constant: -4),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            progressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            progressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -spacing),
            checkmarkImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: spacing/2),
            checkmarkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing/2),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        if layoutManager.isIPad {
            let shadow = PapyrusDesignSystem.Shadow.papyrus()
            containerView.layer.shadowColor = shadow.color
            containerView.layer.shadowOpacity = shadow.opacity
            containerView.layer.shadowOffset = shadow.offset
            containerView.layer.shadowRadius = shadow.radius
        }
    }
    func configure(with achievement: Achievement, progress: Float) {
        nameLabel.text = achievement.name
        descriptionLabel.text = achievement.description
        iconImageView.image = UIImage(systemName: achievement.icon)
        progressView.progress = progress
        progressLabel.text = "\(Int(progress * 100))%"
        let isCompleted = progress >= 1.0
        checkmarkImageView.isHidden = !isCompleted
        if isCompleted {
            containerView.layer.borderColor = PapyrusDesignSystem.Colors.goldLeaf.cgColor
            iconImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
            containerView.backgroundColor = PapyrusDesignSystem.Colors.goldLeaf.withAlphaComponent(0.1)
        } else {
            containerView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
            iconImageView.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
            containerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        }
        if #available(iOS 13.4, *) {
            addCardPointerInteraction()
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if progressView.progress < 1.0 {
                containerView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
            }
        }
        descriptionLabel.isHidden = !layoutManager.isIPad || 
                                   !layoutManager.isRegularWidth(traitCollection)
    }
}