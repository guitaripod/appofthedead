import UIKit

/// One answer of a quiz question: a card in the Judgment style with an optional letter or symbol badge, lit in the
/// tradition's color when chosen and marked right or wrong once the answer is checked.
final class QuizOptionCard: UIControl {

    enum Badge {
        case letter(String)
        case symbol(String)
        case none
    }

    enum Layout {
        /// A full-width row: badge, words, and the verdict mark at the trailing edge.
        case row
        /// A tall tile with a large symbol above the words, for true or false.
        case tile
        /// A compact card for matching, words only.
        case compact
    }

    enum Mark: Equatable {
        case idle
        case selected
        case paired(UIColor)
        case correct
        case incorrect
        case dimmed
    }

    let title: String
    private let accent: UIColor
    private let layout: Layout
    private let badgeView = UIView()
    private let badgeLabel = UILabel()
    private let badgeImage = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let markView = UIImageView()
    private let stack = UIStackView()
    private var badgeTint: UIColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
    private(set) var mark: Mark = .idle

    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle == nil
            refreshAccessibility()
        }
    }

    var subtitleColor: UIColor = PapyrusDesignSystem.Colors.Core.scarabGreen {
        didSet { subtitleLabel.textColor = subtitleColor }
    }

    init(title: String, badge: Badge, accent: UIColor, layout: Layout = .row) {
        self.title = title
        self.accent = accent
        self.layout = layout
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        setupBadge(badge)
        setupLabels()
        setupLayout(hasBadge: !badgeView.isHidden)
        isAccessibilityElement = true
        accessibilityTraits = .button
        apply(.idle, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { animatePress() }
    }

    private func setupBadge(_ badge: Badge) {
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.layer.borderWidth = 1.5
        badgeView.isUserInteractionEnabled = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = PapyrusDesignSystem.Typography.rounded(15, weight: .bold, textStyle: .subheadline)
        badgeLabel.adjustsFontForContentSizeCategory = true
        badgeLabel.textAlignment = .center
        badgeImage.translatesAutoresizingMaskIntoConstraints = false
        badgeImage.contentMode = .scaleAspectFit
        let pointSize: CGFloat = layout == .tile ? 26 : 14
        badgeImage.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        badgeView.addSubview(badgeLabel)
        badgeView.addSubview(badgeImage)
        switch badge {
        case .letter(let letter):
            badgeLabel.text = letter
            badgeImage.isHidden = true
        case .symbol(let symbol):
            badgeImage.image = UIImage(systemName: symbol)
            badgeLabel.isHidden = true
        case .none:
            badgeView.isHidden = true
        }
        NSLayoutConstraint.activate([
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeImage.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeImage.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
        ])
    }

    private func setupLabels() {
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        switch layout {
        case .row:
            titleLabel.font = PapyrusDesignSystem.Typography.sans(17, weight: .medium, textStyle: .body)
        case .tile:
            titleLabel.font = PapyrusDesignSystem.Typography.serif(22, weight: .semibold, textStyle: .title3)
            titleLabel.textAlignment = .center
        case .compact:
            titleLabel.font = PapyrusDesignSystem.Typography.sans(15, weight: .medium, textStyle: .subheadline)
        }
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = PapyrusDesignSystem.Typography.sans(13, weight: .semibold, textStyle: .footnote)
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.isHidden = true
        markView.contentMode = .scaleAspectFit
        markView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        markView.setContentHuggingPriority(.required, for: .horizontal)
        markView.setContentCompressionResistancePriority(.required, for: .horizontal)
        markView.isHidden = true
    }

    private func setupLayout(hasBadge: Bool) {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        switch layout {
        case .row, .compact:
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 14
            if hasBadge { stack.addArrangedSubview(badgeView) }
            stack.addArrangedSubview(textStack)
            stack.addArrangedSubview(markView)
            let inset: CGFloat = layout == .row ? 16 : 12
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor, constant: inset),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
                heightAnchor.constraint(greaterThanOrEqualToConstant: layout == .row ? 60 : 52),
            ])
            badgeView.layer.cornerRadius = 15
            NSLayoutConstraint.activate([
                badgeView.widthAnchor.constraint(equalToConstant: 30),
                badgeView.heightAnchor.constraint(equalToConstant: 30),
            ])
        case .tile:
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 12
            textStack.alignment = .center
            stack.addArrangedSubview(badgeView)
            stack.addArrangedSubview(textStack)
            addSubview(markView)
            markView.translatesAutoresizingMaskIntoConstraints = false
            badgeView.layer.cornerRadius = 28
            NSLayoutConstraint.activate([
                stack.centerYAnchor.constraint(equalTo: centerYAnchor),
                stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 20),
                stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                badgeView.widthAnchor.constraint(equalToConstant: 56),
                badgeView.heightAnchor.constraint(equalToConstant: 56),
                markView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                markView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 148),
            ])
        }
    }

    /// Shows `newMark`: the chosen card glows in the tradition's color, a checked answer turns green or red with its
    /// mark, and the answers that played no part fade back.
    func apply(_ newMark: Mark, animated: Bool) {
        mark = newMark
        let style = Self.style(for: newMark, accent: accent, keepsBadgeNeutral: layout == .tile)
        let changes = {
            self.backgroundColor = style.background
            self.layer.borderColor = style.border.cgColor
            self.layer.borderWidth = style.borderWidth
            self.alpha = style.alpha
            self.badgeView.backgroundColor = style.badgeFill
            self.badgeView.layer.borderColor = style.badgeBorder.cgColor
            self.badgeLabel.textColor = style.badgeForeground
            self.badgeImage.tintColor = style.badgeForeground
            self.markView.image = style.markSymbol.flatMap { UIImage(systemName: $0) }
            self.markView.tintColor = style.border
            self.markView.isHidden = style.markSymbol == nil
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: changes)
        } else {
            changes()
        }
        refreshAccessibility()
    }

    /// A quick nudge for the card the person chose wrongly, skipped under Reduce Motion.
    func shake() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -8, 7, -5, 3, 0]
        animation.duration = 0.38
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(animation, forKey: "shake")
    }

    /// A short swell for the right answer, skipped under Reduce Motion.
    func pop() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: 0.14, animations: {
            self.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }, completion: { _ in
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.4) {
                self.transform = .identity
            }
        })
    }

    /// Only a card still open to choice reacts to a press; a checked one stays still.
    private var acceptsPress: Bool {
        switch mark {
        case .idle, .selected, .paired: return true
        case .correct, .incorrect, .dimmed: return false
        }
    }

    private func animatePress() {
        guard acceptsPress else { return }
        let scale: CGFloat = isHighlighted && !UIAccessibility.isReduceMotionEnabled ? 0.98 : 1
        UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    private func refreshAccessibility() {
        let prefix: String
        if case .letter(let letter) = currentBadge {
            prefix = "\(letter). "
        } else {
            prefix = ""
        }
        accessibilityLabel = prefix + title + (subtitle.map { ". \($0)" } ?? "")
        var traits: UIAccessibilityTraits = .button
        switch mark {
        case .selected, .paired:
            traits.insert(.selected)
            accessibilityValue = nil
        case .correct:
            accessibilityValue = String(localized: "Correct answer")
        case .incorrect:
            accessibilityValue = String(localized: "Your answer, incorrect")
        case .idle, .dimmed:
            accessibilityValue = nil
        }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }

    private var currentBadge: Badge {
        if badgeView.isHidden { return .none }
        if let letter = badgeLabel.text, !badgeLabel.isHidden { return .letter(letter) }
        return .none
    }

    override var isEnabled: Bool {
        didSet { refreshAccessibility() }
    }

    private struct Style {
        let background: UIColor
        let border: UIColor
        let borderWidth: CGFloat
        let alpha: CGFloat
        let badgeFill: UIColor
        let badgeBorder: UIColor
        let badgeForeground: UIColor
        let markSymbol: String?
    }

    /// A tile's badge is the answer itself (a check for True, a cross for False), so once checked it stays neutral and
    /// the card's color alone tells right from wrong.
    private static func style(for mark: Mark, accent: UIColor, keepsBadgeNeutral: Bool) -> Style {
        let base = style(for: mark, accent: accent)
        switch mark {
        case .correct, .incorrect:
            guard keepsBadgeNeutral else { return base }
            return Style(background: base.background, border: base.border, borderWidth: base.borderWidth, alpha: base.alpha, badgeFill: .clear, badgeBorder: base.border.withAlphaComponent(0.6), badgeForeground: PapyrusDesignSystem.Colors.Dynamic.primaryText, markSymbol: base.markSymbol)
        default:
            return base
        }
    }

    private static func style(for mark: Mark, accent: UIColor) -> Style {
        let surface = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.86)
        let quietBorder = UIColor.white.withAlphaComponent(0.12)
        let ink = PapyrusDesignSystem.Colors.Core.ink
        let secondary = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        switch mark {
        case .idle:
            return Style(background: surface, border: quietBorder, borderWidth: 1, alpha: 1, badgeFill: .clear, badgeBorder: UIColor.white.withAlphaComponent(0.22), badgeForeground: secondary, markSymbol: nil)
        case .selected:
            return Style(background: accent.withAlphaComponent(0.18), border: accent, borderWidth: 1.5, alpha: 1, badgeFill: accent, badgeBorder: accent, badgeForeground: ink, markSymbol: nil)
        case .paired(let color):
            return Style(background: color.withAlphaComponent(0.2), border: color, borderWidth: 1.5, alpha: 1, badgeFill: color, badgeBorder: color, badgeForeground: ink, markSymbol: nil)
        case .correct:
            let green = PapyrusDesignSystem.Colors.Core.scarabGreen
            return Style(background: green.withAlphaComponent(0.2), border: green, borderWidth: 1.5, alpha: 1, badgeFill: green, badgeBorder: green, badgeForeground: ink, markSymbol: "checkmark.circle.fill")
        case .incorrect:
            let red = PapyrusDesignSystem.Colors.Core.tombRed
            return Style(background: red.withAlphaComponent(0.2), border: red, borderWidth: 1.5, alpha: 1, badgeFill: red, badgeBorder: red, badgeForeground: PapyrusDesignSystem.Colors.Core.parchment, markSymbol: "xmark.circle.fill")
        case .dimmed:
            return Style(background: surface, border: quietBorder, borderWidth: 1, alpha: 0.42, badgeFill: .clear, badgeBorder: UIColor.white.withAlphaComponent(0.18), badgeForeground: secondary, markSymbol: nil)
        }
    }
}

/// A thin capsule that fills in the tradition's color as the quiz moves on.
final class QuizProgressBar: UIView {
    private let fill = UIView()
    private var progress: CGFloat = 0
    private let accent: UIColor

    init(accent: UIColor) {
        self.accent = accent
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white.withAlphaComponent(0.12)
        layer.cornerRadius = 3
        clipsToBounds = true
        fill.backgroundColor = accent
        fill.layer.cornerRadius = 3
        addSubview(fill)
        heightAnchor.constraint(equalToConstant: 6).isActive = true
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutFill()
    }

    /// Fills to `value` (0…1), with a soft spring unless Reduce Motion is on.
    func setProgress(_ value: CGFloat, animated: Bool) {
        progress = min(max(value, 0), 1)
        accessibilityValue = NumberFormatter.localizedString(from: NSNumber(value: Double(progress)), number: .percent)
        guard animated, !UIAccessibility.isReduceMotionEnabled, window != nil else {
            layoutFill()
            return
        }
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.3, options: [.beginFromCurrentState]) {
            self.layoutFill()
        }
    }

    private func layoutFill() {
        let width = bounds.width * progress
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        fill.frame = CGRect(x: isRightToLeft ? bounds.width - width : 0, y: 0, width: width, height: bounds.height)
    }
}

/// A capsule label such as "+10 XP", with a symbol, in a tinted pill.
final class QuizChip: UIView {
    private let label = UILabel()
    private let icon = UIImageView()
    private let stack = UIStackView()

    init(symbol: String, text: String, tint: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = tint.withAlphaComponent(0.16)
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = tint.withAlphaComponent(0.45).cgColor
        icon.image = UIImage(systemName: symbol)
        icon.tintColor = tint
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        icon.setContentHuggingPriority(.required, for: .horizontal)
        label.text = text
        label.font = PapyrusDesignSystem.Typography.rounded(14, weight: .bold, textStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = tint
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        stack.spacing = 5
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -11),
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        isAccessibilityElement = true
        accessibilityLabel = text
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (chip: QuizChip, _) in
            chip.invalidateIntrinsicContentSize()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The chip is as wide as its symbol and words, so a stack never stretches it.
    override var intrinsicContentSize: CGSize {
        let content = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: content.width + 21, height: content.height + 10)
    }
}

/// The ground the quiz screens' buttons stand on: the night sky's lowest color, so scrolled content fades out beneath
/// the buttons instead of showing through them.
enum QuizFooter {
    static let floor = UIColor(hex: 0x1A1326)
}

/// The light Markdown some questions and explanations carry (`*Neshamah*`, `**bold**`), set as italic and bold
/// instead of showing asterisks.
enum QuizText {
    static func styled(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard text.contains("*"), let parsed = try? AttributedString(markdown: text, options: options) else {
            return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        }
        let result = NSMutableAttributedString()
        for run in parsed.runs {
            let intent = run.inlinePresentationIntent ?? []
            var traits: UIFontDescriptor.SymbolicTraits = []
            if intent.contains(.stronglyEmphasized) { traits.insert(.traitBold) }
            if intent.contains(.emphasized) { traits.insert(.traitItalic) }
            result.append(NSAttributedString(
                string: String(parsed[run.range].characters),
                attributes: [.font: font.adding(traits), .foregroundColor: color]
            ))
        }
        return result
    }

    /// The words alone, for VoiceOver.
    static func plain(_ text: String) -> String {
        styled(text, font: .systemFont(ofSize: 17), color: .label).string
    }
}

private extension UIFont {
    func adding(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard !traits.isEmpty,
              let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(traits)) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
