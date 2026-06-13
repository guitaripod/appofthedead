import UIKit

final class PathTrophyCell: UICollectionViewCell {

    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusBadge = UIImageView()

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
        containerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 2
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.12
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont(name: "Papyrus", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = UIColor.Papyrus.primaryText
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75

        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        progressView.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let stack = UIStackView(arrangedSubviews: [iconImageView, nameLabel, progressView])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stack)

        statusBadge.contentMode = .scaleAspectFit
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        containerView.addSubview(statusBadge)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconImageView.widthAnchor.constraint(equalToConstant: 44),
            iconImageView.heightAnchor.constraint(equalToConstant: 44),

            stack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),

            progressView.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 4),
            progressView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -4),

            statusBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            statusBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            statusBadge.widthAnchor.constraint(equalToConstant: 22),
            statusBadge.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    func configure(with item: PathJourneyItem) {
        let color = UIColor(hex: item.colorHex) ?? UIColor.Papyrus.hieroglyphBlue
        iconImageView.image = IconProvider.beliefSystemIcon(for: item.iconName, color: color)
        iconImageView.tintColor = color
        nameLabel.text = item.name
        progressView.progress = item.progressFraction
        progressView.progressTintColor = color

        switch item.status {
        case .mastered:
            containerView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            statusBadge.isHidden = false
            statusBadge.image = UIImage(systemName: "crown.fill")
            statusBadge.tintColor = UIColor.Papyrus.gold
        case .completed:
            containerView.layer.borderColor = color.cgColor
            statusBadge.isHidden = false
            statusBadge.image = UIImage(systemName: "checkmark.circle.fill")
            statusBadge.tintColor = UIColor.Papyrus.scarabGreen
        default:
            containerView.layer.borderColor = color.cgColor
            statusBadge.isHidden = true
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "\(item.name), \(item.statusLabel), \(Int((item.progressFraction * 100).rounded())) percent complete"
        accessibilityHint = "Double tap for details"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        nameLabel.text = nil
        progressView.progress = 0
        statusBadge.isHidden = true
        statusBadge.image = nil
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
    }
}
