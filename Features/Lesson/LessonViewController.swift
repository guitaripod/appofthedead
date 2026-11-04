import UIKit
import MidgarCore
import AppOfTheDeadCore

/// A lesson read as story cards: a few sentences at a time over the tradition's glow, then the key terms, then the
/// quiz. Tap the right of a card or swipe to go on, the left or swipe back to return.
final class LessonViewController: UIViewController {
    private let viewModel: LessonViewModel
    private let contentLoader = ContentLoader()
    private let mlxService = MLXService.shared
    private var deity: Deity?
    private let backdrop = UnderworldBackdropView(seed: 17)
    private let foldAvoiding = FoldAvoidingLayout()
    private lazy var progress = JudgmentProgressView(count: viewModel.cards.count + 1)
    private let cardContainer = UIView()
    private let nextButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    private var currentCard: UIView?
    private var index = 0

    private var accent: UIColor {
        viewModel.beliefSystemColor ?? PapyrusDesignSystem.Colors.Core.goldLeaf
    }

    private var isOnKeyTerms: Bool {
        index == viewModel.cards.count
    }

    init(viewModel: LessonViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.night
        backdrop.glowColor = accent
        backdrop.glowIntensity = 0.24
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        foldAvoiding.install(in: view)
        setupNavigationBar()
        setupLayout()
        setupGestures()
        deity = contentLoader.getDeityForBeliefSystem(viewModel.beliefSystemId)
        show(index: 0, forward: true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        foldAvoiding.update(in: view)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        close.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        close.accessibilityLabel = String(localized: "Close")
        navigationItem.leftBarButtonItem = close
        navigationItem.titleView = progress
        progress.widthAnchor.constraint(equalToConstant: 220).isActive = true
    }

    private func setupLayout() {
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardContainer)

        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: nextButton, style: .primary)
        nextButton.addAction(UIAction { [weak self] _ in self?.advance() }, for: .touchUpInside)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        backButton.backgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
        backButton.layer.cornerRadius = 26
        backButton.accessibilityLabel = String(localized: "Previous card")
        backButton.addAction(UIAction { [weak self] _ in self?.retreat() }, for: .touchUpInside)
        let footer = UIStackView(arrangedSubviews: [backButton, nextButton])
        footer.spacing = 12
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footer)
        let preferredWidth = footer.widthAnchor.constraint(equalTo: foldAvoiding.guide.widthAnchor, constant: -48)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cardContainer.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalToConstant: 52),
            backButton.heightAnchor.constraint(equalToConstant: 52),
            footer.centerXAnchor.constraint(equalTo: foldAvoiding.guide.centerXAnchor),
            footer.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            preferredWidth,
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        cardContainer.addGestureRecognizer(tap)
        let forward = UISwipeGestureRecognizer(target: self, action: #selector(swipedForward))
        forward.direction = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        let back = UISwipeGestureRecognizer(target: self, action: #selector(swipedBack))
        back.direction = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        cardContainer.addGestureRecognizer(forward)
        cardContainer.addGestureRecognizer(back)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !isOnKeyTerms else { return }
        let x = gesture.location(in: cardContainer).x
        let leading = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? x > cardContainer.bounds.width * 0.7 : x < cardContainer.bounds.width * 0.3
        leading ? retreat() : advance()
    }

    @objc private func swipedForward() {
        guard !isOnKeyTerms else { return }
        advance()
    }

    @objc private func swipedBack() {
        retreat()
    }

    private func advance() {
        if isOnKeyTerms {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.continueToQuiz()
            return
        }
        UISelectionFeedbackGenerator().selectionChanged()
        show(index: index + 1, forward: true, animated: true)
    }

    private func retreat() {
        guard index > 0 else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        show(index: index - 1, forward: false, animated: true)
    }

    private func show(index newIndex: Int, forward: Bool, animated: Bool) {
        index = newIndex
        progress.setCurrent(index, color: accent)
        nextButton.configuration?.title = isOnKeyTerms ? String(localized: "Begin the Quiz") : String(localized: "Next")
        backButton.isHidden = index == 0
        let card = isOnKeyTerms ? makeKeyTermsCard() : makeStoryCard(at: index)
        swap(to: card, forward: forward, animated: animated)
    }

    private func swap(to card: UIView, forward: Bool, animated: Bool) {
        card.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            card.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
        ])
        let old = currentCard
        currentCard = card
        UIAccessibility.post(notification: .layoutChanged, argument: card)
        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            old?.removeFromSuperview()
            return
        }
        let offset: CGFloat = forward ? 40 : -40
        card.alpha = 0
        card.transform = CGAffineTransform(translationX: offset, y: 0)
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
            card.alpha = 1
            card.transform = .identity
            old?.alpha = 0
            old?.transform = CGAffineTransform(translationX: -offset, y: 0)
        } completion: { _ in
            old?.removeFromSuperview()
        }
    }

    private func makeStoryCard(at index: Int) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        if index == 0 {
            stack.addArrangedSubview(makeEyebrowLabel("\(viewModel.beliefSystemName) · \(viewModel.lessonPosition)", color: accent, alignment: .natural))
            let title = makeSerifLabel(viewModel.lessonTitle, size: 30, weight: .bold, alignment: .natural)
            title.accessibilityTraits = .header
            stack.addArrangedSubview(title)
            stack.setCustomSpacing(26, after: title)
        } else {
            stack.addArrangedSubview(makeEyebrowLabel(String(localized: "\(index + 1) of \(viewModel.cards.count)"), color: PapyrusDesignSystem.Colors.Dynamic.tertiaryText, alignment: .natural))
        }
        let text = UILabel()
        text.numberOfLines = 0
        text.adjustsFontForContentSizeCategory = true
        text.attributedText = LessonText.attributed(
            viewModel.cards[index],
            font: PapyrusDesignSystem.Typography.serif(22, weight: .regular, textStyle: .title3),
            boldFont: PapyrusDesignSystem.Typography.serif(22, weight: .bold, textStyle: .title3),
            color: PapyrusDesignSystem.Colors.Dynamic.primaryText,
            accent: accent
        )
        stack.addArrangedSubview(text)
        let scroll = CenteredScrollView(content: stack, maxWidth: 600, horizontalInset: 28)
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }

    private func makeKeyTermsCard() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.addArrangedSubview(makeEyebrowLabel(String(localized: "Key terms"), color: accent, alignment: .natural))
        let title = makeSerifLabel(String(localized: "Words to carry with you"), size: 28, weight: .bold, alignment: .natural)
        stack.addArrangedSubview(title)
        if deity != nil {
            stack.addArrangedSubview(makeBodyLabel(String(localized: "Tap a term and the Oracle explains it."), size: 15, alignment: .natural))
        }
        stack.setCustomSpacing(20, after: stack.arrangedSubviews.last!)
        for term in viewModel.keyTerms {
            stack.addArrangedSubview(makeTermRow(term))
        }
        let scroll = CenteredScrollView(content: stack, maxWidth: 600, horizontalInset: 28)
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }

    private func makeTermRow(_ term: String) -> UIView {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = term
        configuration.baseBackgroundColor = PapyrusDesignSystem.Colors.Core.surface
        configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        configuration.image = deity == nil ? nil : UIImage(systemName: "sparkles")
        configuration.imagePlacement = .trailing
        configuration.imageColorTransformer = UIConfigurationColorTransformer { [accent] _ in accent }
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = PapyrusDesignSystem.Typography.sans(17, weight: .medium, textStyle: .body)
            return outgoing
        }
        button.configuration = configuration
        button.contentHorizontalAlignment = .fill
        button.layer.borderWidth = 1
        button.layer.borderColor = accent.withAlphaComponent(0.25).cgColor
        button.layer.cornerRadius = 12
        button.addAction(UIAction { [weak self] _ in self?.explain(term) }, for: .touchUpInside)
        button.isEnabled = deity != nil
        return button
    }

    private func explain(_ term: String) {
        guard let deity else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        present(PapyrusModal(deity: deity, keyword: term, mlxService: mlxService), animated: true)
    }

    @objc private func closeTapped() {
        MidgarLog.debug("LessonViewController - Close tapped", category: .ui)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.exitLearningPath()
    }
}

/// Lesson text with its `**bold**` spans set in the bold face and the tradition's color.
enum LessonText {
    static func attributed(_ text: String, font: UIFont, boldFont: UIFont, color: UIColor, accent: UIColor) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        let result = NSMutableAttributedString()
        let parts = text.components(separatedBy: "**")
        for (offset, part) in parts.enumerated() where !part.isEmpty {
            let isBold = offset % 2 == 1 && offset < parts.count - 1
            result.append(NSAttributedString(string: part, attributes: [
                .font: isBold ? boldFont : font,
                .foregroundColor: isBold ? accent : color,
                .paragraphStyle: paragraph,
            ]))
        }
        return result
    }
}
