import UIKit

/// What an empty conversation shows: the deity in its glow, who it is, a few questions to begin with and a way to
/// choose another guide. It centers in whatever room the keyboard leaves and scrolls when that is too little.
final class OracleWelcomeView: UIView {
    var onPrompt: ((String) -> Void)?
    var onChangeGuide: (() -> Void)?

    private let stack = UIStackView()
    private lazy var scrollView = CenteredScrollView(content: stack, maxWidth: 560, horizontalInset: 24, verticalInset: 16)
    private var renderedDeityId: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(deity: OracleViewModel.Deity) {
        guard renderedDeityId != deity.id else { return }
        renderedDeityId = deity.id
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let accent = PapyrusDesignSystem.Colors.tradition(deity.color)

        let glyph = GlowingGlyphView(symbol: UIImage(systemName: deity.avatar) == nil ? "sparkles" : deity.avatar, color: accent, diameter: 72, pointSize: 30)
        glyph.pulse()
        let eyebrow = makeEyebrowLabel(deity.tradition, color: accent)
        let name = makeSerifLabel(deity.name, size: 32, weight: .bold)
        name.accessibilityTraits = .header
        let role = makeBodyLabel(deity.role, size: 16, color: PapyrusDesignSystem.Colors.Dynamic.secondaryText)
        [glyph, eyebrow, name, role].forEach(stack.addArrangedSubview)
        stack.setCustomSpacing(16, after: glyph)
        stack.setCustomSpacing(4, after: eyebrow)
        stack.setCustomSpacing(22, after: role)

        let prompts = deity.suggestedPrompts ?? []
        if !prompts.isEmpty {
            let heading = makeEyebrowLabel(String(localized: "Begin with"), color: PapyrusDesignSystem.Colors.Dynamic.tertiaryText, alignment: .natural)
            stack.addArrangedSubview(heading)
            stack.setCustomSpacing(10, after: heading)
            for prompt in prompts.prefix(4) {
                stack.addArrangedSubview(makePromptButton(prompt, accent: accent))
            }
        }
        if let last = stack.arrangedSubviews.last {
            stack.setCustomSpacing(12, after: last)
        }
        stack.addArrangedSubview(makeChangeGuideButton())
        let disclosure = OracleDisclosureView()
        stack.addArrangedSubview(disclosure)
    }

    private func makePromptButton(_ prompt: String, accent: UIColor) -> UIView {
        let button = JudgmentAnswerButton(title: prompt, accent: accent)
        button.accessibilityHint = String(localized: "Asks this question")
        button.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onPrompt?(prompt)
        }, for: .touchUpInside)
        return button
    }

    private func makeChangeGuideButton() -> UIView {
        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Choose another guide")
        configuration.image = UIImage(systemName: "person.2.wave.2")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = PapyrusDesignSystem.Typography.sans(15, weight: .medium, textStyle: .subheadline)
            return outgoing
        }
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in self?.onChangeGuide?() }, for: .touchUpInside)
        return button
    }
}

/// The deity in the navigation bar: its emblem, its name and a chevron that opens the choice of guides.
final class OracleDeityTitleView: UIControl {
    private let emblemBackground = UIView()
    private let emblem = UIImageView()
    private let nameLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        emblemBackground.translatesAutoresizingMaskIntoConstraints = false
        emblemBackground.layer.cornerRadius = 13
        emblemBackground.isUserInteractionEnabled = false
        emblem.translatesAutoresizingMaskIntoConstraints = false
        emblem.contentMode = .scaleAspectFit
        emblem.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        emblemBackground.addSubview(emblem)
        nameLabel.font = PapyrusDesignSystem.Typography.sans(17, weight: .semibold, textStyle: .headline)
        nameLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        nameLabel.adjustsFontForContentSizeCategory = true
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        chevron.tintColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        let row = UIStackView(arrangedSubviews: [emblemBackground, nameLabel, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 7
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            emblemBackground.widthAnchor.constraint(equalToConstant: 26),
            emblemBackground.heightAnchor.constraint(equalToConstant: 26),
            emblem.centerXAnchor.constraint(equalTo: emblemBackground.centerXAnchor),
            emblem.centerYAnchor.constraint(equalTo: emblemBackground.centerYAnchor),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = String(localized: "Choose another guide")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    func configure(deity: OracleViewModel.Deity) {
        let accent = PapyrusDesignSystem.Colors.tradition(deity.color)
        emblem.image = UIImage(systemName: deity.avatar) ?? UIImage(systemName: "sparkles")
        emblem.tintColor = accent
        emblemBackground.backgroundColor = accent.withAlphaComponent(0.18)
        nameLabel.text = deity.name
        accessibilityLabel = deity.name
        invalidateIntrinsicContentSize()
        sizeToFit()
    }
}
