import UIKit

protocol QuizSessionViewControllerDelegate: AnyObject {
    /// The person checked an answer. The delegate records it and answers with `showFeedback(for:xpEarned:isLast:)`.
    func quizSession(_ session: QuizSessionViewController, didAnswer outcome: QuestionOutcome, for viewModel: BaseQuestionViewModel)
    /// The person read the feedback and wants the next question.
    func quizSessionDidContinue(_ session: QuizSessionViewController)
    func quizSessionDidRequestClose(_ session: QuizSessionViewController)
}

/// A whole quiz on one screen: the close button and a progress bar in the tradition's color stay put while the
/// questions slide through beneath them; Check sits at the bottom until an answer is checked, when the feedback panel
/// rises in its place and waits for Continue.
final class QuizSessionViewController: UIViewController {

    weak var delegate: QuizSessionViewControllerDelegate?

    private let accent: UIColor
    private let backdrop = UnderworldBackdropView(seed: 41)
    private let foldAvoiding = FoldAvoidingLayout()
    private lazy var progressBar = QuizProgressBar(accent: accent)
    private let questionContainer = UIView()
    private let checkButton = UIButton(type: .system)
    private let footer = UIView()
    private let footerFade = CAGradientLayer()
    private let feedbackPanel = QuizFeedbackPanel()
    private var feedbackHidden: NSLayoutConstraint?
    private var feedbackShown: NSLayoutConstraint?
    private(set) var currentQuestion: BaseQuestionViewController?
    private var isShowingFeedback = false
    private var isAwaitingVerdict = false
    private var answeredCount = 0
    private var totalCount = 1

    init(accent: UIColor) {
        self.accent = accent
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
        backdrop.glowCenter = CGPoint(x: 0.5, y: -0.08)
        backdrop.glowIntensity = 0.22
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        foldAvoiding.install(in: view)
        setupNavigationBar()
        setupQuestionContainer()
        setupFooter()
        setupFeedbackPanel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
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
        feedbackPanel.bottomInset = view.safeAreaInsets.bottom
        feedbackPanel.maximumExplanationHeight = max(120, view.bounds.height * 0.3)
        if isShowingFeedback {
            currentQuestion?.setBottomObstruction(obstructionHeight, animated: false)
        }
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = true
        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        close.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        close.accessibilityLabel = String(localized: "Close")
        navigationItem.leftBarButtonItem = close
        navigationItem.titleView = progressBar
        let width = progressBar.widthAnchor.constraint(equalToConstant: 260)
        width.priority = .defaultHigh
        NSLayoutConstraint.activate([width, progressBar.widthAnchor.constraint(lessThanOrEqualToConstant: 260)])
    }

    private func setupQuestionContainer() {
        questionContainer.translatesAutoresizingMaskIntoConstraints = false
        questionContainer.clipsToBounds = true
        view.addSubview(questionContainer)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            questionContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            questionContainer.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor),
            questionContainer.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor),
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
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: checkButton, style: .primary)
        checkButton.configuration?.title = String(localized: "Check Answer")
        checkButton.configurationUpdateHandler = { button in
            var configuration = button.configuration
            configuration?.baseBackgroundColor = button.isEnabled ? PapyrusDesignSystem.Colors.Component.Button.primaryBackground : PapyrusDesignSystem.Colors.Core.surfaceRaised
            configuration?.baseForegroundColor = button.isEnabled ? PapyrusDesignSystem.Colors.Component.Button.primaryForeground : PapyrusDesignSystem.Colors.Dynamic.tertiaryText
            button.configuration = configuration
        }
        checkButton.isEnabled = false
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.addAction(UIAction { [weak self] _ in self?.check() }, for: .touchUpInside)
        footer.addSubview(checkButton)
        let preferredWidth = checkButton.widthAnchor.constraint(equalTo: foldAvoiding.guide.widthAnchor, constant: -48)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footer.topAnchor.constraint(equalTo: checkButton.topAnchor, constant: -28),
            questionContainer.bottomAnchor.constraint(equalTo: checkButton.topAnchor, constant: -8),
            checkButton.centerXAnchor.constraint(equalTo: foldAvoiding.guide.centerXAnchor),
            checkButton.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            preferredWidth,
            checkButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            checkButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    private func setupFeedbackPanel() {
        feedbackPanel.onContinue = { [weak self] in self?.continueTapped() }
        feedbackPanel.isHidden = true
        view.addSubview(feedbackPanel)
        let hidden = feedbackPanel.topAnchor.constraint(equalTo: view.bottomAnchor)
        let shown = feedbackPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        feedbackHidden = hidden
        feedbackShown = shown
        NSLayoutConstraint.activate([
            feedbackPanel.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor),
            feedbackPanel.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor),
            feedbackPanel.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            hidden,
        ])
    }

    /// Shows `question` as number `answeredCount + 1` of `total`, sliding the previous one out.
    func show(_ question: BaseQuestionViewController, answeredCount: Int, total: Int, animated: Bool) {
        loadViewIfNeeded()
        let previous = currentQuestion
        currentQuestion = question
        isAwaitingVerdict = false
        question.onReadinessChange = { [weak self] ready in self?.checkButton.isEnabled = ready }
        addChild(question)
        question.view.translatesAutoresizingMaskIntoConstraints = false
        questionContainer.addSubview(question.view)
        NSLayoutConstraint.activate([
            question.view.topAnchor.constraint(equalTo: questionContainer.topAnchor),
            question.view.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor),
            question.view.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor),
            question.view.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor),
        ])
        question.didMove(toParent: self)
        self.answeredCount = answeredCount
        totalCount = max(total, 1)
        checkButton.isEnabled = question.isReadyToCheck
        progressBar.setProgress(CGFloat(answeredCount) / CGFloat(max(total, 1)), animated: animated)
        progressBar.accessibilityLabel = question.viewModel.positionText
        hideFeedback(animated: animated)
        transition(from: previous, to: question, animated: animated)
        UIAccessibility.post(notification: .screenChanged, argument: question.view)
    }

    private func transition(from previous: BaseQuestionViewController?, to next: BaseQuestionViewController, animated: Bool) {
        guard let previous else { return }
        previous.willMove(toParent: nil)
        let finish = {
            previous.view.removeFromSuperview()
            previous.removeFromParent()
        }
        guard animated else {
            finish()
            return
        }
        questionContainer.layoutIfNeeded()
        let isRightToLeft = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let offset: CGFloat = UIAccessibility.isReduceMotionEnabled ? 0 : (isRightToLeft ? -56 : 56)
        next.view.alpha = 0
        next.view.transform = CGAffineTransform(translationX: offset, y: 0)
        UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
            next.view.alpha = 1
            next.view.transform = .identity
            previous.view.alpha = 0
            previous.view.transform = CGAffineTransform(translationX: -offset, y: 0)
        } completion: { _ in
            finish()
        }
    }

    private func check() {
        guard !isShowingFeedback, !isAwaitingVerdict, let question = currentQuestion, let outcome = question.submit() else { return }
        isAwaitingVerdict = true
        checkButton.isEnabled = false
        progressBar.setProgress(CGFloat(answeredCount + 1) / CGFloat(totalCount), animated: true)
        UINotificationFeedbackGenerator().notificationOccurred(outcome.isCorrect ? .success : .error)
        delegate?.quizSession(self, didAnswer: outcome, for: question.viewModel)
    }

    /// Raises the feedback panel for the answer just checked; `isLast` turns Continue into See Results.
    func showFeedback(for outcome: QuestionOutcome, xpEarned: Int, isLast: Bool) {
        isAwaitingVerdict = false
        let title = isLast ? String(localized: "See Results") : String(localized: "Continue")
        feedbackPanel.configure(outcome: outcome, xpEarned: xpEarned, continueTitle: title)
        isShowingFeedback = true
        feedbackPanel.isHidden = false
        view.layoutIfNeeded()
        feedbackHidden?.isActive = false
        feedbackShown?.isActive = true
        let animations = {
            self.view.layoutIfNeeded()
            self.checkButton.alpha = 0
        }
        if UIAccessibility.isReduceMotionEnabled {
            animations()
        } else {
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.3, options: [.allowUserInteraction], animations: animations)
        }
        currentQuestion?.setBottomObstruction(obstructionHeight, animated: true)
        UIAccessibility.post(notification: .screenChanged, argument: feedbackPanel.verdictElement)
    }

    /// How far the feedback panel reaches above the Check button, which the question must scroll clear of.
    private var obstructionHeight: CGFloat {
        let panelTop = view.bounds.height - feedbackPanel.bounds.height
        return max(0, questionContainer.frame.maxY - panelTop)
    }

    private func hideFeedback(animated: Bool) {
        guard isShowingFeedback else { return }
        isShowingFeedback = false
        feedbackShown?.isActive = false
        feedbackHidden?.isActive = true
        let animations = {
            self.view.layoutIfNeeded()
            self.checkButton.alpha = 1
        }
        let completion: (Bool) -> Void = { _ in
            guard !self.isShowingFeedback else { return }
            self.feedbackPanel.isHidden = true
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    private func continueTapped() {
        guard isShowingFeedback else { return }
        delegate?.quizSessionDidContinue(self)
    }

    @objc private func closeTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        delegate?.quizSessionDidRequestClose(self)
    }

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        let inputs = ["1", "2", "3", "4", "5", "6", "a", "b", "c", "d", "e", "f", "t"]
        var commands = inputs.map { input in
            UIKeyCommand(input: input, modifierFlags: [], action: #selector(answerKeyPressed(_:)))
        }
        let confirm = UIKeyCommand(title: String(localized: "Check or Continue"), action: #selector(returnPressed), input: "\r")
        confirm.wantsPriorityOverSystemBehavior = true
        commands.append(confirm)
        commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        return commands
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        becomeFirstResponder()
    }

    @objc private func answerKeyPressed(_ command: UIKeyCommand) {
        guard !isShowingFeedback, let input = command.input else { return }
        _ = currentQuestion?.handleKeyInput(input)
    }

    @objc private func returnPressed() {
        if isShowingFeedback {
            feedbackPanel.performContinue()
        } else if checkButton.isEnabled {
            check()
        }
    }

    #if DEBUG
    /// Screenshot rig: answers the current question and checks it.
    func demoAnswer(correctly: Bool) {
        currentQuestion?.demoChooseAnswer(correctly: correctly)
        check()
    }
    #endif
}
