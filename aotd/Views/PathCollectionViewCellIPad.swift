import UIKit
final class PathCollectionViewCellIPad: UICollectionViewCell {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let progressView = UIProgressView()
    private let progressLabel = UILabel()
    private let lockOverlay = UIView()
    private let lockImageView = UIImageView()
    private let statusBadge = UILabel()
    private let statsStackView = UIStackView()
    private let lessonsLabel = UILabel()
    private let xpLabel = UILabel()
    private let difficultyLabel = UILabel()
    private var pathItem: PathItem?
    private let layoutManager = AdaptiveLayoutManager.shared
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupViews() {
        contentView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        containerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        containerView.layer.borderWidth = 1.5
        containerView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        contentView.addSubview(containerView)
        if layoutManager.isIPad {
            let shadow = PapyrusDesignSystem.Shadow.papyrus()
            containerView.layer.shadowColor = shadow.color
            containerView.layer.shadowOpacity = shadow.opacity
            containerView.layer.shadowOffset = shadow.offset
            containerView.layer.shadowRadius = shadow.radius
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        containerView.addSubview(iconImageView)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = PapyrusDesignSystem.Typography.title3(for: traitCollection)
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = PapyrusDesignSystem.Typography.footnote(for: traitCollection)
        descriptionLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textAlignment = .center
        containerView.addSubview(descriptionLabel)
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .horizontal
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 8
        containerView.addSubview(statsStackView)
        lessonsLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        lessonsLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        lessonsLabel.textAlignment = .center
        statsStackView.addArrangedSubview(lessonsLabel)
        xpLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        xpLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        xpLabel.textAlignment = .center
        statsStackView.addArrangedSubview(xpLabel)
        difficultyLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        difficultyLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        difficultyLabel.textAlignment = .center
        statsStackView.addArrangedSubview(difficultyLabel)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = PapyrusDesignSystem.Colors.goldLeaf
        progressView.trackTintColor = PapyrusDesignSystem.Colors.aged.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        containerView.addSubview(progressView)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = PapyrusDesignSystem.Typography.caption2(for: traitCollection)
        progressLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        progressLabel.textAlignment = .center
        containerView.addSubview(progressLabel)
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.font = PapyrusDesignSystem.Typography.caption1(weight: .bold, for: traitCollection)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 12
        statusBadge.clipsToBounds = true
        statusBadge.isHidden = true
        containerView.addSubview(statusBadge)
        lockOverlay.translatesAutoresizingMaskIntoConstraints = false
        lockOverlay.backgroundColor = PapyrusDesignSystem.Colors.ancientInk.withAlphaComponent(0.7)
        lockOverlay.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        lockOverlay.isHidden = true
        containerView.addSubview(lockOverlay)
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        lockImageView.image = UIImage(systemName: "lock.fill")
        lockImageView.tintColor = PapyrusDesignSystem.Colors.beige
        lockImageView.contentMode = .scaleAspectFit
        lockOverlay.addSubview(lockImageView)
    }
    private func setupConstraints() {
        let spacing = layoutManager.spacing(for: .medium, traitCollection: traitCollection)
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
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: spacing/2),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            statsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: spacing/2),
            statsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            statsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            progressView.bottomAnchor.constraint(equalTo: progressLabel.topAnchor, constant: -4),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            progressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            progressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -spacing),
            statusBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: spacing/2),
            statusBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing/2),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            lockOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            lockImageView.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 40),
            lockImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        if !layoutManager.isIPad {
            descriptionLabel.isHidden = true
            statsStackView.isHidden = true
        }
    }
    func configure(with item: PathItem, preview: PathPreview?) {
        self.pathItem = item
        titleLabel.text = item.name
        iconImageView.image = UIImage(systemName: item.icon)
        if layoutManager.isIPad {
            descriptionLabel.text = "Explore the ancient wisdom"
            descriptionLabel.isHidden = false
            lessonsLabel.text = "12 lessons"
            xpLabel.text = "\(item.totalXP) XP"
            difficultyLabel.text = "Intermediate"
            statsStackView.isHidden = false
        }
        let color = item.color
        iconImageView.tintColor = color
        progressView.progressTintColor = color
        containerView.layer.borderColor = item.isUnlocked ? 
            color.withAlphaComponent(0.3).cgColor : 
            PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        progressView.setProgress(item.progress, animated: false)
        progressLabel.text = "\(Int(item.progress * 100))% Complete"
        lockOverlay.isHidden = item.isUnlocked
        containerView.alpha = item.isUnlocked ? 1.0 : 0.7
        updateStatusBadge(for: item.status)
        updateFonts()
    }
    private func updateStatusBadge(for status: Progress.ProgressStatus) {
        switch status {
        case .completed:
            statusBadge.text = "DONE"
            statusBadge.backgroundColor = PapyrusDesignSystem.Colors.scarabGreen
            statusBadge.textColor = .white
            statusBadge.isHidden = false
        case .mastered:
            statusBadge.text = "MASTER"
            statusBadge.backgroundColor = PapyrusDesignSystem.Colors.goldLeaf
            statusBadge.textColor = PapyrusDesignSystem.Colors.ancientInk
            statusBadge.isHidden = false
        default:
            statusBadge.isHidden = true
        }
    }
    private func updateFonts() {
        titleLabel.font = PapyrusDesignSystem.Typography.title3(for: traitCollection)
        descriptionLabel.font = PapyrusDesignSystem.Typography.footnote(for: traitCollection)
        lessonsLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        xpLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        difficultyLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        progressLabel.font = PapyrusDesignSystem.Typography.caption2(for: traitCollection)
        statusBadge.font = PapyrusDesignSystem.Typography.caption1(weight: .bold, for: traitCollection)
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            containerView.layer.borderColor = pathItem?.isUnlocked == true ?
                pathItem?.color.withAlphaComponent(0.3).cgColor :
                PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        }
        updateFonts()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        progressView.progress = 0
        progressLabel.text = nil
        statusBadge.isHidden = true
        lockOverlay.isHidden = true
    }
}