import UIKit

/// The card above the Settings list: what the person has open and, unless everything is theirs, the way to Premium.
final class SettingsMembershipCard: UIView {
    var onSeePlans: (() -> Void)?

    private let card = DashboardCardView(accent: PapyrusDesignSystem.Colors.Core.goldLeaf)
    private var membership: SettingsState.Membership?

    init() {
        super.init(frame: .zero)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ membership: SettingsState.Membership) {
        guard membership != self.membership else { return }
        self.membership = membership
        card.content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        switch membership {
        case .free:
            build(
                symbol: "sparkles",
                eyebrow: String(localized: "App of the Dead Premium"),
                title: String(localized: "Open Every Path"),
                body: String(localized: "All 21 paths, unlimited Oracle and every path still to come"),
                showsPlans: true
            )
        case .premiumWeek(let daysLeft):
            build(
                symbol: "hourglass",
                eyebrow: String(localized: "Premium Week · \(daysLeft) days left"),
                title: String(localized: "Everything Is Open"),
                body: String(localized: "Keep every path and every god open. Your progress stays exactly where you left it."),
                showsPlans: true
            )
        case .member:
            build(
                symbol: "crown.fill",
                eyebrow: String(localized: "App of the Dead Premium"),
                title: String(localized: "Everything Is Open"),
                body: String(localized: "Every path and the Oracle without limits are yours. Thank you for keeping a one-person studio going."),
                showsPlans: false
            )
        }
    }

    private func build(symbol: String, eyebrow: String, title: String, body: String, showsPlans: Bool) {
        let glyph = GlowingGlyphView(symbol: symbol, color: PapyrusDesignSystem.Colors.Core.goldLeaf, diameter: 52, pointSize: 22)
        glyph.widthAnchor.constraint(equalToConstant: 52).isActive = true
        let text = UIStackView(arrangedSubviews: [
            makeEyebrowLabel(eyebrow, alignment: .natural),
            makeSerifLabel(title, size: 22, weight: .bold, alignment: .natural),
            makeBodyLabel(body, size: 15, alignment: .natural),
        ])
        text.axis = .vertical
        text.spacing = 4
        let row = UIStackView(arrangedSubviews: [glyph, text])
        row.spacing = 14
        row.alignment = .top
        card.content.addArrangedSubview(row)
        guard showsPlans else { return }
        let button = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: button, style: .primary)
        button.configuration?.title = String(localized: "See Plans")
        button.configuration?.titleLineBreakMode = .byWordWrapping
        button.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onSeePlans?()
        }, for: .touchUpInside)
        card.content.setCustomSpacing(16, after: row)
        card.content.addArrangedSubview(button)
    }
}
