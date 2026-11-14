import UIKit
import MidgarCore

/// The end of a quiz: a ring that fills to the score in the tradition's color, the verdict, the right answers and the
/// XP earned, the daily reminder offer when it is due, and every question to read again with the answer given, the
/// right answer and the explanation. The actions sit at the bottom: Continue, and Practice Mistakes or Try Again.
final class QuizResultsViewController: UIViewController {

    struct Action {
        enum Style {
            case primary
            case secondary
        }

        let title: String
        let symbol: String?
        let style: Style
        let handler: () -> Void
    }

    var onClose: (() -> Void)?
    /// Runs once, when the results are first on screen: the moment a paywall may cover them.
    var onFirstAppear: (() -> Void)?

    private let viewModel: QuizResultsViewModel
    private var actions: [Action]
    private let buttonStack = UIStackView()
    private let reminder: DailyReminder?
    private let accent: UIColor
    private let backdrop = UnderworldBackdropView(seed: 53)
    private let foldAvoiding = FoldAvoidingLayout()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let footer = UIView()
    private let footerFade = CAGradientLayer()
    private lazy var ring = QuizScoreRingView(accent: accent)
    private var reminderCard: ReminderOfferCardView?
    private var hasAppeared = false

    init(viewModel: QuizResultsViewModel, actions: [Action], reminder: DailyReminder? = nil) {
        self.viewModel = viewModel
        self.actions = actions
        self.reminder = reminder
        self.accent = PapyrusDesignSystem.Colors.tradition(viewModel.traditionColor)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.night
        backdrop.glowColor = accent
        backdrop.glowCenter = CGPoint(x: 0.5, y: -0.05)
        backdrop.glowIntensity = 0.32
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        foldAvoiding.install(in: view)
        setupNavigationBar()
        setupScrollView()
        setupFooter()
        buildContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        guard !hasAppeared else { return }
        hasAppeared = true
        ring.animate(to: viewModel.fraction)
        celebrate()
        UIAccessibility.post(notification: .screenChanged, argument: ring)
        onFirstAppear?()
        onFirstAppear = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        foldAvoiding.update(in: view)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        footerFade.frame = footer.bounds
        CATransaction.commit()
        let footerHeight = footer.bounds.height
        if abs(scrollView.contentInset.bottom - footerHeight) > 0.5 {
            scrollView.contentInset.bottom = footerHeight
            scrollView.verticalScrollIndicatorInsets.bottom = footerHeight
        }
    }

    private func celebrate() {
        if viewModel.passed == false || viewModel.tier == .struggling {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), primaryAction: UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onClose?()
        })
        close.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        close.accessibilityLabel = String(localized: "Close")
        navigationItem.leftBarButtonItem = close
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        scrollView.addSubview(contentStack)
        let preferredWidth = contentStack.widthAnchor.constraint(equalTo: foldAvoiding.guide.widthAnchor, constant: -48)
        preferredWidth.priority = .required - 1
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            contentStack.widthAnchor.constraint(lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            preferredWidth,
        ])
    }

    private func setupFooter() {
        footer.translatesAutoresizingMaskIntoConstraints = false
        footerFade.colors = [
            QuizFooter.floor.withAlphaComponent(0).cgColor,
            QuizFooter.floor.cgColor,
        ]
        footerFade.locations = [0, 0.4]
        footer.layer.addSublayer(footerFade)
        view.addSubview(footer)
        let buttons = buttonStack
        actions.map(makeButton).forEach(buttons.addArrangedSubview)
        buttons.axis = .vertical
        buttons.spacing = 10
        buttons.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(buttons)
        let preferredWidth = buttons.widthAnchor.constraint(equalTo: foldAvoiding.guide.widthAnchor, constant: -48)
        preferredWidth.priority = .required - 1
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footer.topAnchor.constraint(equalTo: buttons.topAnchor, constant: -32),
            buttons.centerXAnchor.constraint(equalTo: foldAvoiding.guide.centerXAnchor),
            buttons.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            preferredWidth,
            buttons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    /// Replaces the actions at the bottom, for a screen whose actions refer to the screen itself.
    func setActions(_ newActions: [Action]) {
        actions = newActions
        guard isViewLoaded else { return }
        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        newActions.map(makeButton).forEach(buttonStack.addArrangedSubview)
    }

    private func makeButton(for action: Action) -> UIButton {
        let button = UIButton(type: .system)
        switch action.style {
        case .primary:
            PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: button, style: .primary)
        case .secondary:
            PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: button, style: .tertiary)
            button.configuration?.background.strokeColor = UIColor.white.withAlphaComponent(0.14)
            button.configuration?.background.strokeWidth = 1
        }
        button.configuration?.title = action.title
        if let symbol = action.symbol {
            button.configuration?.image = UIImage(systemName: symbol)
            button.configuration?.imagePadding = 8
            button.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        }
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        let handler = action.handler
        let style = action.style
        button.addAction(UIAction { _ in
            UIImpactFeedbackGenerator(style: style == .primary ? .medium : .light).impactOccurred()
            handler()
        }, for: .touchUpInside)
        return button
    }

    private func buildContent() {
        let ringHolder = UIView()
        ringHolder.addSubview(ring)
        NSLayoutConstraint.activate([
            ring.topAnchor.constraint(equalTo: ringHolder.topAnchor, constant: 12),
            ring.bottomAnchor.constraint(equalTo: ringHolder.bottomAnchor),
            ring.centerXAnchor.constraint(equalTo: ringHolder.centerXAnchor),
        ])
        ring.configure(scoreText: viewModel.scoreText, caption: String(localized: "Score"))
        ring.accessibilityLabel = String(localized: "Score \(viewModel.score) percent. \(viewModel.correctCount) of \(viewModel.totalCount) correct")
        let eyebrow = makeEyebrowLabel(viewModel.eyebrow, color: accent)
        let title = makeSerifLabel(viewModel.title, size: 34, weight: .bold)
        title.accessibilityTraits = .header
        let subtitle = makeBodyLabel(viewModel.subtitle, size: 16)
        [ringHolder, eyebrow, title, subtitle].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(22, after: ringHolder)
        contentStack.setCustomSpacing(8, after: eyebrow)
        contentStack.setCustomSpacing(8, after: title)
        contentStack.setCustomSpacing(24, after: subtitle)
        contentStack.addArrangedSubview(makeStatsRow())
        addReminderCardIfOffered()
        addReview()
    }

    private func makeStatsRow() -> UIView {
        let correctTile = QuizStatTile(symbol: "checkmark.circle.fill", value: viewModel.correctValue, caption: String(localized: "Correct"), tint: PapyrusDesignSystem.Colors.Core.scarabGreen)
        let xpTile = QuizStatTile(symbol: "sparkles", value: viewModel.xpValue, caption: String(localized: "XP earned"), tint: PapyrusDesignSystem.Colors.Core.goldLeaf)
        let row = UIStackView(arrangedSubviews: [correctTile, xpTile])
        row.spacing = 12
        row.distribution = .fillEqually
        return row
    }

    private func addReminderCardIfOffered() {
        guard let reminder else { return }
        let card = ReminderOfferCardView(state: .offer(time: reminder.time))
        card.onRemindTapped = { [weak self] in self?.enableReminder() }
        card.onOpenSettingsTapped = {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        reminderCard = card
        contentStack.setCustomSpacing(20, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(card)
    }

    private func enableReminder() {
        guard let reminder else { return }
        Diagnostics.logUserAction("reminderOfferAccepted", parameters: [:], category: .general)
        reminder.enable { [weak self] granted in
            guard let self, let card = self.reminderCard else { return }
            UIView.animate(withDuration: PapyrusDesignSystem.Animation.normal) {
                card.render(granted ? .enabled(time: reminder.time) : .denied)
                self.view.layoutIfNeeded()
            }
            UINotificationFeedbackGenerator().notificationOccurred(granted ? .success : .warning)
            UIAccessibility.post(notification: .layoutChanged, argument: card)
        }
    }

    private func addReview() {
        guard !viewModel.items.isEmpty else { return }
        let header = makeEyebrowLabel(String(localized: "Review answers"), color: PapyrusDesignSystem.Colors.Dynamic.secondaryText, alignment: .natural)
        header.accessibilityTraits = .header
        contentStack.setCustomSpacing(32, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(12, after: header)
        for (index, item) in viewModel.items.enumerated() {
            let row = QuizReviewRow(item: item, number: index + 1, expanded: !item.wasCorrect)
            row.onToggle = { [weak self] in
                UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.28) {
                    self?.contentStack.layoutIfNeeded()
                }
            }
            contentStack.addArrangedSubview(row)
        }
    }
}

/// The score as a ring that fills from the top, with the percentage in its middle.
final class QuizScoreRingView: UIView {
    private let track = CAShapeLayer()
    private let fill = CAShapeLayer()
    private let scoreLabel = UILabel()
    private let captionLabel = UILabel()
    private let diameter: CGFloat = 164
    private let lineWidth: CGFloat = 12

    init(accent: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        track.fillColor = UIColor.clear.cgColor
        track.strokeColor = UIColor.white.withAlphaComponent(0.1).cgColor
        track.lineWidth = lineWidth
        fill.fillColor = UIColor.clear.cgColor
        fill.strokeColor = accent.cgColor
        fill.lineWidth = lineWidth
        fill.lineCap = .round
        fill.strokeEnd = 0
        let glow = PapyrusDesignSystem.Shadow.glow(color: accent)
        fill.shadowColor = glow.color
        fill.shadowOpacity = glow.opacity
        fill.shadowRadius = glow.radius
        fill.shadowOffset = .zero
        layer.addSublayer(track)
        layer.addSublayer(fill)
        scoreLabel.font = PapyrusDesignSystem.Typography.rounded(40, weight: .bold, textStyle: .largeTitle)
        scoreLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        scoreLabel.adjustsFontSizeToFitWidth = true
        scoreLabel.minimumScaleFactor = 0.6
        scoreLabel.textAlignment = .center
        captionLabel.font = PapyrusDesignSystem.Typography.sans(12, weight: .semibold, textStyle: .caption1)
        captionLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        captionLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [scoreLabel, captionLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * lineWidth - 16),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = lineWidth / 2
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(
            arcCenter: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        )
        track.frame = bounds
        fill.frame = bounds
        track.path = path.cgPath
        fill.path = path.cgPath
    }

    func configure(scoreText: String, caption: String) {
        scoreLabel.text = scoreText
        captionLabel.text = caption.uppercased(with: .current)
    }

    /// Fills the ring to `fraction`, drawn over most of a second unless Reduce Motion is on.
    func animate(to fraction: Double) {
        let target = CGFloat(min(max(fraction, 0), 1))
        guard !UIAccessibility.isReduceMotionEnabled else {
            fill.strokeEnd = target
            return
        }
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = target
        animation.duration = 0.9
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fill.strokeEnd = target
        fill.add(animation, forKey: "fill")
    }
}

/// A small tile with a symbol, a large value and a caption, such as "5/6 Correct".
final class QuizStatTile: UIView {
    init(symbol: String, value: String, caption: String, tint: UIColor) {
        super.init(frame: .zero)
        backgroundColor = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.82)
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = PapyrusDesignSystem.Typography.rounded(24, weight: .bold, textStyle: .title2)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = PapyrusDesignSystem.Typography.sans(13, weight: .medium, textStyle: .footnote)
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        captionLabel.numberOfLines = 0
        let valueRow = UIStackView(arrangedSubviews: [icon, valueLabel])
        valueRow.spacing = 8
        valueRow.alignment = .center
        let stack = UIStackView(arrangedSubviews: [valueRow, captionLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
        ])
        isAccessibilityElement = true
        accessibilityLabel = "\(caption): \(value)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// One question of the review: right or wrong at a glance, the answer given and the right one, and the explanation
/// to open and read.
final class QuizReviewRow: UIControl {
    var onToggle: (() -> Void)?

    private let item: QuizResultsViewModel.ReviewItem
    private let chevron = UIImageView()
    private let explanationLabel = UILabel()
    private(set) var isExpanded: Bool

    init(item: QuizResultsViewModel.ReviewItem, number: Int, expanded: Bool) {
        self.item = item
        self.isExpanded = expanded
        super.init(frame: .zero)
        backgroundColor = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.82)
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        let tint = item.wasCorrect ? PapyrusDesignSystem.Colors.Core.scarabGreen : PapyrusDesignSystem.Colors.Core.tombRed
        layer.borderColor = tint.withAlphaComponent(0.32).cgColor
        build(tint: tint, number: number)
        addAction(UIAction { [weak self] _ in self?.toggle() }, for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = String(localized: "Shows or hides the explanation")
        applyExpansion()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build(tint: UIColor, number: Int) {
        let status = UIImageView(image: UIImage(systemName: item.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"))
        status.tintColor = tint
        status.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        status.setContentHuggingPriority(.required, for: .horizontal)
        status.setContentCompressionResistancePriority(.required, for: .horizontal)
        let question = UILabel()
        question.attributedText = QuizText.styled(
            item.question,
            font: PapyrusDesignSystem.Typography.sans(16, weight: .semibold, textStyle: .callout),
            color: PapyrusDesignSystem.Colors.Dynamic.primaryText
        )
        question.adjustsFontForContentSizeCategory = true
        question.numberOfLines = 0
        chevron.image = UIImage(systemName: "chevron.down")
        chevron.tintColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let header = UIStackView(arrangedSubviews: [status, question, chevron])
        header.spacing = 12
        header.alignment = .firstBaseline

        var lines: [UIView] = [header]
        let given = answerLabel(prefix: String(localized: "Your answer:"), value: item.givenAnswer, color: tint)
        lines.append(given)
        if !item.wasCorrect {
            lines.append(answerLabel(prefix: String(localized: "Answer:"), value: item.correctAnswer, color: PapyrusDesignSystem.Colors.Core.scarabGreen))
        }
        explanationLabel.attributedText = QuizText.styled(
            item.explanation,
            font: PapyrusDesignSystem.Typography.sans(15, weight: .regular, textStyle: .subheadline),
            color: PapyrusDesignSystem.Colors.Dynamic.secondaryText
        )
        explanationLabel.adjustsFontForContentSizeCategory = true
        explanationLabel.numberOfLines = 0
        lines.append(explanationLabel)
        let stack = UIStackView(arrangedSubviews: lines)
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(10, after: header)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
        ])
        accessibilityLabel = [
            String(localized: "Question \(number)"),
            item.wasCorrect ? String(localized: "Correct") : String(localized: "Incorrect"),
            QuizText.plain(item.question),
            "\(String(localized: "Your answer:")) \(item.givenAnswer)",
            item.wasCorrect ? nil : "\(String(localized: "Answer:")) \(item.correctAnswer)",
        ].compactMap { $0 }.joined(separator: "\n")
    }

    private func answerLabel(prefix: String, value: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        let separator = value.contains("\n") ? "\n" : " "
        let text = NSMutableAttributedString(string: prefix + separator, attributes: [
            .font: PapyrusDesignSystem.Typography.sans(14, weight: .medium, textStyle: .subheadline),
            .foregroundColor: PapyrusDesignSystem.Colors.Dynamic.tertiaryText,
        ])
        text.append(NSAttributedString(string: value, attributes: [
            .font: PapyrusDesignSystem.Typography.sans(15, weight: .semibold, textStyle: .subheadline),
            .foregroundColor: color,
        ]))
        label.attributedText = text
        return label
    }

    private func toggle() {
        UISelectionFeedbackGenerator().selectionChanged()
        isExpanded.toggle()
        applyExpansion()
        onToggle?()
    }

    private func applyExpansion() {
        explanationLabel.isHidden = !isExpanded || item.explanation.isEmpty
        explanationLabel.alpha = isExpanded ? 1 : 0
        chevron.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        accessibilityValue = isExpanded ? QuizText.plain(item.explanation) : nil
    }
}
