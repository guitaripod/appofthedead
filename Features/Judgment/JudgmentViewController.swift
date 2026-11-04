import UIKit
import MidgarCore
import AppOfTheDeadCore

/// Where the person goes when they leave the Judgment.
enum JudgmentOutcome: Equatable {
    /// Skipped on the first run.
    case skipped
    /// Closed with nothing else to do.
    case done
    /// Tapped a realm, or chose to begin their journey, on this path.
    case path(String)
    /// Chose to ask their guide about the verdict.
    case oracle(deityId: String)
}

/// The Judgment, full screen over a night sky: an intro, nine scenes asked by guardians of the dead, the weighing of
/// the heart and the verdict with its Soul Card.
final class JudgmentViewController: UIViewController {

    private let viewModel: JudgmentViewModel
    private let onFinish: (JudgmentOutcome) -> Void
    private let backdrop = UnderworldBackdropView(seed: 11)
    private let foldAvoiding = FoldAvoidingLayout()
    private let pageContainer = UIView()
    private let topBar = UIStackView()
    private let backButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private lazy var progressView = JudgmentProgressView(count: viewModel.sceneCount)
    private var currentPage: UIView?
    private let selection = UISelectionFeedbackGenerator()

    init(viewModel: JudgmentViewModel, onFinish: @escaping (JudgmentOutcome) -> Void) {
        self.viewModel = viewModel
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.night
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        foldAvoiding.install(in: view)
        setupTopBar()
        pageContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageContainer)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainer.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
            pageContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageContainer.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor),
            pageContainer.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor),
        ])
        viewModel.onStageChange = { [weak self] stage in
            self?.render(stage, animated: true)
        }
        render(viewModel.stage, animated: false)
        Diagnostics.logViewControllerLifecycle("JudgmentViewController", event: "viewDidLoad")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        foldAvoiding.update(in: view)
    }

    private func setupTopBar() {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        backButton.accessibilityLabel = String(localized: "Back")
        backButton.addAction(UIAction { [weak self] _ in self?.viewModel.goBack() }, for: .touchUpInside)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        closeButton.accessibilityLabel = String(localized: "Close")
        closeButton.addAction(UIAction { [weak self] _ in self?.close() }, for: .touchUpInside)
        [backButton, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 44).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.axis = .horizontal
        topBar.alignment = .center
        topBar.spacing = 12
        topBar.addArrangedSubview(backButton)
        topBar.addArrangedSubview(progressView)
        topBar.addArrangedSubview(closeButton)
        view.addSubview(topBar)
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            topBar.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor, constant: 12),
            topBar.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor, constant: -12),
        ])
    }

    private func close() {
        switch viewModel.entry {
        case .firstRun:
            onFinish(.skipped)
        case .retake, .review:
            onFinish(.done)
        }
    }

    // MARK: Rendering

    private func render(_ stage: JudgmentViewModel.Stage, animated: Bool) {
        let page: UIView
        switch stage {
        case .intro:
            page = makeIntroPage()
            setTopBar(back: false, progress: nil, close: true)
            backdrop.glowColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        case .scene(let index):
            let scene = viewModel.scenes[index]
            let tradition = traditionColor(for: scene)
            page = makeScenePage(scene, index: index, color: tradition)
            setTopBar(back: true, progress: (index, tradition), close: true)
            backdrop.glowColor = tradition
            selection.prepare()
        case .weighing:
            page = makeWeighingPage()
            setTopBar(back: false, progress: nil, close: false)
            backdrop.glowColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        case .verdict(let verdict):
            page = makeVerdictPage(verdict)
            setTopBar(back: false, progress: nil, close: true)
            backdrop.glowColor = JudgmentCopy.color(for: verdict.leadingTradition)
        }
        swap(to: page, animated: animated)
        UIAccessibility.post(notification: .screenChanged, argument: page)
    }

    private func setTopBar(back: Bool, progress: (Int, UIColor)?, close: Bool) {
        backButton.alpha = back ? 1 : 0
        backButton.isEnabled = back
        if let (index, color) = progress {
            progressView.isHidden = false
            progressView.setCurrent(index, color: color)
        } else {
            progressView.isHidden = true
        }
        closeButton.alpha = close ? 1 : 0
        closeButton.isEnabled = close
    }

    private func swap(to page: UIView, animated: Bool) {
        page.translatesAutoresizingMaskIntoConstraints = false
        pageContainer.addSubview(page)
        NSLayoutConstraint.activate([
            page.topAnchor.constraint(equalTo: pageContainer.topAnchor),
            page.bottomAnchor.constraint(equalTo: pageContainer.bottomAnchor),
            page.leadingAnchor.constraint(equalTo: pageContainer.leadingAnchor),
            page.trailingAnchor.constraint(equalTo: pageContainer.trailingAnchor),
        ])
        let old = currentPage
        currentPage = page
        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            old?.removeFromSuperview()
            return
        }
        page.alpha = 0
        page.transform = CGAffineTransform(translationX: 0, y: 18)
        UIView.animate(withDuration: 0.22, animations: {
            old?.alpha = 0
        }, completion: { _ in
            old?.removeFromSuperview()
        })
        UIView.animate(withDuration: 0.45, delay: 0.12, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.3) {
            page.alpha = 1
            page.transform = .identity
        }
    }

    private func traditionColor(for scene: JudgmentScene) -> UIColor {
        let tradition = JudgmentTradition.allCases.first { $0.pathId == scene.pathId } ?? .egyptian
        return JudgmentCopy.color(for: tradition)
    }

    private func traditionName(for scene: JudgmentScene) -> String {
        let tradition = JudgmentTradition.allCases.first { $0.pathId == scene.pathId } ?? .egyptian
        return JudgmentCopy.tradition(tradition)
    }

    // MARK: Pages

    private func makeIntroPage() -> UIView {
        let glyph = GlowingGlyphView(symbol: "scalemass.fill", color: PapyrusDesignSystem.Colors.Core.goldLeaf, diameter: 116, pointSize: 50)
        glyph.pulse()
        let eyebrow = makeEyebrowLabel(String(localized: "Where will your soul go?"))
        let title = makeSerifLabel(String(localized: "The Judgment"), size: 44, weight: .bold)
        let body = makeBodyLabel(String(localized: "Every culture has asked what happens after we die. Six of them are about to weigh your soul."), size: 18)
        let meta = makeEyebrowLabel(String(localized: "Nine questions · About two minutes"), color: PapyrusDesignSystem.Colors.Dynamic.tertiaryText)
        let stack = UIStackView(arrangedSubviews: [glyph, eyebrow, title, body, meta])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 14
        stack.setCustomSpacing(32, after: glyph)
        stack.setCustomSpacing(22, after: body)

        let begin = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: begin, style: .primary)
        begin.configuration?.title = String(localized: "Begin the Judgment")
        begin.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self?.viewModel.begin()
        }, for: .touchUpInside)
        var buttons: [UIView] = [begin]
        if case .firstRun = viewModel.entry {
            let skip = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = String(localized: "Skip to the lessons")
            configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
            skip.configuration = configuration
            skip.addAction(UIAction { [weak self] _ in self?.onFinish(.skipped) }, for: .touchUpInside)
            buttons.append(skip)
        }
        return makePage(content: stack, footer: buttons)
    }

    private func makeScenePage(_ scene: JudgmentScene, index: Int, color: UIColor) -> UIView {
        let guardian = JudgmentCopy.guardian(for: scene)
        let glyph = GlowingGlyphView(symbol: guardian.symbol, color: color, diameter: 76, pointSize: 30)
        let eyebrow = makeEyebrowLabel("\(traditionName(for: scene)) · \(guardian.title)", color: color)
        let name = makeSerifLabel(guardian.name, size: 22, weight: .semibold, color: PapyrusDesignSystem.Colors.Dynamic.secondaryText)
        let prompt = makeSerifLabel(JudgmentCopy.prompt(for: scene), size: 26, weight: .semibold)
        prompt.accessibilityTraits = .header
        let answers = UIStackView()
        answers.axis = .vertical
        answers.spacing = 10
        for (answerIndex, answer) in scene.answers.enumerated() {
            let button = JudgmentAnswerButton(title: JudgmentCopy.answer(answer, in: scene), accent: color)
            button.addAction(UIAction { [weak self, weak button] _ in
                self?.choose(answerIndex, button: button)
            }, for: .touchUpInside)
            answers.addArrangedSubview(button)
        }
        let stack = UIStackView(arrangedSubviews: [glyph, eyebrow, name, prompt, answers])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(18, after: glyph)
        stack.setCustomSpacing(18, after: name)
        stack.setCustomSpacing(28, after: prompt)
        return makePage(content: stack, footer: [])
    }

    private func choose(_ index: Int, button: JudgmentAnswerButton?) {
        guard view.isUserInteractionEnabled else { return }
        view.isUserInteractionEnabled = false
        button?.isSelected = true
        selection.selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
            self?.view.isUserInteractionEnabled = true
            self?.viewModel.choose(answerAt: index)
        }
    }

    private func makeWeighingPage() -> UIView {
        let scale = ScaleOfMaatView()
        scale.translatesAutoresizingMaskIntoConstraints = false
        let caption = makeSerifLabel(String(localized: "Anubis weighs your heart against the feather of Ma'at…"), size: 22, weight: .regular, color: PapyrusDesignSystem.Colors.Dynamic.secondaryText)
        let stack = UIStackView(arrangedSubviews: [scale, caption])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 36
        scale.heightAnchor.constraint(equalToConstant: 240).isActive = true
        let page = makePage(content: stack, footer: [])
        let settle: ScaleOfMaatView.Settle
        switch JudgmentEngine.realm(in: .egyptian, for: viewModel.soul) {
        case .solarBarque: settle = .lighter
        case .ammit: settle = .heavier
        default: settle = .balanced
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak scale, weak caption] in
            scale?.weigh(settling: settle) {
                caption?.text = String(localized: "The scales have spoken.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self?.viewModel.finishWeighing()
                }
            }
        }
        return page
    }

    private func makeVerdictPage(_ verdict: Verdict) -> UIView {
        let archetype = verdict.archetype
        let leading = JudgmentCopy.color(for: verdict.leadingTradition)
        let glyph = GlowingGlyphView(symbol: JudgmentCopy.archetypeSymbol(archetype), color: PapyrusDesignSystem.Colors.Core.goldLeaf, diameter: 104, pointSize: 44)
        glyph.pulse()
        let eyebrow = makeEyebrowLabel(String(localized: "Your soul is"))
        let name = makeSerifLabel(JudgmentCopy.archetypeName(archetype), size: 36, weight: .bold, color: PapyrusDesignSystem.Colors.Core.goldLeaf)
        name.accessibilityTraits = .header
        let description = makeBodyLabel(JudgmentCopy.archetypeDescription(archetype), size: 17)
        let stack = UIStackView(arrangedSubviews: [glyph, eyebrow, name, description])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(24, after: glyph)
        stack.setCustomSpacing(28, after: description)

        if viewModel.startedPremiumWeek, let end = viewModel.premiumWeekEnd {
            stack.addArrangedSubview(makePremiumWeekCard(endingOn: end))
            stack.setCustomSpacing(28, after: stack.arrangedSubviews.last!)
        }

        let realmsHeader = makeEyebrowLabel(String(localized: "Where you will go"), color: PapyrusDesignSystem.Colors.Dynamic.tertiaryText)
        stack.addArrangedSubview(realmsHeader)
        stack.setCustomSpacing(14, after: realmsHeader)
        for realm in verdict.realms {
            let row = VerdictRealmRow(realm: realm, verdict: verdict)
            row.addAction(UIAction { [weak self] _ in
                self?.onFinish(.path(realm.tradition.pathId))
            }, for: .touchUpInside)
            stack.addArrangedSubview(row)
        }

        let share = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: share, style: .primary)
        share.configuration?.title = String(localized: "Share My Soul Card")
        share.configuration?.image = UIImage(systemName: "square.and.arrow.up")
        share.configuration?.imagePadding = 8
        share.addAction(UIAction { [weak self, weak share] _ in
            self?.shareSoulCard(verdict, from: share)
        }, for: .touchUpInside)

        let guide = deityName(for: archetype.guideDeityId)
        let ask = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: ask, style: .tertiary)
        ask.configuration?.title = String(localized: "Ask \(guide)")
        ask.configuration?.image = UIImage(systemName: "bubble.left.and.text.bubble.right")
        ask.configuration?.imagePadding = 6
        ask.addAction(UIAction { [weak self] _ in
            self?.onFinish(.oracle(deityId: archetype.guideDeityId))
        }, for: .touchUpInside)

        let journey = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: journey, style: .tertiary)
        switch viewModel.entry {
        case .firstRun:
            journey.configuration?.title = String(localized: "Begin")
            journey.addAction(UIAction { [weak self] _ in
                self?.onFinish(.path(verdict.leadingTradition.pathId))
            }, for: .touchUpInside)
        case .retake, .review:
            journey.configuration?.title = String(localized: "Done")
            journey.addAction(UIAction { [weak self] _ in self?.onFinish(.done) }, for: .touchUpInside)
        }
        let secondary = UIStackView(arrangedSubviews: [ask, journey])
        secondary.axis = .horizontal
        secondary.spacing = 10
        secondary.distribution = .fillEqually
        return makePage(content: stack, footer: [share, secondary], centered: false)
    }

    private func makePremiumWeekCard(endingOn end: Date) -> UIView {
        let card = UIView()
        card.backgroundColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.1)
        card.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.4).cgColor
        let icon = UIImageView(image: UIImage(systemName: "door.left.hand.open"))
        icon.tintColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let title = makeSerifLabel(String(localized: "The gates are open"), size: 19, weight: .semibold, color: PapyrusDesignSystem.Colors.Core.goldLeaf, alignment: .natural)
        let date = end.formatted(.dateTime.month(.wide).day())
        let body = makeBodyLabel(String(localized: "Every path and every god are yours until \(date). Nothing to sign up for, nothing to cancel."), size: 15, alignment: .natural)
        let text = UIStackView(arrangedSubviews: [title, body])
        text.axis = .vertical
        text.spacing = 4
        let row = UIStackView(arrangedSubviews: [icon, text])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(title.text ?? ""). \(body.text ?? "")"
        return card
    }

    /// A scrolling page with its content, and the footer's buttons pinned above the home indicator.
    private func makePage(content: UIView, footer: [UIView], centered: Bool = true) -> UIView {
        let page = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        let scroll: UIScrollView
        if centered {
            scroll = CenteredScrollView(content: content, horizontalInset: 24)
        } else {
            scroll = UIScrollView()
            scroll.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(content)
            let preferredWidth = content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
            preferredWidth.priority = .init(999)
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
                content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
                content.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
                content.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
                content.widthAnchor.constraint(lessThanOrEqualTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
                preferredWidth,
            ])
        }
        scroll.showsVerticalScrollIndicator = false
        page.addSubview(scroll)
        let footerStack = UIStackView(arrangedSubviews: footer)
        footerStack.axis = .vertical
        footerStack.spacing = 10
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        page.addSubview(footerStack)
        let maxWidth = footerStack.widthAnchor.constraint(lessThanOrEqualToConstant: 520)
        let preferredWidth = footerStack.widthAnchor.constraint(equalTo: page.widthAnchor, constant: -48)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: page.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: page.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: page.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: footerStack.topAnchor, constant: footer.isEmpty ? 0 : -14),
            footerStack.centerXAnchor.constraint(equalTo: page.centerXAnchor),
            maxWidth,
            preferredWidth,
            footerStack.bottomAnchor.constraint(equalTo: page.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
        return page
    }

    private func deityName(for deityId: String) -> String {
        OracleDeityDirectory.name(for: deityId) ?? deityId.capitalized
    }

    // MARK: Sharing

    private func shareSoulCard(_ verdict: Verdict, from source: UIView?) {
        let image = SoulCardRenderer.render(verdict)
        let message = "\(viewModel.shareMessage(for: verdict)) \(JudgmentViewModel.appStoreURL.absoluteString)"
        let controller = UIActivityViewController(activityItems: [SoulCardShareItem(image: image), message], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = source ?? view
        controller.completionWithItemsHandler = { activity, completed, _, _ in
            guard completed else { return }
            Diagnostics.logUserAction("soulCardShared", parameters: ["activity": activity?.rawValue ?? "unknown"], category: .learning)
            AppFunnel.note(.soulCardShared)
        }
        present(controller, animated: true)
    }
}
