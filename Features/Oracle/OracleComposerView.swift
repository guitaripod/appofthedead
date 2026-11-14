import UIKit

/// Where a question is written: the deity's emblem to change guides, a field that grows to six lines, and one button
/// that sends, or stops the answer while it is being written. On a hardware keyboard Return sends and Shift-Return
/// starts a new line.
final class OracleComposerView: UIView {
    var onSend: (() -> Void)?
    var onStop: (() -> Void)?
    var onChooseDeity: (() -> Void)?
    var onTextChange: (() -> Void)?

    let textView = OracleComposerTextView()
    private let field = UIView()
    private let placeholderLabel = UILabel()
    private let deityButton = UIButton(type: .custom)
    private let actionButton = UIButton(type: .custom)
    private var textHeight: NSLayoutConstraint!
    private var measuredWidth: CGFloat = 0
    private var accent = PapyrusDesignSystem.Colors.Core.goldLeaf
    private var isGenerating = false

    private static let maximumLines: CGFloat = 6
    private static let buttonSize: CGFloat = 36

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        refreshActionButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The question as written, without surrounding space.
    var question: String {
        textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setText(_ text: String) {
        textView.text = text
        textDidChange()
    }

    func clear() {
        setText("")
    }

    func setDeity(_ deity: OracleViewModel.Deity) {
        accent = PapyrusDesignSystem.Colors.tradition(deity.color)
        var configuration = deityButton.configuration ?? .plain()
        configuration.image = UIImage(systemName: deity.avatar) ?? UIImage(systemName: "sparkles")
        configuration.baseForegroundColor = accent
        configuration.background.backgroundColor = accent.withAlphaComponent(0.16)
        deityButton.configuration = configuration
        deityButton.accessibilityLabel = String(localized: "Guide: \(deity.name)")
        placeholderLabel.text = String(localized: "Ask \(deity.name)…")
        textView.accessibilityLabel = String(localized: "Ask \(deity.name)")
        refreshFieldBorder()
    }

    func setGenerating(_ generating: Bool) {
        isGenerating = generating
        refreshActionButton()
    }

    private func setupViews() {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.94)
        field.layer.cornerRadius = 26
        field.layer.cornerCurve = .continuous
        field.layer.borderWidth = 1
        field.layer.shadowColor = UIColor.black.cgColor
        field.layer.shadowOpacity = 0.35
        field.layer.shadowRadius = 18
        field.layer.shadowOffset = CGSize(width: 0, height: 6)
        addSubview(field)

        setupDeityButton()
        setupTextView()
        setupActionButton()

        let row = UIStackView(arrangedSubviews: [deityButton, textView, actionButton])
        row.axis = .horizontal
        row.alignment = .bottom
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        field.addSubview(row)

        textHeight = textView.heightAnchor.constraint(equalToConstant: minimumTextHeight)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: topAnchor),
            field.bottomAnchor.constraint(equalTo: bottomAnchor),
            field.leadingAnchor.constraint(equalTo: leadingAnchor),
            field.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: field.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: field.bottomAnchor, constant: -8),
            row.leadingAnchor.constraint(equalTo: field.leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: field.trailingAnchor, constant: -8),
            deityButton.widthAnchor.constraint(equalToConstant: Self.buttonSize),
            deityButton.heightAnchor.constraint(equalToConstant: Self.buttonSize),
            actionButton.widthAnchor.constraint(equalToConstant: Self.buttonSize),
            actionButton.heightAnchor.constraint(equalToConstant: Self.buttonSize),
            textHeight,
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: textView.textContainerInset.left + textView.textContainer.lineFragmentPadding),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: textView.textContainerInset.top),
        ])
        refreshFieldBorder()
    }

    private func setupDeityButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.cornerStyle = .capsule
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        configuration.contentInsets = .zero
        deityButton.configuration = configuration
        deityButton.accessibilityHint = String(localized: "Choose another guide")
        deityButton.addAction(UIAction { [weak self] _ in self?.onChooseDeity?() }, for: .touchUpInside)
        deityButton.pointerStyleProvider = { button, _, _ in
            UIPointerStyle(effect: .highlight(UITargetedPreview(view: button)), shape: .roundedRect(button.bounds, radius: Self.buttonSize / 2))
        }
    }

    private func setupTextView() {
        textView.backgroundColor = .clear
        textView.font = PapyrusDesignSystem.Typography.sans(17, textStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        textView.tintColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        textView.keyboardAppearance = .dark
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 2)
        textView.delegate = self
        textView.onSendKey = { [weak self] in self?.sendTapped() }
        placeholderLabel.font = textView.font
        placeholderLabel.adjustsFontForContentSizeCategory = true
        placeholderLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.isAccessibilityElement = false
        textView.addSubview(placeholderLabel)
    }

    private func setupActionButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .zero
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        actionButton.configuration = configuration
        actionButton.addAction(UIAction { [weak self] _ in self?.actionTapped() }, for: .touchUpInside)
        actionButton.pointerStyleProvider = { button, _, _ in
            UIPointerStyle(effect: .lift(UITargetedPreview(view: button)), shape: .roundedRect(button.bounds, radius: Self.buttonSize / 2))
        }
    }

    private var minimumTextHeight: CGFloat {
        ceil((textView.font?.lineHeight ?? 20) + textView.textContainerInset.top + textView.textContainerInset.bottom)
    }

    private var maximumTextHeight: CGFloat {
        ceil((textView.font?.lineHeight ?? 20) * Self.maximumLines + textView.textContainerInset.top + textView.textContainerInset.bottom)
    }

    /// The field grows with its text up to six lines, then scrolls inside.
    private func fitTextHeight(animated: Bool) {
        let width = textView.bounds.width > 0 ? textView.bounds.width : 240
        let fitting = ceil(textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
        let height = min(max(fitting, minimumTextHeight), maximumTextHeight)
        textView.isScrollEnabled = fitting > maximumTextHeight
        guard abs(textHeight.constant - height) > 0.5 else { return }
        textHeight.constant = height
        guard animated, let container = superview, window != nil else { return }
        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            container.layoutIfNeeded()
        }
    }

    /// A new width rewraps the text, so the height is measured again.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard abs(textView.bounds.width - measuredWidth) > 0.5 else { return }
        measuredWidth = textView.bounds.width
        fitTextHeight(animated: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        placeholderLabel.font = textView.font
        textHeight.constant = minimumTextHeight
        fitTextHeight(animated: false)
    }

    private func textDidChange() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        fitTextHeight(animated: true)
        refreshActionButton()
        onTextChange?()
    }

    private func refreshFieldBorder() {
        field.layer.borderColor = (textView.isFirstResponder ? accent.withAlphaComponent(0.55) : UIColor.white.withAlphaComponent(0.1)).cgColor
    }

    /// Send while there is a question, stop while an answer is written, and dimmed otherwise.
    private func refreshActionButton() {
        var configuration = actionButton.configuration ?? .filled()
        let colors = PapyrusDesignSystem.Colors.self
        if isGenerating {
            configuration.image = UIImage(systemName: "stop.fill")
            configuration.baseBackgroundColor = colors.Core.surfaceRaised
            configuration.baseForegroundColor = colors.Dynamic.primaryText
            actionButton.isEnabled = true
            actionButton.accessibilityLabel = String(localized: "Stop answering")
        } else {
            let canSend = !question.isEmpty
            configuration.image = UIImage(systemName: "arrow.up")
            configuration.baseBackgroundColor = canSend ? colors.Core.goldLeaf : colors.Core.surfaceRaised
            configuration.baseForegroundColor = canSend ? colors.Core.ink : colors.Dynamic.tertiaryText
            actionButton.isEnabled = canSend
            actionButton.accessibilityLabel = String(localized: "Send")
        }
        actionButton.configuration = configuration
    }

    private func actionTapped() {
        if isGenerating {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onStop?()
        } else {
            sendTapped()
        }
    }

    private func sendTapped() {
        guard !isGenerating, !question.isEmpty else { return }
        onSend?()
    }
}

extension OracleComposerView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textDidChange()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.2) { self.refreshFieldBorder() }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.2) { self.refreshFieldBorder() }
    }
}

/// The composer's text view: on a hardware keyboard Return and Command-Return send, while text still being composed
/// with an input method keeps Return for itself.
final class OracleComposerTextView: UITextView {
    var onSendKey: (() -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        let send = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(sendFromKeyboard))
        send.wantsPriorityOverSystemBehavior = true
        let commandSend = UIKeyCommand(title: String(localized: "Send"), action: #selector(sendFromKeyboard), input: "\r", modifierFlags: .command)
        commandSend.wantsPriorityOverSystemBehavior = true
        return [send, commandSend]
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(sendFromKeyboard) {
            return markedTextRange == nil
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @objc private func sendFromKeyboard() {
        onSendKey?()
    }
}
