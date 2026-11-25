import UIKit

/// Stands in for the Oracle on a device whose GPU cannot run the model at all. It has no
/// controls: nothing can be downloaded that would work, so the screen says why and leaves
/// the rest of the app alone.
final class OracleUnavailableView: UIView {

    private let panel = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let goldEdge = UIView()
    private let stack = UIStackView()
    private let kicker = UILabel()
    private let titleLabel = UILabel()
    private let supporting = UILabel()

    private static let ink = UIColor(red: 245/255, green: 240/255, blue: 226/255, alpha: 1)

    init() {
        super.init(frame: .zero)
        backgroundColor = PapyrusDesignSystem.Colors.Core.night
        setupPanel()
        setupLabels()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupPanel() {
        panel.overrideUserInterfaceStyle = .dark
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.layer.cornerRadius = 28
        panel.layer.cornerCurve = .continuous
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        addSubview(panel)

        goldEdge.translatesAutoresizingMaskIntoConstraints = false
        goldEdge.backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.55)
        panel.contentView.addSubview(goldEdge)
    }

    private func setupLabels() {
        kicker.attributedText = NSAttributedString(string: String(localized: "THE ORACLE CANNOT AWAKEN HERE"), attributes: [
            .font: PapyrusDesignSystem.Typography.caption2(weight: .semibold),
            .foregroundColor: Self.ink.withAlphaComponent(0.7),
            .kern: 2.5
        ])
        kicker.numberOfLines = 1

        titleLabel.text = String(localized: "This device is too old for the Oracle.")
        titleLabel.font = PapyrusDesignSystem.Typography.largeTitle(weight: .bold)
        titleLabel.textColor = Self.ink
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85

        supporting.text = String(localized: "The Oracle needs Apple Intelligence or an iPhone 12 or later to run its model on the device. Everything else in the app works here.")
        supporting.font = PapyrusDesignSystem.Typography.body()
        supporting.textColor = Self.ink.withAlphaComponent(0.82)
        supporting.numberOfLines = 0
    }

    private func setupLayout() {
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20)
        stack.addArrangedSubview(kicker)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(supporting)
        stack.setCustomSpacing(20, after: supporting)
        panel.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.contentView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            goldEdge.topAnchor.constraint(equalTo: panel.contentView.topAnchor),
            goldEdge.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            goldEdge.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),
            goldEdge.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
