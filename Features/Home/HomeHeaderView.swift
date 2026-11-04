import UIKit
import AppOfTheDeadCore

/// The top of Home: the title and the person's standing, the Premium Week countdown, the Judgment, the day's omen,
/// and the heading over the paths.
final class HomeHeaderView: UICollectionReusableView {
    weak var delegate: HomeHeaderViewDelegate?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "App of the Dead")
        label.font = PapyrusDesignSystem.Typography.serif(34, weight: .bold, textStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.accessibilityTraits = .header
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "What every culture believes comes after")
        label.font = PapyrusDesignSystem.Typography.sans(15, weight: .medium, textStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private lazy var profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.6).cgColor
        button.tintColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        button.setImage(UIImage(systemName: "person.fill"), for: .normal)
        button.accessibilityLabel = String(localized: "Profile")
        button.addAction(UIAction { [weak self] _ in self?.delegate?.profileButtonTapped() }, for: .touchUpInside)
        return button
    }()

    private let xpLabel = UILabel()
    private let streakLabel = UILabel()
    private let statsRow = UIStackView()
    private let dynamicStack = UIStackView()

    private lazy var mainStack: UIStackView = {
        let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titles.axis = .vertical
        titles.spacing = 2
        let top = UIStackView(arrangedSubviews: [titles, profileButton])
        top.alignment = .center
        top.spacing = 12
        let stack = UIStackView(arrangedSubviews: [top, statsRow, dynamicStack])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 4, bottom: 12, right: 4)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        statsRow.axis = .horizontal
        statsRow.spacing = 8
        statsRow.alignment = .center
        dynamicStack.axis = .vertical
        dynamicStack.spacing = 14
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ dashboard: HomeDashboard) {
        statsRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsRow.addArrangedSubview(statPill(symbol: "star.fill", value: "\(dashboard.xp)", caption: String(localized: "XP"), color: PapyrusDesignSystem.Colors.Core.goldLeaf))
        statsRow.addArrangedSubview(statPill(symbol: "flame.fill", value: "\(dashboard.streak)", caption: String(localized: "Day Streak"), color: UIColor(hex: 0xF07E62)))
        statsRow.addArrangedSubview(UIView())

        dynamicStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let days = dashboard.premiumWeekDaysLeft {
            let chip = PremiumWeekChip(daysLeft: days)
            chip.addAction(UIAction { [weak self] _ in self?.delegate?.premiumWeekTapped() }, for: .touchUpInside)
            let row = UIStackView(arrangedSubviews: [chip, UIView()])
            dynamicStack.addArrangedSubview(row)
            dynamicStack.setCustomSpacing(12, after: row)
        }
        let judgment = JudgmentHomeCard(verdict: dashboard.verdict)
        judgment.onOpen = { [weak self] in self?.delegate?.judgmentCardTapped(reviewing: true) }
        judgment.onRetake = { [weak self] in self?.delegate?.judgmentCardTapped(reviewing: false) }
        dynamicStack.addArrangedSubview(judgment)
        if let omen = dashboard.omen {
            let card = DailyOmenCard(omen: omen, answer: dashboard.omenAnswer)
            card.onAnswer = { [weak self] choice in self?.delegate?.dailyOmenAnswered(choice, omen: omen) }
            card.onOpenPath = { [weak self] in self?.delegate?.dailyOmenPathTapped(omen.pathId) }
            dynamicStack.addArrangedSubview(card)
        }
        let pathsHeading = makeEyebrowLabel(String(localized: "Twenty-two paths"), color: PapyrusDesignSystem.Colors.Dynamic.tertiaryText, alignment: .natural)
        dynamicStack.addArrangedSubview(pathsHeading)
        dynamicStack.setCustomSpacing(4, after: pathsHeading)
    }

    private func statPill(symbol: String, value: String, caption: String, color: UIColor) -> UIView {
        let pill = UIView()
        pill.backgroundColor = PapyrusDesignSystem.Colors.Core.surface
        pill.layer.cornerRadius = 16
        pill.layer.borderWidth = 1
        pill.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = color
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let number = UILabel()
        number.text = value
        number.font = PapyrusDesignSystem.Typography.rounded(15, weight: .bold, textStyle: .subheadline)
        number.adjustsFontForContentSizeCategory = true
        number.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        let label = UILabel()
        label.text = caption
        label.font = PapyrusDesignSystem.Typography.sans(12, weight: .medium, textStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        let row = UIStackView(arrangedSubviews: [icon, number, label])
        row.spacing = 5
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            row.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            row.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),
        ])
        pill.isAccessibilityElement = true
        pill.accessibilityLabel = "\(value) \(caption)"
        return pill
    }
}

protocol HomeHeaderViewDelegate: AnyObject {
    func profileButtonTapped()
    func premiumWeekTapped()
    func judgmentCardTapped(reviewing: Bool)
    func dailyOmenAnswered(_ choice: String, omen: DailyOmen)
    func dailyOmenPathTapped(_ pathId: String)
}
