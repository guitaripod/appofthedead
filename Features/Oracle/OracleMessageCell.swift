import UIKit

/// One turn of an Oracle conversation in a readable column: the person's question on the trailing side, the deity's
/// answer under its name, the app's own notices and care in quieter cards. A reply still being written shows three
/// breathing dots until its first words arrive.
final class OracleMessageCell: UITableViewCell {
    static let reuseIdentifier = "OracleMessageCell"
    static let columnWidth: CGFloat = 720
    static let answerWidth: CGFloat = 600
    static let questionWidth: CGFloat = 480

    enum Role {
        case question
        case answer(OracleViewModel.Deity?)
        case notice(OracleViewModel.Deity?)
        case failure(OracleViewModel.Deity?)
        case care
    }

    var onRetry: (() -> Void)?

    private let column = UILayoutGuide()
    private let stack = UIStackView()
    private let header = UIStackView()
    private let avatar = UIImageView()
    private let avatarBackground = UIView()
    private let nameLabel = UILabel()
    private let bubble = UIView()
    private let bubbleStack = UIStackView()
    private let bodyLabel = UILabel()
    private let writingIndicator = OracleWritingIndicator()
    private let retryButton = UIButton(type: .system)
    private var sideConstraints: [NSLayoutConstraint] = []
    private var widthConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The bubble, for a context menu preview that lifts only the message.
    var bubbleView: UIView {
        bubble
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onRetry = nil
        writingIndicator.stop()
        bodyLabel.attributedText = nil
    }

    func configure(text: String, role: Role, isWriting: Bool) {
        applyLayout(for: role)
        applyStyle(for: role)
        retryButton.isHidden = !isFailure(role)
        let formatted = Self.attributedText(text, for: role)
        if isWriting && text.isEmpty {
            showWriting()
        } else {
            showBody(formatted)
        }
        configureAccessibility(text: formatted.string, role: role, isWriting: isWriting)
    }

    /// Shows the part of an answer that has been revealed so far and answers whether the text now needs more or less
    /// height than it had.
    @discardableResult
    func showRevealedText(_ text: NSAttributedString) -> Bool {
        let before = bodyHeight()
        if text.length == 0 {
            showWriting()
        } else {
            showBody(text)
        }
        return abs(bodyHeight() - before) > 0.5
    }

    /// The text style of a deity's answer, shared with the reveal that writes it out.
    static func answerText(_ text: String) -> NSAttributedString {
        OracleTextFormatter.attributedText(
            from: text,
            font: bodyFont,
            color: PapyrusDesignSystem.Colors.Dynamic.primaryText,
            paragraphStyle: bodyParagraphStyle
        )
    }

    private static var bodyFont: UIFont {
        PapyrusDesignSystem.Typography.sans(17, textStyle: .body)
    }

    private static let bodyParagraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.paragraphSpacing = 4
        return style
    }()

    private static func attributedText(_ text: String, for role: Role) -> NSAttributedString {
        switch role {
        case .answer:
            return answerText(text)
        case .question, .care:
            return NSAttributedString(string: text, attributes: [
                .font: bodyFont,
                .foregroundColor: PapyrusDesignSystem.Colors.Dynamic.primaryText,
                .paragraphStyle: bodyParagraphStyle,
            ])
        case .notice, .failure:
            return NSAttributedString(string: text, attributes: [
                .font: PapyrusDesignSystem.Typography.sans(15, textStyle: .subheadline).withItalics(),
                .foregroundColor: PapyrusDesignSystem.Colors.Dynamic.secondaryText,
            ])
        }
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addLayoutGuide(column)

        avatarBackground.translatesAutoresizingMaskIntoConstraints = false
        avatarBackground.layer.cornerRadius = 11
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.contentMode = .scaleAspectFit
        avatar.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        avatarBackground.addSubview(avatar)
        nameLabel.font = PapyrusDesignSystem.Typography.sans(13, weight: .semibold, textStyle: .footnote)
        nameLabel.adjustsFontForContentSizeCategory = true
        header.addArrangedSubview(avatarBackground)
        header.addArrangedSubview(nameLabel)
        header.axis = .horizontal
        header.spacing = 7
        header.alignment = .center

        bubble.layer.cornerRadius = 20
        bubble.layer.cornerCurve = .continuous
        bubble.layer.borderWidth = 1
        bodyLabel.numberOfLines = 0
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        writingIndicator.isHidden = true
        setupRetryButton()

        bubbleStack.axis = .vertical
        bubbleStack.alignment = .leading
        bubbleStack.spacing = 10
        bubbleStack.translatesAutoresizingMaskIntoConstraints = false
        [bodyLabel, writingIndicator, retryButton].forEach(bubbleStack.addArrangedSubview)
        bubble.addSubview(bubbleStack)

        stack.axis = .vertical
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(header)
        stack.addArrangedSubview(bubble)
        contentView.addSubview(stack)

        let preferredColumnWidth = column.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -32)
        preferredColumnWidth.priority = .init(999)
        let bottom = stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        bottom.priority = .init(999)
        NSLayoutConstraint.activate([
            column.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            column.widthAnchor.constraint(lessThanOrEqualToConstant: Self.columnWidth),
            column.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            preferredColumnWidth,
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bottom,
            avatarBackground.widthAnchor.constraint(equalToConstant: 22),
            avatarBackground.heightAnchor.constraint(equalToConstant: 22),
            avatar.centerXAnchor.constraint(equalTo: avatarBackground.centerXAnchor),
            avatar.centerYAnchor.constraint(equalTo: avatarBackground.centerYAnchor),
            bubbleStack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
            bubbleStack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -12),
            bubbleStack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            bubbleStack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16),
            bodyLabel.widthAnchor.constraint(equalTo: bubbleStack.widthAnchor),
        ])
    }

    private func setupRetryButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Ask again")
        configuration.image = UIImage(systemName: "arrow.clockwise")
        configuration.imagePadding = 6
        configuration.contentInsets = .zero
        configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = PapyrusDesignSystem.Typography.sans(15, weight: .semibold, textStyle: .subheadline)
            return outgoing
        }
        retryButton.configuration = configuration
        retryButton.isHidden = true
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
    }

    /// Questions hug the trailing edge of the column, everything else the leading edge, each within its own width.
    private func applyLayout(for role: Role) {
        NSLayoutConstraint.deactivate(sideConstraints)
        widthConstraint?.isActive = false
        let isQuestion: Bool
        let maximumWidth: CGFloat
        switch role {
        case .question:
            isQuestion = true
            maximumWidth = Self.questionWidth
        case .answer, .notice, .failure, .care:
            isQuestion = false
            maximumWidth = Self.answerWidth
        }
        if isQuestion {
            sideConstraints = [
                stack.trailingAnchor.constraint(equalTo: column.trailingAnchor),
                stack.leadingAnchor.constraint(greaterThanOrEqualTo: column.leadingAnchor, constant: 44),
            ]
        } else {
            let fillsColumn = stack.trailingAnchor.constraint(equalTo: column.trailingAnchor)
            fillsColumn.priority = .defaultHigh
            sideConstraints = [
                stack.leadingAnchor.constraint(equalTo: column.leadingAnchor),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: column.trailingAnchor),
                fillsColumn,
            ]
        }
        stack.alignment = isQuestion ? .trailing : .fill
        widthConstraint = stack.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth)
        widthConstraint?.isActive = true
        NSLayoutConstraint.activate(sideConstraints)
    }

    private func applyStyle(for role: Role) {
        let colors = PapyrusDesignSystem.Colors.self
        switch role {
        case .question:
            header.isHidden = true
            bubble.backgroundColor = colors.Core.surfaceRaised
            bubble.layer.borderColor = colors.Core.goldLeaf.withAlphaComponent(0.32).cgColor
            bubble.layer.borderWidth = 1
        case .answer(let deity):
            showHeader(for: deity)
            let accent = deity.map { colors.tradition($0.color) } ?? colors.Core.goldLeaf
            bubble.backgroundColor = colors.Core.surface.withAlphaComponent(0.86)
            bubble.layer.borderColor = accent.withAlphaComponent(0.24).cgColor
            bubble.layer.borderWidth = 1
            writingIndicator.color = accent
        case .notice(let deity), .failure(let deity):
            showHeader(for: deity)
            bubble.backgroundColor = colors.Core.surface.withAlphaComponent(0.5)
            bubble.layer.borderColor = colors.Dynamic.border.cgColor
            bubble.layer.borderWidth = 1
        case .care:
            header.isHidden = true
            bubble.backgroundColor = colors.Core.goldLeaf.withAlphaComponent(0.12)
            bubble.layer.borderColor = colors.Core.goldLeaf.withAlphaComponent(0.6).cgColor
            bubble.layer.borderWidth = 1
        }
    }

    private func showHeader(for deity: OracleViewModel.Deity?) {
        guard let deity else {
            header.isHidden = true
            return
        }
        let accent = PapyrusDesignSystem.Colors.tradition(deity.color)
        header.isHidden = false
        nameLabel.text = deity.name
        nameLabel.textColor = accent
        avatar.image = UIImage(systemName: deity.avatar) ?? UIImage(systemName: "sparkles")
        avatar.tintColor = accent
        avatarBackground.backgroundColor = accent.withAlphaComponent(0.16)
    }

    private func isFailure(_ role: Role) -> Bool {
        if case .failure = role { return true }
        return false
    }

    private func showWriting() {
        bodyLabel.isHidden = true
        bodyLabel.attributedText = nil
        writingIndicator.isHidden = false
        writingIndicator.start()
    }

    private func showBody(_ text: NSAttributedString) {
        if !writingIndicator.isHidden {
            writingIndicator.stop()
            writingIndicator.isHidden = true
        }
        bodyLabel.isHidden = false
        bodyLabel.attributedText = text
    }

    private func bodyHeight() -> CGFloat {
        guard !bodyLabel.isHidden else { return writingIndicator.intrinsicContentSize.height }
        let width = bodyLabel.bounds.width > 0 ? bodyLabel.bounds.width : Self.answerWidth - 32
        return ceil(bodyLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
    }

    private func configureAccessibility(text: String, role: Role, isWriting: Bool) {
        isAccessibilityElement = true
        accessibilityCustomActions = nil
        switch role {
        case .question:
            accessibilityLabel = String(localized: "You: \(text)")
            accessibilityTraits = .staticText
            accessibilityHint = nil
        case .answer(let deity), .notice(let deity):
            let name = deity?.name ?? String(localized: "Oracle")
            accessibilityLabel = isWriting && text.isEmpty ? String(localized: "\(name) is writing") : String(localized: "\(name): \(text)")
            accessibilityTraits = .staticText
            accessibilityHint = nil
        case .failure(let deity):
            let name = deity?.name ?? String(localized: "Oracle")
            accessibilityLabel = String(localized: "\(name): \(text)")
            accessibilityTraits = .staticText
            accessibilityHint = nil
            accessibilityCustomActions = [UIAccessibilityCustomAction(name: String(localized: "Ask again")) { [weak self] _ in
                self?.onRetry?()
                return true
            }]
        case .care:
            accessibilityLabel = text
            accessibilityTraits = .link
            accessibilityHint = String(localized: "Opens findahelpline.com")
        }
    }
}

/// Three dots that breathe in the deity's color while a reply has not begun.
final class OracleWritingIndicator: UIView {
    private let dots = (0..<3).map { _ in UIView() }
    private let row = UIStackView()

    var color: UIColor = PapyrusDesignSystem.Colors.Core.goldLeaf {
        didSet { dots.forEach { $0.backgroundColor = color } }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        for dot in dots {
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            row.addArrangedSubview(dot)
        }
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 36, height: 20)
    }

    /// Under Reduce Motion the dots hold still at full strength.
    func start() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            stop()
            return
        }
        for (index, dot) in dots.enumerated() {
            dot.layer.removeAllAnimations()
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.25
            pulse.toValue = 1
            pulse.duration = 0.6
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulse.beginTime = CACurrentMediaTime() + Double(index) * 0.2
            pulse.fillMode = .backwards
            dot.layer.add(pulse, forKey: "pulse")
        }
    }

    func stop() {
        dots.forEach { $0.layer.removeAllAnimations() }
    }
}

private extension UIFont {
    func withItalics() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(.traitItalic)) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
