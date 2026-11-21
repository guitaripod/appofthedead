import UIKit
import MidgarCore
import Combine

/// The Oracle: a conversation with one deity at a time in a readable column over the deity's glow. An empty
/// conversation offers questions to begin with; answers are written out smoothly as the on-device model produces them,
/// and the conversation follows the newest words unless the person has scrolled back to read.
final class OracleViewController: UIViewController {
    private let viewModel = OracleViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let backdrop = UnderworldBackdropView(seed: 41)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private lazy var dataSource = makeDataSource()
    private let welcomeView = OracleWelcomeView()
    private let composer = OracleComposerView()
    private let composerScrim = OracleComposerScrim()
    private let jumpButton = UIButton(type: .custom)
    private let disclosureHeader = OracleDisclosureView()
    private let headerContainer = UIView()
    private let titleControl = OracleDeityTitleView()
    private lazy var newConversationItem = UIBarButtonItem(
        title: String(localized: "New Conversation"),
        image: UIImage(systemName: "square.and.pencil"),
        primaryAction: UIAction { [weak self] _ in self?.startNewConversation() }
    )
    private var summonView: OracleSummonView?
    private let hapticConductor = OracleHapticConductor()
    private var messagesByID: [UUID: OracleViewModel.ChatMessage] = [:]
    private var reveal: OracleStreamReveal?
    private var revealMessageID: UUID?
    private var isModelReady = false
    private var isPinnedToBottom = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.night
        setupBackdrop()
        setupTableView()
        setupWelcome()
        setupComposer()
        setupJumpButton()
        setupNavigationItem()
        setupSummon()
        setupBindings()
        checkModelStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        checkModelStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MidgarSignals.noteScreen("oracle", feature: true)
        if !composer.textView.isFirstResponder {
            becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keepConversationClearOfComposer()
        sizeDisclosureHeader()
    }

    /// The AI disclosure heads the conversation inside the safe area, clear of an iPad sidebar floating over the table.
    private func sizeDisclosureHeader() {
        let insets = tableView.safeAreaInsets
        let width = tableView.bounds.width - insets.left - insets.right
        guard width > 0 else { return }
        disclosureHeader.fit(toWidth: width)
        disclosureHeader.frame.origin.x = insets.left
        let frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: disclosureHeader.frame.height)
        guard headerContainer.frame != frame || tableView.tableHeaderView !== headerContainer else { return }
        headerContainer.frame = frame
        tableView.tableHeaderView = headerContainer
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var keyCommands: [UIKeyCommand]? {
        let newConversation = UIKeyCommand(title: String(localized: "New Conversation"), action: #selector(startNewConversationFromKeyboard), input: "n", modifierFlags: .command)
        let stop = UIKeyCommand(title: String(localized: "Stop Answering"), action: #selector(stopFromKeyboard), input: UIKeyCommand.inputEscape)
        stop.wantsPriorityOverSystemBehavior = true
        return [newConversation, stop]
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(stopFromKeyboard):
            return viewModel.isGenerating && composer.textView.markedTextRange == nil
        case #selector(startNewConversationFromKeyboard):
            return !messagesByID.isEmpty
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    /// Opens a conversation with the deity at `deityId`, as if it had been chosen from the list, with `draft` waiting
    /// in the message field for the person to send.
    func openConversation(withDeityId deityId: String, draft: String? = nil) {
        loadViewIfNeeded()
        guard let deity = viewModel.availableDeities.first(where: { $0.id == deityId }) else {
            MidgarLog.notice("Oracle has no deity \(deityId)", category: .ui)
            return
        }
        if deity.id != viewModel.selectedDeity?.id {
            viewModel.selectDeity(deity)
        }
        if let draft {
            composer.setText(draft)
        }
    }

    private func setupBackdrop() {
        backdrop.glowCenter = CGPoint(x: 0.5, y: 1.08)
        backdrop.glowIntensity = 0.2
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.showsHorizontalScrollIndicator = false
        tableView.alwaysBounceHorizontal = false
        tableView.allowsSelection = true
        tableView.estimatedRowHeight = 140
        tableView.delegate = self
        tableView.register(OracleMessageCell.self, forCellReuseIdentifier: OracleMessageCell.reuseIdentifier)
        headerContainer.addSubview(disclosureHeader)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupWelcome() {
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.onPrompt = { [weak self] prompt in self?.send(prompt) }
        welcomeView.onChangeGuide = { [weak self] in self?.selectDeity() }
        view.addSubview(welcomeView)
    }

    private func setupComposer() {
        composerScrim.translatesAutoresizingMaskIntoConstraints = false
        composerScrim.isUserInteractionEnabled = false
        view.addSubview(composerScrim)
        composer.translatesAutoresizingMaskIntoConstraints = false
        composer.onSend = { [weak self] in
            guard let self else { return }
            send(composer.question, fromComposer: true)
        }
        composer.onStop = { [weak self] in self?.viewModel.stopGenerating() }
        composer.onChooseDeity = { [weak self] in self?.selectDeity() }
        view.addSubview(composer)

        let guide = view.safeAreaLayoutGuide
        let preferredWidth = composer.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -24)
        preferredWidth.priority = .init(999)
        NSLayoutConstraint.activate([
            composer.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            composer.widthAnchor.constraint(lessThanOrEqualToConstant: OracleMessageCell.columnWidth),
            composer.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: 12),
            preferredWidth,
            composer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10),
            composerScrim.topAnchor.constraint(equalTo: composer.topAnchor, constant: -28),
            composerScrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            composerScrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerScrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomeView.topAnchor.constraint(equalTo: guide.topAnchor),
            welcomeView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            welcomeView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            welcomeView.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -4),
        ])
    }

    private func setupJumpButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrow.down")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
        configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        configuration.background.strokeColor = UIColor.white.withAlphaComponent(0.12)
        configuration.background.strokeWidth = 1
        jumpButton.configuration = configuration
        jumpButton.accessibilityLabel = String(localized: "Show latest")
        jumpButton.alpha = 0
        jumpButton.isHidden = true
        jumpButton.translatesAutoresizingMaskIntoConstraints = false
        jumpButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            isPinnedToBottom = true
            scrollToBottom(animated: true)
        }, for: .touchUpInside)
        view.addSubview(jumpButton)
        NSLayoutConstraint.activate([
            jumpButton.centerXAnchor.constraint(equalTo: composer.centerXAnchor),
            jumpButton.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -12),
            jumpButton.widthAnchor.constraint(equalToConstant: 40),
            jumpButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func setupNavigationItem() {
        navigationItem.largeTitleDisplayMode = .never
        title = String(localized: "Oracle")
        titleControl.translatesAutoresizingMaskIntoConstraints = false
        titleControl.addAction(UIAction { [weak self] _ in self?.selectDeity() }, for: .touchUpInside)
        navigationItem.titleView = titleControl
        newConversationItem.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        newConversationItem.accessibilityLabel = String(localized: "New Conversation")
        navigationItem.rightBarButtonItem = newConversationItem
    }

    private func setupSummon() {
        let summon = OracleSummonView(
            deityColor: viewModel.selectedDeity.map { PapyrusDesignSystem.Colors.tradition($0.color) },
            isSimulator: DeviceUtility.isSimulator
        )
        summon.translatesAutoresizingMaskIntoConstraints = false
        summon.isHidden = true
        let model = MLXModelManager.shared.activeModel
        summon.configure(modelName: model.displayName, sizeGB: model.approximateDownloadGB)
        summon.onAwaken = { [weak self] in
            Task { await self?.viewModel.loadModel() }
        }
        summon.onWhy = { [weak self] in
            guard let self else { return }
            let alert = PapyrusAlert(
                title: String(localized: "Why the download?"),
                message: String(localized: "The Oracle is a private AI that runs entirely on your iPhone, never on a server. The model is downloaded once and kept on your device."),
                style: .alert
            )
            alert.addAction(PapyrusAlert.Action(title: String(localized: "Understood"), style: .default))
            alert.present(from: self)
        }
        view.addSubview(summon)
        NSLayoutConstraint.activate([
            summon.topAnchor.constraint(equalTo: view.topAnchor),
            summon.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            summon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        summonView = summon
    }

    /// The conversation, the writing reply and the deity follow the view model as it changes, in the same turn, so a
    /// reply is never drawn from a stale copy of the conversation.
    private func setupBindings() {
        viewModel.$messages
            .sink { [weak self] messages in self?.apply(messages) }
            .store(in: &cancellables)
        viewModel.$writingMessageID
            .sink { [weak self] id in self?.writingMessageChanged(to: id) }
            .store(in: &cancellables)
        viewModel.$isGenerating
            .sink { [weak self] isGenerating in self?.composer.setGenerating(isGenerating) }
            .store(in: &cancellables)
        viewModel.$selectedDeity
            .sink { [weak self] deity in self?.deityChanged(to: deity) }
            .store(in: &cancellables)
        viewModel.$isModelLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoaded in self?.modelLoadedChanged(isLoaded) }
            .store(in: &cancellables)
        bindModelDownload()
    }

    private func bindModelDownload() {
        viewModel.$isModelLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self, isLoading else { return }
                summonView?.apply(MLXModelManager.shared.isModelDownloadedSync ? .preparing : .downloading)
                hapticConductor.start()
            }
            .store(in: &cancellables)
        viewModel.$downloadProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.summonView?.update(progress: progress)
                self?.hapticConductor.update(progress: progress)
            }
            .store(in: &cancellables)
        viewModel.$downloadStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status.contains("Loading Oracle model") {
                    self?.summonView?.apply(.preparing)
                } else if !status.isEmpty {
                    self?.summonView?.setStatus(status)
                }
            }
            .store(in: &cancellables)
        viewModel.$downloadStage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stage in
                guard !stage.isEmpty else { return }
                self?.summonView?.setStatus(stage)
            }
            .store(in: &cancellables)
        viewModel.$modelError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in self?.showModelError(error) }
            .store(in: &cancellables)
    }

    private func showModelError(_ message: String) {
        let alert = PapyrusAlert(title: String(localized: "Oracle Error"), message: message, style: .alert)
        alert.addAction(PapyrusAlert.Action(title: String(localized: "OK"), style: .default))
        alert.present(from: self)
    }

    private func modelLoadedChanged(_ isLoaded: Bool) {
        isModelReady = isLoaded
        if isLoaded {
            summonView?.update(progress: 1)
            hapticConductor.complete()
            dismissSummon()
        } else {
            showSummon()
        }
        renderVisibility()
    }

    private func deityChanged(to deity: OracleViewModel.Deity?) {
        guard let deity else { return }
        let accent = PapyrusDesignSystem.Colors.tradition(deity.color)
        titleControl.configure(deity: deity)
        composer.setDeity(deity)
        welcomeView.configure(deity: deity)
        UIView.animate(withDuration: 0.4) {
            self.backdrop.glowColor = accent
        }
        summonView?.setDeity(color: accent)
    }

    private func showSummon() {
        summonView?.isHidden = false
        summonView?.alpha = 1
        summonView?.resume()
        if MLXModelManager.shared.isModelDownloadedSync {
            summonView?.apply(.preparing)
            if !viewModel.isModelLoading && !viewModel.isModelLoaded {
                Task { await viewModel.loadModel() }
            }
        } else {
            summonView?.apply(.idle)
        }
    }

    private func dismissSummon() {
        hapticConductor.stop()
        guard let summon = summonView, !summon.isHidden else { return }
        UIView.animate(withDuration: 0.5, animations: {
            summon.alpha = 0
        }, completion: { _ in
            summon.pause()
            summon.isHidden = true
        })
    }

    private func checkModelStatus() {
        if viewModel.isModelLoaded != OracleVoice.shared.isReady {
            viewModel.syncModelLoadedState()
        }
        isModelReady = viewModel.isModelLoaded
        if isModelReady {
            summonView?.isHidden = true
        } else {
            showSummon()
        }
        renderVisibility()
    }

    /// One place decides what shows: the summoning while the model is away, otherwise the welcome for an empty
    /// conversation or the conversation itself, with the composer under both.
    private func renderVisibility() {
        let hasMessages = !messagesByID.isEmpty
        composer.isHidden = !isModelReady
        composerScrim.isHidden = !isModelReady
        tableView.isHidden = !isModelReady || !hasMessages
        welcomeView.isHidden = !isModelReady || hasMessages
        newConversationItem.isEnabled = hasMessages
        updateJumpButton()
    }

    /// Asks `text`; the composer is emptied only when the question came from it, so a suggested question leaves a
    /// draft alone.
    private func send(_ text: String, fromComposer: Bool = false) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !viewModel.isGenerating else { return }
        if CompassionGuard.needsCare(question) {
            if fromComposer {
                composer.clear()
            }
            isPinnedToBottom = true
            viewModel.respondWithCare(to: question)
            return
        }
        guard let deity = viewModel.selectedDeity, mayConsult(deity) else { return }
        if fromComposer {
            composer.clear()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isPinnedToBottom = true
        Diagnostics.logUserAction("oracleQuestionSent", parameters: ["deityId": deity.id], category: .viewModel)
        Task { await viewModel.sendMessage(question) }
    }

    private func retry(_ failureID: UUID) {
        guard !viewModel.isGenerating, let deity = viewModel.selectedDeity, mayConsult(deity) else { return }
        isPinnedToBottom = true
        Task { await viewModel.retry(failureID: failureID) }
    }

    /// Whether the person may ask `deity` now; past the free limit it shows the plans instead.
    private func mayConsult(_ deity: OracleViewModel.Deity) -> Bool {
        guard let user = DatabaseManager.shared.fetchUser() else {
            MidgarLog.error("Oracle cannot ask: no user record", category: .viewModel)
            return false
        }
        guard user.canConsultOracle(deityId: deity.id) else {
            present(PaywallViewController(reason: .oracleLimit(deityId: deity.id, deityName: deity.name)), animated: true)
            return false
        }
        return true
    }

    private func startNewConversation() {
        guard !messagesByID.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.transition(with: view, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.viewModel.startNewConversation()
        }
    }

    @objc private func startNewConversationFromKeyboard() {
        startNewConversation()
    }

    @objc private func stopFromKeyboard() {
        viewModel.stopGenerating()
    }

    @objc private func selectDeity() {
        guard !viewModel.availableDeities.isEmpty, presentedViewController == nil else { return }
        let picker = DeitySelectionViewController(deities: viewModel.availableDeities, currentDeity: viewModel.selectedDeity) { [weak self] chosen in
            guard let self, let deity = viewModel.availableDeities.first(where: { $0.id == chosen.id }), deity.id != viewModel.selectedDeity?.id else { return }
            UIView.transition(with: view, duration: 0.3, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.viewModel.selectDeity(deity)
            }
        }
        present(picker, animated: true)
    }

    @objc private func handleMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        guard !viewModel.isGenerating, viewModel.isModelLoaded else { return }
        MLXModelManager.shared.handleMemoryPressure()
    }
}

extension OracleViewController {
    private func makeDataSource() -> UITableViewDiffableDataSource<Int, UUID> {
        let source = UITableViewDiffableDataSource<Int, UUID>(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: OracleMessageCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? OracleMessageCell {
                self?.configure(cell, for: id)
            }
            return cell
        }
        source.defaultRowAnimation = .fade
        return source
    }

    private func configure(_ cell: OracleMessageCell, for id: UUID) {
        guard let message = messagesByID[id] else { return }
        let isWriting = id == revealMessageID
        cell.configure(text: isWriting ? "" : message.text, role: role(for: message), isWriting: isWriting)
        if isWriting, let reveal {
            cell.showRevealedText(reveal.visibleText)
        }
        cell.onRetry = message.kind == .failure ? { [weak self] in self?.retry(id) } : nil
    }

    private func role(for message: OracleViewModel.ChatMessage) -> OracleMessageCell.Role {
        switch message.kind {
        case .care:
            return .care
        case .notice:
            return .notice(message.deity)
        case .failure:
            return .failure(message.deity)
        case .conversation:
            return message.isUser ? .question : .answer(message.deity)
        }
    }

    /// Brings the table in step with the conversation: new turns are inserted, replaced ones redrawn, and the reply
    /// being written is handed to the reveal rather than redrawn on every word.
    private func apply(_ messages: [OracleViewModel.ChatMessage]) {
        let previousIDs = dataSource.snapshot().numberOfSections > 0 ? dataSource.snapshot().itemIdentifiers : []
        var changed: [UUID] = []
        var next: [UUID: OracleViewModel.ChatMessage] = [:]
        for message in messages {
            next[message.id] = message
            if let old = messagesByID[message.id], old.text != message.text || old.kind != message.kind {
                changed.append(message.id)
                if old.kind != message.kind, message.kind == .failure || message.kind == .notice {
                    announce(message.text)
                }
            }
        }
        messagesByID = next
        if let id = revealMessageID {
            if let message = next[id], message.kind == .conversation {
                reveal?.update(text: message.text, isComplete: viewModel.writingMessageID != id)
                changed.removeAll { $0 == id }
            } else {
                endReveal()
            }
        }
        let ids = messages.map(\.id)
        let reconfigure = changed.filter { previousIDs.contains($0) }
        if ids != previousIDs || !reconfigure.isEmpty {
            var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
            snapshot.appendSections([0])
            snapshot.appendItems(ids)
            snapshot.reconfigureItems(reconfigure)
            let appended = ids.count > previousIDs.count && Array(ids.prefix(previousIDs.count)) == previousIDs
            dataSource.apply(snapshot, animatingDifferences: appended && view.window != nil && !previousIDs.isEmpty)
            if appended && isPinnedToBottom {
                scrollToBottom(animated: !previousIDs.isEmpty)
            }
        }
        renderVisibility()
    }

    private func writingMessageChanged(to id: UUID?) {
        if let id {
            beginReveal(of: id)
            return
        }
        guard let current = revealMessageID else { return }
        if let message = messagesByID[current], message.kind == .conversation, !message.text.isEmpty {
            reveal?.update(text: message.text, isComplete: true)
        } else {
            endReveal()
        }
    }

    private func beginReveal(of id: UUID) {
        endReveal()
        let reveal = OracleStreamReveal(format: OracleMessageCell.answerText)
        reveal.onUpdate = { [weak self] text in self?.showRevealed(text) }
        reveal.onFinish = { [weak self] in self?.revealFinished() }
        self.reveal = reveal
        revealMessageID = id
        reconfigureRow(id)
    }

    /// Stops the reveal and draws the message as it stands.
    private func endReveal() {
        guard let id = revealMessageID else { return }
        reveal?.cancel()
        reveal = nil
        revealMessageID = nil
        reconfigureRow(id)
    }

    private func revealFinished() {
        guard let id = revealMessageID else { return }
        reveal = nil
        revealMessageID = nil
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
        if let text = messagesByID[id]?.text {
            announce(OracleMessageCell.answerText(text).string)
        }
        DispatchQueue.main.async { [weak self] in
            self?.reconfigureRow(id)
        }
    }

    /// Reads `text` to a VoiceOver user after what is already being spoken.
    private func announce(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning, !text.isEmpty else { return }
        UIAccessibility.post(notification: .announcement, argument: NSAttributedString(string: text, attributes: [.accessibilitySpeechQueueAnnouncement: true]))
    }

    private func reconfigureRow(_ id: UUID) {
        var snapshot = dataSource.snapshot()
        guard snapshot.indexOfItem(id) != nil else { return }
        snapshot.reconfigureItems([id])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Draws the newest revealed text; when it takes another line the row grows and the conversation follows it.
    private func showRevealed(_ text: NSAttributedString) {
        guard let id = revealMessageID, let indexPath = dataSource.indexPath(for: id),
              let cell = tableView.cellForRow(at: indexPath) as? OracleMessageCell else { return }
        guard cell.showRevealedText(text) else { return }
        UIView.performWithoutAnimation {
            tableView.performBatchUpdates(nil)
        }
        if isPinnedToBottom {
            scrollToBottom(animated: true)
        }
    }

    /// The bottom of the conversation clears the composer and the keyboard; a reader at the bottom stays there.
    private func keepConversationClearOfComposer() {
        let covered = max(0, view.bounds.maxY - composer.frame.minY + 12)
        let inset = max(0, covered - view.safeAreaInsets.bottom)
        if abs(tableView.contentInset.bottom - inset) > 0.5 {
            tableView.contentInset.bottom = inset
            tableView.verticalScrollIndicatorInsets.bottom = inset
        }
        guard isPinnedToBottom, !tableView.isTracking, !tableView.isDecelerating, distanceFromBottom > 1 else { return }
        scrollToBottom(animated: false)
    }

    private var bottomOffset: CGPoint {
        let inset = tableView.adjustedContentInset
        let y = max(-inset.top, tableView.contentSize.height - tableView.bounds.height + inset.bottom)
        return CGPoint(x: tableView.contentOffset.x, y: y)
    }

    private var distanceFromBottom: CGFloat {
        bottomOffset.y - tableView.contentOffset.y
    }

    /// A short glide for a line or two; a longer way goes to the last row, which measures the rows it passes instead
    /// of trusting their estimated heights.
    private func scrollToBottom(animated: Bool) {
        let rows = tableView.numberOfSections > 0 ? tableView.numberOfRows(inSection: 0) : 0
        guard rows > 0, tableView.bounds.height > 0 else { return }
        tableView.layoutIfNeeded()
        let target = bottomOffset
        let distance = abs(target.y - tableView.contentOffset.y)
        guard distance > 0.5 else { return }
        let animates = animated && !UIAccessibility.isReduceMotionEnabled
        if !animates || distance > tableView.bounds.height / 2 {
            tableView.scrollToRow(at: IndexPath(row: rows - 1, section: 0), at: .bottom, animated: animates)
        } else {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
                self.tableView.contentOffset = target
            }
        }
    }

    private func updateJumpButton() {
        let shows = !tableView.isHidden && distanceFromBottom > 160
        guard shows == jumpButton.isHidden else { return }
        if shows {
            jumpButton.isHidden = false
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.jumpButton.alpha = shows ? 1 : 0
            self.jumpButton.transform = shows ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            if !shows && self.jumpButton.alpha == 0 {
                self.jumpButton.isHidden = true
            }
            self.updateJumpButton()
        })
    }

    /// Shares a reply as a card with the deity's name and the question it answered.
    private func shareReply(_ message: OracleViewModel.ChatMessage, deity: OracleViewModel.Deity, from cell: UIView) {
        let ids = dataSource.snapshot().itemIdentifiers
        let question = ids.firstIndex(of: message.id).flatMap { index in
            ids[..<index].reversed().compactMap { messagesByID[$0] }.first(where: \.isUser)?.text
        }
        let image = OracleQuoteRenderer.render(reply: message.text, question: question, deity: deity)
        let text = String(localized: "I asked \(deity.name) about the afterlife. \(JudgmentViewModel.appStoreURL.absoluteString)")
        let controller = UIActivityViewController(activityItems: [SoulCardShareItem(image: image), text], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds
        controller.completionWithItemsHandler = { activity, completed, _, _ in
            guard completed else { return }
            Diagnostics.logUserAction("oracleReplyShared", parameters: ["deityId": deity.id, "activity": activity?.rawValue ?? "unknown"], category: .viewModel)
        }
        present(controller, animated: true)
    }
}

extension OracleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        dataSource.itemIdentifier(for: indexPath).flatMap { messagesByID[$0] }?.kind == .care
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath), messagesByID[id]?.kind == .care else { return }
        UIApplication.shared.open(CompassionGuard.helplineURL)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let id = dataSource.itemIdentifier(for: indexPath), id != revealMessageID,
              let message = messagesByID[id], !message.text.isEmpty, message.kind != .care else { return nil }
        return UIContextMenuConfiguration(identifier: id.uuidString as NSString, previewProvider: nil) { [weak self] _ in
            var actions: [UIMenuElement] = [
                UIAction(title: String(localized: "Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = message.text
                },
            ]
            if !message.isUser, message.kind == .conversation, let deity = message.deity {
                actions.insert(UIAction(title: String(localized: "Share as Card"), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    guard let self, let indexPath = dataSource.indexPath(for: id), let cell = tableView.cellForRow(at: indexPath) else { return }
                    shareReply(message, deity: deity, from: cell)
                }, at: 0)
            }
            return UIMenu(children: actions)
        }
    }

    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        bubblePreview(for: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        bubblePreview(for: configuration)
    }

    /// Lifts only the message's bubble for its menu, not the whole width of the row.
    private func bubblePreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? NSString, let id = UUID(uuidString: identifier as String),
              let indexPath = dataSource.indexPath(for: id),
              let cell = tableView.cellForRow(at: indexPath) as? OracleMessageCell else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.visiblePath = UIBezierPath(roundedRect: cell.bubbleView.bounds, cornerRadius: 20)
        return UITargetedPreview(view: cell.bubbleView, parameters: parameters)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking || scrollView.isDecelerating {
            isPinnedToBottom = distanceFromBottom < 48
        }
        updateJumpButton()
    }
}

/// Darkens the conversation as it slides under the composer, so the field always reads against the night.
final class OracleComposerScrim: UIView {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let gradient = layer as? CAGradientLayer else { return }
        let night = PapyrusDesignSystem.Colors.Core.night
        gradient.colors = [night.withAlphaComponent(0).cgColor, night.withAlphaComponent(0.82).cgColor, night.withAlphaComponent(0.94).cgColor]
        gradient.locations = [0, 0.4, 1]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
