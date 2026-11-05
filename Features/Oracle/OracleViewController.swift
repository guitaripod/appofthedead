import UIKit
import MidgarCore
import Combine
final class OracleViewController: UIViewController {
    let tableView = UITableView()
    private var displayedMessageCount = 0
    private var isUserNearBottom = true
    let inputContainerView = UIView()
    let messageTextView = UITextView()
    let sendButton = UIButton(type: .system)
    private let deitySelectionButton = UIButton(type: .system)
    var promptSuggestionsView = UIView()
    private let viewModel = OracleViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var lastInputContainerTop: CGFloat = 0
    private var typingIndicator: UIActivityIndicatorView?
    private var summonView: OracleSummonView?
    private let disclosureHeader = OracleDisclosureView()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updateLayoutForIPad()
        checkModelStatus()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = String(localized: "Oracle")
        checkModelStatus()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        followInputContainerWhenKeyboardMoves()
        sizeDisclosureHeader()
    }

    /// Keeps the AI disclosure above the conversation as wide as the table, which a table header does not do by itself.
    private func sizeDisclosureHeader() {
        guard tableView.bounds.width > 0, disclosureHeader.fit(toWidth: tableView.bounds.width) else { return }
        tableView.tableHeaderView = disclosureHeader
    }

    /// The keyboard layout guide moves the input bar; the newest message stays above it.
    private func followInputContainerWhenKeyboardMoves() {
        let top = inputContainerView.frame.minY
        defer { lastInputContainerTop = top }
        guard lastInputContainerTop != 0, top < lastInputContainerTop else { return }
        scrollToBottom()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            inputContainerView.layer.shadowColor = traitCollection.userInterfaceStyle == .dark ?
                UIColor.white.cgColor : UIColor.black.cgColor
            inputContainerView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.05 : 0.1
            messageTextView.layer.borderColor = UIColor.Papyrus.separator.cgColor
        }
    }
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        setupTableView()
        setupInputContainer()
        setupPromptSuggestions()
        setupConstraints()
        setupSummon()
        updateDeityButton()
    }
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.Papyrus.background
        tableView.keyboardDismissMode = .interactive
        tableView.alwaysBounceHorizontal = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.clipsToBounds = true
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.tableHeaderView = disclosureHeader
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false 
        tableView.addGestureRecognizer(tapGesture)
    }
    private func setupInputContainer() {
        inputContainerView.backgroundColor = UIColor.Papyrus.cardBackground
        inputContainerView.layer.borderWidth = 1
        inputContainerView.layer.borderColor = UIColor.Papyrus.separator.cgColor
        inputContainerView.layer.shadowColor = UITraitCollection.current.userInterfaceStyle == .dark ?
            UIColor.white.cgColor : UIColor.black.cgColor
        inputContainerView.layer.shadowOpacity = UITraitCollection.current.userInterfaceStyle == .dark ? 0.05 : 0.1
        inputContainerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        inputContainerView.layer.shadowRadius = 4
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainerView)
        deitySelectionButton.tintColor = UIColor.Papyrus.gold
        deitySelectionButton.addTarget(self, action: #selector(selectDeity), for: .touchUpInside)
        deitySelectionButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(deitySelectionButton)
        messageTextView.font = .systemFont(ofSize: 16)
        messageTextView.layer.cornerRadius = 18
        messageTextView.layer.borderColor = UIColor.Papyrus.separator.cgColor
        messageTextView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                PapyrusDesignSystem.Colors.Core.darkCard :
                PapyrusDesignSystem.Colors.Core.beige
        }
        messageTextView.textColor = UIColor.Papyrus.primaryText
        messageTextView.layer.borderWidth = 1
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        messageTextView.isScrollEnabled = false
        messageTextView.delegate = self
        messageTextView.keyboardAppearance = .dark 
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(messageTextView)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = UIColor.Papyrus.gold
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(sendButton)
    }
    private func setupPromptSuggestions() {
        promptSuggestionsView.backgroundColor = UIColor.Papyrus.background
        promptSuggestionsView.translatesAutoresizingMaskIntoConstraints = false
        promptSuggestionsView.isHidden = true
        view.addSubview(promptSuggestionsView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        promptSuggestionsView.addGestureRecognizer(tapGesture)
    }
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            inputContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            deitySelectionButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            deitySelectionButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            deitySelectionButton.widthAnchor.constraint(equalToConstant: 36),
            deitySelectionButton.heightAnchor.constraint(equalToConstant: 36),
            messageTextView.leadingAnchor.constraint(equalTo: deitySelectionButton.trailingAnchor, constant: 8),
            messageTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 12),
            messageTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            messageTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            messageTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            promptSuggestionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            promptSuggestionsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            promptSuggestionsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            promptSuggestionsView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])
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
        view.insertSubview(summon, belowSubview: promptSuggestionsView)
        NSLayoutConstraint.activate([
            summon.topAnchor.constraint(equalTo: view.topAnchor),
            summon.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            summon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summon.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        summonView = summon
    }
    private func setupBindings() {
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.applyMessages(messages)
            }
            .store(in: &cancellables)
        viewModel.$selectedDeity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDeityButton()
            }
            .store(in: &cancellables)
        viewModel.$isModelLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    self.summonView?.apply(MLXModelManager.shared.isModelDownloadedSync ? .preparing : .downloading)
                    self.hapticConductor.start()
                }
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
                guard let self else { return }
                if status.contains("Loading Oracle model") {
                    self.summonView?.apply(.preparing)
                } else if !status.isEmpty {
                    self.summonView?.setStatus(status)
                }
            }
            .store(in: &cancellables)
        viewModel.$downloadStage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stage in
                guard let self, !stage.isEmpty else { return }
                self.summonView?.setStatus(stage)
            }
            .store(in: &cancellables)
        viewModel.$selectedDeity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deity in
                guard let hex = deity?.color, let color = UIColor(hex: hex) else { return }
                self?.summonView?.setDeity(color: color)
            }
            .store(in: &cancellables)
        viewModel.$isModelLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoaded in
                guard let self else { return }
                self.inputContainerView.isHidden = !isLoaded
                self.tableView.isHidden = !isLoaded
                self.updatePromptSuggestions()
                if isLoaded {
                    self.summonView?.update(progress: 1)
                    self.hapticConductor.complete()
                    self.dismissSummon()
                } else {
                    self.showSummon()
                }
            }
            .store(in: &cancellables)
        viewModel.$isGenerating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGenerating in
                self?.sendButton.isEnabled = !isGenerating
                self?.messageTextView.isEditable = !isGenerating
            }
            .store(in: &cancellables)
        viewModel.$modelError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                let alert = PapyrusAlert(
                    title: String(localized: "Oracle Error"),
                    message: error,
                    style: .alert
                )
                alert.addAction(PapyrusAlert.Action(title: String(localized: "OK"), style: .default))
                alert.present(from: self!)
            }
            .store(in: &cancellables)
    }

    private let hapticConductor = OracleHapticConductor()

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
        if viewModel.isModelLoaded {
            summonView?.isHidden = true
            inputContainerView.isHidden = false
            tableView.isHidden = false
        } else {
            showSummon()
            inputContainerView.isHidden = true
            tableView.isHidden = true
        }
        updatePromptSuggestions()
    }
    @objc func sendMessage() {
        guard let text = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        guard !viewModel.isGenerating else {
            return
        }
        if CompassionGuard.needsCare(text) {
            messageTextView.text = ""
            textViewDidChange(messageTextView)
            viewModel.respondWithCare(to: text)
            return
        }
        guard let user = DatabaseManager.shared.fetchUser(),
              let deity = viewModel.selectedDeity else {
            return
        }
        if !user.canConsultOracle(deityId: deity.id) {
            let paywall = PaywallViewController(reason: .oracleLimit(deityId: deity.id, deityName: deity.name))
            present(paywall, animated: true)
            return
        }
        messageTextView.text = ""
        textViewDidChange(messageTextView)
        Task {
            await viewModel.sendMessage(text)
        }
    }
    @objc private func downloadModel() {
        Task {
            await viewModel.loadModel()
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
            messageTextView.text = draft
            textViewDidChange(messageTextView)
        }
    }

    @objc private func selectDeity() {
        guard !viewModel.availableDeities.isEmpty else {
            return
        }
        let deitiesArray = viewModel.availableDeities.map { deity in
            return OracleViewModel.Deity(
                id: deity.id,
                name: deity.name,
                tradition: deity.tradition,
                role: deity.role,
                avatar: deity.avatar,
                color: deity.color,
                systemPrompt: deity.systemPrompt,
                suggestedPrompts: deity.suggestedPrompts
            )
        }
        let currentDeityCopy = deitiesArray.first { $0.id == viewModel.selectedDeity?.id }
        let deitySelector = DeitySelectionViewController(
            deities: deitiesArray,
            currentDeity: currentDeityCopy
        ) { [weak self] selectedDeity in
            guard let self = self else { return }
            if let originalDeity = self.viewModel.availableDeities.first(where: { $0.id == selectedDeity.id }) {
                self.animateDeityTransition {
                    self.viewModel.selectDeity(originalDeity)
                }
            }
        }
        if self.presentedViewController == nil {
            self.present(deitySelector, animated: true)
        }
    }
    @objc private func handleMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        tableView.reloadData()
        let memoryStatus = MLXModelManager.shared.checkMemoryStatus()
        let availableMB = memoryStatus.availableMemory / 1024 / 1024
        if !viewModel.isGenerating && viewModel.isModelLoaded {
            MLXModelManager.shared.handleMemoryPressure()
            if availableMB < 500 {
            }
        }
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    private func updateDeityButton() {
        guard let deity = viewModel.selectedDeity else {
            return
        }
        if let iconImage = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            deitySelectionButton.setImage(iconImage.withConfiguration(config), for: .normal)
            deitySelectionButton.tintColor = PapyrusDesignSystem.Colors.tradition(deity.color)
        } else {
            deitySelectionButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
            deitySelectionButton.tintColor = PapyrusDesignSystem.Colors.tradition(deity.color)
        }
        updatePromptSuggestions()
    }
    private func updatePromptSuggestions() {
        promptSuggestionsView.subviews.forEach { $0.removeFromSuperview() }
        let hasRealMessages = viewModel.messages.filter { !$0.text.isEmpty && $0.isUser }.count > 0
        let shouldShowPrompts = !hasRealMessages && viewModel.selectedDeity != nil && viewModel.isModelLoaded
        promptSuggestionsView.isHidden = !shouldShowPrompts
        if viewModel.isModelLoaded {
            tableView.isHidden = shouldShowPrompts
        }
        guard shouldShowPrompts, let deity = viewModel.selectedDeity else { return }
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        promptSuggestionsView.addSubview(containerView)
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        let iconSize: CGFloat = 32
        let iconContainerView = UIView()
        iconContainerView.backgroundColor = PapyrusDesignSystem.Colors.tradition(deity.color).withAlphaComponent(0.15)
        iconContainerView.layer.cornerRadius = iconSize / 2
        iconContainerView.layer.borderWidth = 1
        iconContainerView.layer.borderColor = PapyrusDesignSystem.Colors.tradition(deity.color).withAlphaComponent(0.3).cgColor
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(iconContainerView)
        let iconImageView = UIImageView()
        if let iconImage = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            iconImageView.image = iconImage.withConfiguration(config)
        }
        iconImageView.tintColor = PapyrusDesignSystem.Colors.tradition(deity.color)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.addSubview(iconImageView)
        let nameLabel = UILabel()
        nameLabel.text = deity.name
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = UIColor.Papyrus.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        let gridContainer = UIView()
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gridContainer)
        if let prompts = deity.suggestedPrompts {
            let columns = 2
            let spacing: CGFloat = 8
            let buttonHeight: CGFloat = 48
            for (index, prompt) in prompts.prefix(4).enumerated() {
                let row = index / columns
                let col = index % columns
                let button = createCompactPromptButton(with: prompt, color: deity.color)
                button.translatesAutoresizingMaskIntoConstraints = false
                gridContainer.addSubview(button)
                let isLeftColumn = col == 0
                let isTopRow = row == 0
                let isBottomRow = row == 1
                var constraints: [NSLayoutConstraint] = [
                    button.heightAnchor.constraint(equalToConstant: buttonHeight)
                ]
                if isLeftColumn {
                    constraints.append(button.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor))
                    constraints.append(button.trailingAnchor.constraint(equalTo: gridContainer.centerXAnchor, constant: -spacing/2))
                } else {
                    constraints.append(button.leadingAnchor.constraint(equalTo: gridContainer.centerXAnchor, constant: spacing/2))
                    constraints.append(button.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor))
                }
                if isTopRow {
                    constraints.append(button.topAnchor.constraint(equalTo: gridContainer.topAnchor))
                } else {
                    constraints.append(button.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: buttonHeight + spacing))
                }
                if isBottomRow {
                    constraints.append(button.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor))
                }
                NSLayoutConstraint.activate(constraints)
            }
        }
        let centerYOffset: CGFloat = 0
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: promptSuggestionsView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: promptSuggestionsView.trailingAnchor, constant: -16),
            containerView.centerYAnchor.constraint(equalTo: promptSuggestionsView.centerYAnchor, constant: centerYOffset),
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            headerView.heightAnchor.constraint(equalToConstant: iconSize),
            iconContainerView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconContainerView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: iconSize),
            iconContainerView.heightAnchor.constraint(equalToConstant: iconSize),
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            gridContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            gridContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gridContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gridContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            gridContainer.heightAnchor.constraint(equalToConstant: 104) 
        ])
    }
    private func createPromptButton(with text: String, color: String, isCompact: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = text
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = .systemFont(ofSize: isCompact ? 14 : 16, weight: .medium)
            return updated
        }
        config.baseBackgroundColor = PapyrusDesignSystem.Colors.tradition(color).withAlphaComponent(0.15)
        config.baseForegroundColor = PapyrusDesignSystem.Colors.tradition(color)
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(
            top: isCompact ? 12 : 16,
            leading: isCompact ? 16 : 20,
            bottom: isCompact ? 12 : 16,
            trailing: isCompact ? 16 : 20
        )
        button.configuration = config
        button.layer.borderWidth = 1
        button.layer.borderColor = PapyrusDesignSystem.Colors.tradition(color).cgColor
        button.layer.cornerRadius = isCompact ? 10 : 12
        button.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    private func createCompactPromptButton(with text: String, color: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.backgroundColor = PapyrusDesignSystem.Colors.tradition(color).withAlphaComponent(0.08)
        button.layer.cornerRadius = 8
        let shimmerView = ShimmerBorderView(color: PapyrusDesignSystem.Colors.tradition(color))
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        shimmerView.isUserInteractionEnabled = false
        button.addSubview(shimmerView)
        button.setTitle(text, for: .normal)
        button.setTitleColor(PapyrusDesignSystem.Colors.tradition(color).withAlphaComponent(0.8), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.9
        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: button.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    @objc private func promptButtonTapped(_ sender: UIButton) {
        guard let prompt = sender.titleLabel?.text else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        messageTextView.text = prompt
        textViewDidChange(messageTextView)
        sendMessage()
    }
    /// Structural changes (a message added/removed) reload + force-scroll once; per-token
    /// streaming updates patch only the last cell in place (no reloadData, so the user can
    /// still scroll) and pin to the latest text only if they were already near the bottom.
    private func applyMessages(_ messages: [OracleViewModel.ChatMessage]) {
        if messages.count != displayedMessageCount {
            displayedMessageCount = messages.count
            tableView.reloadData()
            updatePromptSuggestions()
            DispatchQueue.main.async { [weak self] in
                self?.scrollToBottom(animated: false, force: true)
            }
        } else if let last = messages.indices.last {
            let indexPath = IndexPath(row: last, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? ChatMessageCell {
                cell.updateStreamingText(messages[last])
                UIView.performWithoutAnimation { tableView.performBatchUpdates(nil) }
            }
            scrollToBottom(animated: false, force: false)
        }
    }

    private func scrollToBottom(animated: Bool = true, force: Bool = false) {
        guard viewModel.messages.count > 0 else { return }
        guard force || isUserNearBottom else { return }
        let indexPath = IndexPath(row: viewModel.messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    private func animateDeityTransition(completion: @escaping () -> Void) {
        let transitionView = UIView(frame: view.bounds)
        transitionView.backgroundColor = UIColor.Papyrus.background
        transitionView.alpha = 0
        view.addSubview(transitionView)
        if let deity = viewModel.selectedDeity {
            let deityColor = PapyrusDesignSystem.Colors.tradition(deity.color)
            let circleView = UIView()
            circleView.backgroundColor = deityColor.withAlphaComponent(0.3)
            circleView.layer.cornerRadius = 30
            circleView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            let buttonCenter = view.convert(deitySelectionButton.center, from: deitySelectionButton.superview)
            circleView.center = buttonCenter
            transitionView.addSubview(circleView)
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
                circleView.transform = CGAffineTransform(scaleX: 20, y: 20)
                circleView.alpha = 0.1
            })
        }
        UIView.animate(withDuration: 0.2, animations: {
            transitionView.alpha = 1.0
            self.tableView.alpha = 0.3
            self.promptSuggestionsView.alpha = 0.3
        }) { _ in
            completion()
            UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseInOut], animations: {
                transitionView.alpha = 0
                self.tableView.alpha = 1.0
                self.promptSuggestionsView.alpha = 1.0
            }) { _ in
                transitionView.removeFromSuperview()
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                    self.deitySelectionButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }) { _ in
                    UIView.animate(withDuration: 0.2) {
                        self.deitySelectionButton.transform = .identity
                    }
                }
            }
        }
    }
}
extension OracleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        let message = viewModel.messages[indexPath.row]
        cell.configure(with: message)
        return cell
    }
}
extension OracleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard viewModel.messages.indices.contains(indexPath.row),
              viewModel.messages[indexPath.row].kind == .care else { return }
        UIApplication.shared.open(CompassionGuard.helplineURL)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard viewModel.messages.indices.contains(indexPath.row) else { return nil }
        let message = viewModel.messages[indexPath.row]
        guard !message.isUser, message.kind == .conversation, let deity = message.deity, !message.text.isEmpty else { return nil }
        let question = viewModel.messages[..<indexPath.row].last(where: { $0.isUser })?.text
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let share = UIAction(title: String(localized: "Share as Card"), image: UIImage(systemName: "square.and.arrow.up")) { _ in
                self?.shareReply(message.text, question: question, deity: deity, at: indexPath)
            }
            let copy = UIAction(title: String(localized: "Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.string = message.text
            }
            return UIMenu(children: [share, copy])
        }
    }

    /// Shares a reply as a card with the deity's name and the question it answered.
    private func shareReply(_ reply: String, question: String?, deity: OracleViewModel.Deity, at indexPath: IndexPath) {
        let image = OracleQuoteRenderer.render(reply: reply, question: question, deity: deity)
        let message = String(localized: "I asked \(deity.name) about the afterlife. \(JudgmentViewModel.appStoreURL.absoluteString)")
        let controller = UIActivityViewController(activityItems: [SoulCardShareItem(image: image), message], applicationActivities: nil)
        let anchor = tableView.cellForRow(at: indexPath) ?? view
        controller.popoverPresentationController?.sourceView = anchor
        controller.popoverPresentationController?.sourceRect = anchor?.bounds ?? .zero
        controller.completionWithItemsHandler = { activity, completed, _, _ in
            guard completed else { return }
            Diagnostics.logUserAction("oracleReplyShared", parameters: ["deityId": deity.id, "activity": activity?.rawValue ?? "unknown"], category: .viewModel)
        }
        present(controller, animated: true)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let viewportBottom = scrollView.bounds.height - scrollView.adjustedContentInset.bottom - scrollView.adjustedContentInset.top
        if scrollView.contentSize.height <= viewportBottom {
            isUserNearBottom = true
            return
        }
        let maxOffsetY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        isUserNearBottom = (maxOffsetY - scrollView.contentOffset.y) < 120
    }
}
extension OracleViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isEnabled = hasText
        sendButton.alpha = hasText ? 1.0 : 0.5
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        textView.isScrollEnabled = size.height > 120
    }
}
private class ChatMessageCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()
    private let typingIndicator = UIActivityIndicatorView(style: .medium)
    private var bubbleTopConstraint: NSLayoutConstraint?
    private var bubbleLeadingConstraint: NSLayoutConstraint?
    private var bubbleTrailingConstraint: NSLayoutConstraint?
    private var bubbleBottomConstraint: NSLayoutConstraint?
    private lazy var typingIndicatorSizeConstraints = [
        bubbleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
    ]
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(typingIndicator)
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = PapyrusDesignSystem.Typography.sans(16, textStyle: .callout)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        typingIndicator.translatesAutoresizingMaskIntoConstraints = false
        typingIndicator.hidesWhenStopped = true
        typingIndicator.color = UIColor.Papyrus.aged
        setupConstraints()
    }
    private func setupConstraints() {
        bubbleTopConstraint = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        bubbleBottomConstraint = bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 7),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 13),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -13),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -7),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 720),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.88),
            typingIndicator.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            typingIndicator.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])
        bubbleTopConstraint?.priority = UILayoutPriority(999)
        bubbleBottomConstraint?.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            bubbleTopConstraint!,
            bubbleBottomConstraint!
        ])
    }
    func configure(with message: OracleViewModel.ChatMessage) {
        if !message.isUser && message.text.isEmpty {
            messageLabel.text = " "
            messageLabel.isHidden = true
            typingIndicator.startAnimating()
            NSLayoutConstraint.activate(typingIndicatorSizeConstraints)
        } else {
            showText(of: message)
            messageLabel.isHidden = false
            typingIndicator.stopAnimating()
            NSLayoutConstraint.deactivate(typingIndicatorSizeConstraints)
        }
        bubbleLeadingConstraint?.isActive = false
        bubbleTrailingConstraint?.isActive = false
        if message.kind == .care {
            bubbleView.backgroundColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.12)
            bubbleView.layer.borderColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.6).cgColor
            messageLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
            nameLabel.isHidden = true
            bubbleTopConstraint?.constant = 8
            bubbleBottomConstraint?.constant = -8
            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            bubbleLeadingConstraint?.isActive = true
            bubbleTrailingConstraint?.isActive = true
            accessibilityTraits = .link
            accessibilityHint = String(localized: "Opens findahelpline.com")
            return
        }
        accessibilityTraits = .staticText
        accessibilityHint = nil
        if message.isUser {
            bubbleView.backgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
            bubbleView.layer.borderColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.5).cgColor
            messageLabel.textColor = UIColor.Papyrus.beige
            nameLabel.isHidden = true
            bubbleTopConstraint?.constant = 8
            bubbleBottomConstraint?.constant = -8
            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 40)
            bubbleTrailingConstraint?.isActive = true
            bubbleLeadingConstraint?.isActive = true
        } else {
            bubbleView.backgroundColor = PapyrusDesignSystem.Colors.Core.surface
            bubbleView.layer.borderColor = (message.deity.map { PapyrusDesignSystem.Colors.tradition($0.color) } ?? UIColor.white).withAlphaComponent(0.25).cgColor
            messageLabel.textColor = UIColor.Papyrus.primaryText
            if let deity = message.deity {
                nameLabel.isHidden = false
                nameLabel.text = deity.name
                nameLabel.textColor = PapyrusDesignSystem.Colors.tradition(deity.color)
                bubbleTopConstraint?.constant = 28
                bubbleBottomConstraint?.constant = -8
                NSLayoutConstraint.activate([
                    nameLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -4)
                ])
            } else {
                nameLabel.isHidden = true
                bubbleTopConstraint?.constant = 8
                bubbleBottomConstraint?.constant = -8
            }
            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40)
            bubbleLeadingConstraint?.isActive = true
            bubbleTrailingConstraint?.isActive = true
        }
    }
    func updateStreamingText(_ message: OracleViewModel.ChatMessage) {
        if !message.isUser && message.text.isEmpty {
            messageLabel.isHidden = true
            typingIndicator.startAnimating()
            NSLayoutConstraint.activate(typingIndicatorSizeConstraints)
        } else {
            if messageLabel.isHidden {
                messageLabel.isHidden = false
                typingIndicator.stopAnimating()
                NSLayoutConstraint.deactivate(typingIndicatorSizeConstraints)
            }
            showText(of: message)
        }
    }

    /// User messages stay plain; deity replies render the model's Markdown so emphasis shows as
    /// bold and italics rather than asterisks.
    private func showText(of message: OracleViewModel.ChatMessage) {
        if message.isUser {
            messageLabel.attributedText = nil
            messageLabel.font = PapyrusDesignSystem.Typography.sans(16, textStyle: .callout)
            messageLabel.textColor = UIColor.Papyrus.beige
            messageLabel.text = message.text
        } else {
            messageLabel.attributedText = OracleTextFormatter.attributedText(
                from: message.text,
                font: PapyrusDesignSystem.Typography.sans(16, textStyle: .callout),
                color: UIColor.Papyrus.primaryText
            )
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            (constraint.firstItem === nameLabel || constraint.secondItem === nameLabel) &&
            constraint.firstAttribute == .bottom
        })
        NSLayoutConstraint.deactivate(typingIndicatorSizeConstraints)
        typingIndicator.stopAnimating()
        messageLabel.isHidden = false
    }
}
private class ShimmerBorderView: UIView {
    private let borderLayer = CAShapeLayer()
    private let shimmerLayer = CAShapeLayer()
    private let animationDuration: TimeInterval = 3.0
    private let deityColor: UIColor
    init(color: UIColor) {
        self.deityColor = color
        super.init(frame: .zero)
        setupLayers()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
        startAnimation()
    }
    private func setupLayers() {
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = deityColor.withAlphaComponent(0.15).cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)
        shimmerLayer.fillColor = UIColor.clear.cgColor
        shimmerLayer.strokeColor = deityColor.cgColor
        shimmerLayer.lineWidth = 1.5
        shimmerLayer.lineCap = .round
        shimmerLayer.strokeEnd = 0.0
        layer.addSublayer(shimmerLayer)
    }
    private func updatePaths() {
        let rect = bounds
        let cornerRadius: CGFloat = 8
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        borderLayer.path = path.cgPath
        shimmerLayer.path = path.cgPath
        borderLayer.frame = rect
        shimmerLayer.frame = rect
    }
    private func startAnimation() {
        shimmerLayer.removeAllAnimations()
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values = [0.0, 0.3, 1.0, 1.0]
        strokeEndAnimation.keyTimes = [0.0, 0.3, 0.6, 1.0]
        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values = [0.0, 0.0, 0.7, 1.0]
        strokeStartAnimation.keyTimes = [0.0, 0.3, 0.6, 1.0]
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0.0, 1.0, 1.0, 0.0]
        opacityAnimation.keyTimes = [0.0, 0.2, 0.8, 1.0]
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [strokeEndAnimation, strokeStartAnimation, opacityAnimation]
        animationGroup.duration = animationDuration
        animationGroup.repeatCount = .infinity
        animationGroup.isRemovedOnCompletion = false
        shimmerLayer.add(animationGroup, forKey: "shimmerAnimation")
    }
}
