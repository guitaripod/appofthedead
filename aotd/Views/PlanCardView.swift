import UIKit

final class PlanCardView: UIControl {

    private let glassBackground = PapyrusDesignSystem.Glass.makeCard(interactive: true)
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let detailLabel = UILabel()
    private let badgeLabel = PaddedBadgeLabel()
    private let checkmarkView = UIImageView()

    let plan: PaywallViewModel.Plan

    init(card: PaywallViewModel.PlanCard) {
        self.plan = card.plan
        super.init(frame: .zero)
        configure(with: card)
        buildLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet { updateSelectionAppearance() }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }

    private func configure(with card: PaywallViewModel.PlanCard) {
        titleLabel.text = card.title
        titleLabel.font = PapyrusDesignSystem.Typography.headline()
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText

        priceLabel.text = card.billedPrice
        priceLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        priceLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.7

        detailLabel.text = card.detail
        detailLabel.font = PapyrusDesignSystem.Typography.footnote()
        detailLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        detailLabel.numberOfLines = 0
        detailLabel.isHidden = card.detail == nil

        switch card.badge {
        case .freeTrial(let days):
            badgeLabel.text = "\(days) DAYS FREE"
            badgeLabel.backgroundColor = PapyrusDesignSystem.Colors.Core.scarabGreen
        case .ownForever:
            badgeLabel.text = "NO SUBSCRIPTION"
            badgeLabel.backgroundColor = PapyrusDesignSystem.Colors.Core.hieroglyphBlue
        case nil:
            badgeLabel.isHidden = true
        }
        badgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .heavy)
        badgeLabel.textColor = PapyrusDesignSystem.Colors.Core.beige
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true

        checkmarkView.image = UIImage(systemName: "circle")
        checkmarkView.tintColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        checkmarkView.contentMode = .scaleAspectFit
    }

    private func buildLayout() {
        glassBackground.isUserInteractionEnabled = false
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassBackground)

        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        layer.cornerCurve = .continuous
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, badgeLabel])
        titleRow.axis = .horizontal
        titleRow.spacing = PapyrusDesignSystem.Spacing.xSmall
        titleRow.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [titleRow, priceLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        checkmarkView.isUserInteractionEnabled = false
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false

        glassBackground.contentView.addSubview(textStack)
        glassBackground.contentView.addSubview(checkmarkView)

        NSLayoutConstraint.activate([
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            textStack.topAnchor.constraint(equalTo: glassBackground.contentView.topAnchor, constant: PapyrusDesignSystem.Spacing.small),
            textStack.leadingAnchor.constraint(equalTo: glassBackground.contentView.leadingAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            textStack.bottomAnchor.constraint(equalTo: glassBackground.contentView.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.small),

            checkmarkView.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: PapyrusDesignSystem.Spacing.xSmall),
            checkmarkView.trailingAnchor.constraint(equalTo: glassBackground.contentView.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            checkmarkView.centerYAnchor.constraint(equalTo: glassBackground.contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 26),
            checkmarkView.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    private func updateSelectionAppearance() {
        layer.borderColor = isSelected
            ? PapyrusDesignSystem.Colors.Core.goldLeaf.cgColor
            : UIColor.clear.cgColor
        checkmarkView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        checkmarkView.tintColor = isSelected
            ? PapyrusDesignSystem.Colors.Core.goldLeaf
            : PapyrusDesignSystem.Colors.Dynamic.tertiaryText
    }
}

final class PaddedBadgeLabel: UILabel {

    private let insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
