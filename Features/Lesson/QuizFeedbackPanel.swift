import UIKit

/// The verdict on one answer, risen from the bottom of the quiz in place of the Check button: green or red, the right
/// answer when the given one was wrong, the whole explanation (it scrolls when long), the XP earned, and Continue. It
/// stays until the person moves on.
final class QuizFeedbackPanel: UIView {

    var onContinue: (() -> Void)?

    private let tintLayerView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let headerRow = UIStackView()
    private let answerLabel = UILabel()
    private let explanationLabel = UILabel()
    private let explanationScroll = UIScrollView()
    private let continueButton = UIButton(type: .system)
    private var chip: QuizChip?
    private var explanationHeight: NSLayoutConstraint?
    private var stackBottom: NSLayoutConstraint?

    /// The home indicator's inset, set by the screen, kept clear under Continue whether the panel is shown or not.
    var bottomInset: CGFloat = 0 {
        didSet { stackBottom?.constant = -(16 + bottomInset) }
    }

    /// The most of the screen the explanation may take before it scrolls.
    var maximumExplanationHeight: CGFloat = 220 {
        didSet { setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.xLarge
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        let shadow = PapyrusDesignSystem.Shadow.floating()
        layer.shadowColor = shadow.color
        layer.shadowOpacity = shadow.opacity
        layer.shadowRadius = shadow.radius
        layer.shadowOffset = CGSize(width: 0, height: -6)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        tintLayerView.translatesAutoresizingMaskIntoConstraints = false
        tintLayerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.xLarge
        tintLayerView.layer.cornerCurve = .continuous
        tintLayerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tintLayerView.isUserInteractionEnabled = false
        addSubview(tintLayerView)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.font = PapyrusDesignSystem.Typography.serif(24, weight: .bold, textStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        let spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        spacer.setContentCompressionResistancePriority(UILayoutPriority(1), for: .horizontal)
        headerRow.addArrangedSubview(iconView)
        headerRow.addArrangedSubview(titleLabel)
        headerRow.addArrangedSubview(spacer)
        headerRow.spacing = 10
        headerRow.alignment = .center
        headerRow.isAccessibilityElement = true
        headerRow.accessibilityTraits = .header

        answerLabel.numberOfLines = 0
        answerLabel.adjustsFontForContentSizeCategory = true
        answerLabel.isAccessibilityElement = false

        explanationLabel.numberOfLines = 0
        explanationLabel.adjustsFontForContentSizeCategory = true
        explanationLabel.font = PapyrusDesignSystem.Typography.sans(16, weight: .regular, textStyle: .callout)
        explanationLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        explanationLabel.isAccessibilityElement = false
        explanationScroll.translatesAutoresizingMaskIntoConstraints = false
        explanationScroll.showsVerticalScrollIndicator = true
        explanationScroll.alwaysBounceVertical = false
        explanationScroll.indicatorStyle = .white
        explanationScroll.addSubview(explanationLabel)

        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: continueButton, style: .primary)
        continueButton.addAction(UIAction { [weak self] _ in self?.continueTapped() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [headerRow, answerLabel, explanationScroll, continueButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(20, after: explanationScroll)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let preferredWidth = stack.widthAnchor.constraint(equalTo: widthAnchor, constant: -48)
        preferredWidth.priority = .required - 1
        let explanationHeight = explanationScroll.heightAnchor.constraint(equalToConstant: 0)
        self.explanationHeight = explanationHeight
        let stackBottom = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        self.stackBottom = stackBottom
        NSLayoutConstraint.activate([
            tintLayerView.topAnchor.constraint(equalTo: topAnchor),
            tintLayerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tintLayerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintLayerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            stack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
            preferredWidth,
            stackBottom,
            explanationLabel.topAnchor.constraint(equalTo: explanationScroll.contentLayoutGuide.topAnchor),
            explanationLabel.bottomAnchor.constraint(equalTo: explanationScroll.contentLayoutGuide.bottomAnchor),
            explanationLabel.leadingAnchor.constraint(equalTo: explanationScroll.contentLayoutGuide.leadingAnchor),
            explanationLabel.trailingAnchor.constraint(equalTo: explanationScroll.contentLayoutGuide.trailingAnchor),
            explanationLabel.widthAnchor.constraint(equalTo: explanationScroll.frameLayoutGuide.widthAnchor),
            explanationHeight,
            continueButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fitExplanation()
    }

    /// The explanation shows whole up to `maximumExplanationHeight` and scrolls beyond it, so nothing is ever cut.
    private func fitExplanation() {
        let width = explanationScroll.bounds.width
        guard width > 0, let explanationHeight else { return }
        let needed = explanationLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        let target = min(ceil(needed), maximumExplanationHeight)
        guard abs(explanationHeight.constant - target) > 0.5 else { return }
        explanationHeight.constant = target
        explanationScroll.flashScrollIndicatorsIfScrollable(needed: needed, shown: target)
        setNeedsLayout()
    }

    /// Fills the panel for `outcome`: the verdict, the right answer when the given one was wrong, the explanation and
    /// the XP the answer earned.
    func configure(outcome: QuestionOutcome, xpEarned: Int, continueTitle: String) {
        let tint = outcome.isCorrect ? PapyrusDesignSystem.Colors.Core.scarabGreen : PapyrusDesignSystem.Colors.Core.tombRed
        tintLayerView.backgroundColor = tint.withAlphaComponent(0.13)
        tintLayerView.layer.borderWidth = 1
        tintLayerView.layer.borderColor = tint.withAlphaComponent(0.4).cgColor
        iconView.image = UIImage(systemName: outcome.isCorrect ? "checkmark.seal.fill" : "xmark.octagon.fill")
        iconView.tintColor = tint
        titleLabel.text = outcome.isCorrect ? String(localized: "Correct!") : String(localized: "Not quite right")
        titleLabel.textColor = tint
        configureChip(xpEarned: xpEarned, tint: tint)
        configureAnswer(outcome)
        explanationLabel.attributedText = QuizText.styled(
            outcome.explanation,
            font: PapyrusDesignSystem.Typography.sans(16, weight: .regular, textStyle: .callout),
            color: PapyrusDesignSystem.Colors.Dynamic.primaryText
        )
        explanationScroll.isHidden = outcome.explanation.isEmpty
        explanationScroll.contentOffset = .zero
        var configuration = continueButton.configuration
        configuration?.title = continueTitle
        configuration?.baseBackgroundColor = outcome.isCorrect ? PapyrusDesignSystem.Colors.Core.scarabGreen : PapyrusDesignSystem.Colors.Core.goldLeaf
        configuration?.baseForegroundColor = PapyrusDesignSystem.Colors.Core.ink
        continueButton.configuration = configuration
        headerRow.accessibilityLabel = spokenSummary(outcome: outcome)
        setNeedsLayout()
    }

    private func configureChip(xpEarned: Int, tint: UIColor) {
        chip?.removeFromSuperview()
        chip = nil
        guard xpEarned > 0 else { return }
        let newChip = QuizChip(symbol: "sparkles", text: String(localized: "+\(xpEarned) XP"), tint: PapyrusDesignSystem.Colors.Core.goldLeaf)
        newChip.isAccessibilityElement = false
        headerRow.addArrangedSubview(newChip)
        chip = newChip
    }

    private func configureAnswer(_ outcome: QuestionOutcome) {
        guard !outcome.isCorrect, !outcome.correctAnswer.isEmpty, !outcome.correctAnswer.contains("\n") else {
            answerLabel.isHidden = true
            return
        }
        answerLabel.isHidden = false
        let text = NSMutableAttributedString(string: String(localized: "Answer:") + " ", attributes: [
            .font: PapyrusDesignSystem.Typography.sans(16, weight: .semibold, textStyle: .callout),
            .foregroundColor: PapyrusDesignSystem.Colors.Dynamic.secondaryText,
        ])
        text.append(NSAttributedString(string: outcome.correctAnswer, attributes: [
            .font: PapyrusDesignSystem.Typography.sans(16, weight: .bold, textStyle: .callout),
            .foregroundColor: PapyrusDesignSystem.Colors.Core.scarabGreen,
        ]))
        answerLabel.attributedText = text
    }

    /// The panel's verdict, for VoiceOver to land on when it appears.
    var verdictElement: UIView {
        headerRow
    }

    /// Everything the panel says in one sentence for VoiceOver: verdict, XP, the right answer and the explanation.
    private func spokenSummary(outcome: QuestionOutcome) -> String {
        [titleLabel.text, chip?.accessibilityLabel, answerLabel.isHidden ? nil : answerLabel.text, QuizText.plain(outcome.explanation)]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    func performContinue() {
        continueTapped()
    }

    private func continueTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onContinue?()
    }
}

private extension UIScrollView {
    /// Shows the scroll indicator briefly when the text runs past what is shown, so the person knows there is more.
    func flashScrollIndicatorsIfScrollable(needed: CGFloat, shown: CGFloat) {
        guard needed > shown + 1 else { return }
        DispatchQueue.main.async { [weak self] in
            self?.flashScrollIndicators()
        }
    }
}
