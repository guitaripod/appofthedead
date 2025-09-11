import UIKit
import Combine

final class OracleViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let messageTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let deitySelectionButton = UIButton(type: .system)
    private let promptSuggestionsView = UIView()
    
    // MARK: - Properties
    
    private let viewModel = OracleViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var inputContainerBottomConstraint: NSLayoutConstraint?
    private var typingIndicator: UIActivityIndicatorView?
    
    // MARK: - Model Download UI
    
    private lazy var downloadContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.Papyrus.cardBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.Papyrus.aged.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var downloadLabel: UILabel = {
        let label = UILabel()
        label.text = "Oracle requires divine knowledge to be downloaded"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor.Papyrus.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var oracleIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "sparkles.rectangle.stack.fill")
        imageView.tintColor = UIColor.Papyrus.gold
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var downloadDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Download the Qwen3 model (1.7B parameters, ~1GB) to enable on-device AI conversations with ancient deities."
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.Papyrus.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = UIColor.Papyrus.gold
        progress.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.Papyrus.secondaryText
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.Papyrus.secondaryText.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.filled()
        config.title = "Download Oracle Model"
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = .systemFont(ofSize: 16, weight: .semibold)
            return updated
        }
        config.image = UIImage(systemName: "arrow.down.circle.fill")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseBackgroundColor = UIColor.Papyrus.gold
        config.baseForegroundColor = UIColor.Papyrus.ink
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        button.configuration = config
        button.addTarget(self, action: #selector(downloadModel), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor.Papyrus.gold
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupBindings()
        checkModelStatus()
        
        // Listen for memory warnings
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
        title = "Oracle"
        
        // Re-check model status when view appears
        checkModelStatus()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update shadow colors for dark mode
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            inputContainerView.layer.shadowColor = traitCollection.userInterfaceStyle == .dark ?
                UIColor.white.cgColor : UIColor.black.cgColor
            inputContainerView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.05 : 0.1
            
            // Update text view border color
            messageTextView.layer.borderColor = UIColor.Papyrus.separator.cgColor
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        setupTableView()
        setupInputContainer()
        setupPromptSuggestions()
        setupConstraints()
        
        setupDownloadUI()
        updateDeityButton()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.Papyrus.background
        tableView.keyboardDismissMode = .interactive
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Allow touches to pass through to table view cells
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
        
        // Deity selection button
        deitySelectionButton.tintColor = UIColor.Papyrus.gold
        deitySelectionButton.addTarget(self, action: #selector(selectDeity), for: .touchUpInside)
        deitySelectionButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(deitySelectionButton)
        
        // Message text view
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
        messageTextView.keyboardAppearance = .dark // Better for dark mode
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(messageTextView)
        
        // Send button
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
        
        // Add tap gesture to promptSuggestionsView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        promptSuggestionsView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint!,
            
            // Deity button
            deitySelectionButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            deitySelectionButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            deitySelectionButton.widthAnchor.constraint(equalToConstant: 36),
            deitySelectionButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Message text view
            messageTextView.leadingAnchor.constraint(equalTo: deitySelectionButton.trailingAnchor, constant: 8),
            messageTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 12),
            messageTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            messageTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            messageTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Prompt suggestions view
            promptSuggestionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            promptSuggestionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            promptSuggestionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            promptSuggestionsView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])
    }
    
    private func setupDownloadUI() {
        // Add download container later to ensure it's above prompt suggestions
        view.insertSubview(downloadContainerView, belowSubview: promptSuggestionsView)
        downloadContainerView.addSubview(oracleIcon)
        downloadContainerView.addSubview(downloadLabel)
        downloadContainerView.addSubview(downloadDescriptionLabel)
        downloadContainerView.addSubview(downloadButton)
        downloadContainerView.addSubview(progressView)
        downloadContainerView.addSubview(progressLabel)
        downloadContainerView.addSubview(stageLabel)
        downloadContainerView.addSubview(loadingIndicator)
        
        // Position download container above where the prompts will appear
        NSLayoutConstraint.activate([
            downloadContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            downloadContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            downloadContainerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            downloadContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            oracleIcon.topAnchor.constraint(equalTo: downloadContainerView.topAnchor, constant: 32),
            oracleIcon.centerXAnchor.constraint(equalTo: downloadContainerView.centerXAnchor),
            oracleIcon.widthAnchor.constraint(equalToConstant: 60),
            oracleIcon.heightAnchor.constraint(equalToConstant: 60),
            
            downloadLabel.topAnchor.constraint(equalTo: oracleIcon.bottomAnchor, constant: 16),
            downloadLabel.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            downloadLabel.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            
            downloadDescriptionLabel.topAnchor.constraint(equalTo: downloadLabel.bottomAnchor, constant: 12),
            downloadDescriptionLabel.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            downloadDescriptionLabel.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            
            progressView.topAnchor.constraint(equalTo: downloadDescriptionLabel.bottomAnchor, constant: 24),
            progressView.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            progressLabel.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            progressLabel.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            
            stageLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 4),
            stageLabel.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            stageLabel.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            
            downloadButton.topAnchor.constraint(equalTo: stageLabel.bottomAnchor, constant: 20),
            downloadButton.centerXAnchor.constraint(equalTo: downloadContainerView.centerXAnchor),
            downloadButton.bottomAnchor.constraint(equalTo: downloadContainerView.bottomAnchor, constant: -32),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: downloadButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: downloadButton.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Bind messages
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.scrollToBottom()
                self?.updatePromptSuggestions()
            }
            .store(in: &cancellables)
        
        // Bind selected deity
        viewModel.$selectedDeity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDeityButton()
            }
            .store(in: &cancellables)
        
        // Bind model loading state
        viewModel.$isModelLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.downloadButton.isHidden = true
                    self?.progressView.isHidden = false
                    self?.progressLabel.isHidden = false
                    self?.stageLabel.isHidden = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.downloadButton.isHidden = false
                    self?.progressView.isHidden = true
                    self?.progressLabel.isHidden = true
                    self?.stageLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        // Bind download progress
        viewModel.$downloadProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.setProgress(progress, animated: true)
            }
            .store(in: &cancellables)
        
        // Bind download status
        viewModel.$downloadStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.progressLabel.text = status
                
                // Update UI based on status
                if status.contains("Loading Oracle model") {
                    // Auto-loading state
                    self?.downloadLabel.text = "Loading Oracle..."
                    self?.downloadDescriptionLabel.text = "Please wait while we restore the divine connection."
                    self?.downloadButton.isHidden = true
                    self?.progressView.isHidden = true
                } else if status.isEmpty {
                    // Reset to default state
                    self?.downloadLabel.text = "Oracle requires divine knowledge to be downloaded"
                    self?.downloadDescriptionLabel.text = "Download the Llama 3.2 model (~1.8GB) to enable on-device AI conversations with ancient deities."
                }
            }
            .store(in: &cancellables)
        
        // Bind download stage
        viewModel.$downloadStage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stage in
                self?.stageLabel.text = stage
            }
            .store(in: &cancellables)
        
        // Bind model loaded state
        viewModel.$isModelLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoaded in
                self?.downloadContainerView.isHidden = isLoaded
                self?.inputContainerView.isHidden = !isLoaded
                self?.tableView.isHidden = !isLoaded
                // Update prompt suggestions visibility
                self?.updatePromptSuggestions()
            }
            .store(in: &cancellables)
        
        // Bind generating state
        viewModel.$isGenerating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGenerating in
                self?.sendButton.isEnabled = !isGenerating
                self?.messageTextView.isEditable = !isGenerating
            }
            .store(in: &cancellables)
        
        // Bind errors
        viewModel.$modelError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                let alert = PapyrusAlert(
                    title: "Oracle Error",
                    message: error,
                    style: .alert
                )
                alert.addAction(PapyrusAlert.Action(title: "OK", style: .default))
                alert.present(from: self!)
            }
            .store(in: &cancellables)
    }
    
    private func checkModelStatus() {
        Task {
            // If model is already loaded in MLXModelManager but not in ViewModel, sync the state
            if MLXModelManager.shared.isModelLoaded && !viewModel.isModelLoaded {
                await MainActor.run {
                    viewModel.syncModelLoadedState()
                }
            }
        }
        
        // Update UI for simulator mode
        if DeviceUtility.isSimulator {
            downloadLabel.text = "Oracle Simulator Mode"
            downloadDescriptionLabel.text = "You're running in the iOS Simulator. The Oracle will provide mock responses for testing the UI. Deploy to a physical device to experience real AI-powered conversations."
            downloadButton.configuration?.title = "Enable Simulator Oracle"
            oracleIcon.image = UIImage(systemName: "desktopcomputer")
        }
        
        // Trust the view model's state which is properly synchronized
        if viewModel.isModelLoaded {
            downloadContainerView.isHidden = true
            inputContainerView.isHidden = false
            tableView.isHidden = false
        } else {
            downloadContainerView.isHidden = false
            inputContainerView.isHidden = true
            tableView.isHidden = true
        }
        
        // Update prompt suggestions
        updatePromptSuggestions()
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func sendMessage() {
        guard let text = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        
        // Check oracle consultation limits
        guard let user = DatabaseManager.shared.fetchUser(),
              let deity = viewModel.selectedDeity else {
            return
        }
        
        if !user.canConsultOracle(deityId: deity.id) {
            // Show paywall
            let paywall = PaywallViewController(reason: .oracleLimit(deityId: deity.id, deityName: deity.name))
            present(paywall, animated: true)
            return
        }
        
        // Clear input
        messageTextView.text = ""
        textViewDidChange(messageTextView)
        
        // Record consultation
        user.recordOracleConsultation(deityId: deity.id)
        
        // Send message through view model
        Task {
            await viewModel.sendMessage(text)
        }
    }
    
    @objc private func downloadModel() {
        Task {
            await viewModel.loadModel()
        }
    }
    
    @objc private func selectDeity() {
        // Ensure we have deities before presenting
        guard !viewModel.availableDeities.isEmpty else {
            return
        }
        
        // Create a new array to ensure proper memory management
        let deitiesArray = viewModel.availableDeities.map { deity in
            // Create a fresh copy of each deity
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
        
        // Find the current deity copy in our new array
        let currentDeityCopy = deitiesArray.first { $0.id == viewModel.selectedDeity?.id }
        
        // Create the view controller with the enhanced UI
        let deitySelector = DeitySelectionViewController(
            deities: deitiesArray,
            currentDeity: currentDeityCopy
        ) { [weak self] selectedDeity in
            guard let self = self else { return }
            
            // Find the original deity in the view model's array
            if let originalDeity = self.viewModel.availableDeities.first(where: { $0.id == selectedDeity.id }) {
                // Animate deity change
                self.animateDeityTransition {
                    self.viewModel.selectDeity(originalDeity)
                }
            }
        }
        
        // Present as normal modal
        if self.presentedViewController == nil {
            self.present(deitySelector, animated: true)
        }
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        inputContainerBottomConstraint?.constant = -keyboardFrame.height + view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        
        scrollToBottom()
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        inputContainerBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func handleMemoryWarning() {
        // Clear image caches if any
        URLCache.shared.removeAllCachedResponses()
        
        // Clear any cached table view cells
        tableView.reloadData()
        
        // Check memory status
        let memoryStatus = MLXModelManager.shared.checkMemoryStatus()
        let availableMB = memoryStatus.availableMemory / 1024 / 1024
        
        // If we're not actively generating, handle memory pressure
        if !viewModel.isGenerating && viewModel.isModelLoaded {
            MLXModelManager.shared.handleMemoryPressure()
            
            // Only unload model if critically low on memory (less than 500MB available)
            if availableMB < 500 {
                // Still don't unload automatically - let iOS handle it
                // The model will be reloaded next time if needed
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helpers
    
    private func updateDeityButton() {
        guard let deity = viewModel.selectedDeity else {
            return
        }
        
        // Use SF Symbol directly since deity.avatar contains SF Symbol names
        if let iconImage = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            deitySelectionButton.setImage(iconImage.withConfiguration(config), for: .normal)
            deitySelectionButton.tintColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
        } else {
            // Fallback icon
            deitySelectionButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
            deitySelectionButton.tintColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
        }
        
        // Update prompt suggestions
        updatePromptSuggestions()
    }
    
    private func updatePromptSuggestions() {
        // Remove existing subviews
        promptSuggestionsView.subviews.forEach { $0.removeFromSuperview() }
        
        // Check if we should show prompts
        let hasRealMessages = viewModel.messages.filter { !$0.text.isEmpty && $0.isUser }.count > 0
        let shouldShowPrompts = !hasRealMessages && viewModel.selectedDeity != nil && viewModel.isModelLoaded
        
        // Only show prompt suggestions when model is loaded and no messages yet
        promptSuggestionsView.isHidden = !shouldShowPrompts
        
        // Hide table view when showing prompts
        if viewModel.isModelLoaded {
            tableView.isHidden = shouldShowPrompts
        }
        
        guard shouldShowPrompts, let deity = viewModel.selectedDeity else { return }
        
        // Create container with styling
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        promptSuggestionsView.addSubview(containerView)
        
        // Compact deity header
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        
        // Small deity icon
        let iconSize: CGFloat = 32
        let iconContainerView = UIView()
        iconContainerView.backgroundColor = UIColor(hex: deity.color)?.withAlphaComponent(0.15) ?? UIColor.Papyrus.gold.withAlphaComponent(0.15)
        iconContainerView.layer.cornerRadius = iconSize / 2
        iconContainerView.layer.borderWidth = 1
        iconContainerView.layer.borderColor = (UIColor(hex: deity.color) ?? UIColor.Papyrus.gold).withAlphaComponent(0.3).cgColor
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(iconContainerView)
        
        let iconImageView = UIImageView()
        if let iconImage = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            iconImageView.image = iconImage.withConfiguration(config)
        }
        iconImageView.tintColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.addSubview(iconImageView)
        
        // Deity name - smaller and inline
        let nameLabel = UILabel()
        nameLabel.text = deity.name
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = UIColor.Papyrus.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        
        // Prompt grid container
        let gridContainer = UIView()
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gridContainer)
        
        // Create 2x2 grid for prompts
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
                
                // Calculate position
                let isLeftColumn = col == 0
                let isTopRow = row == 0
                let isBottomRow = row == 1
                
                var constraints: [NSLayoutConstraint] = [
                    button.heightAnchor.constraint(equalToConstant: buttonHeight)
                ]
                
                // Horizontal constraints
                if isLeftColumn {
                    constraints.append(button.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor))
                    constraints.append(button.trailingAnchor.constraint(equalTo: gridContainer.centerXAnchor, constant: -spacing/2))
                } else {
                    constraints.append(button.leadingAnchor.constraint(equalTo: gridContainer.centerXAnchor, constant: spacing/2))
                    constraints.append(button.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor))
                }
                
                // Vertical constraints
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
        
        // Center the prompts vertically
        let centerYOffset: CGFloat = 0
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: promptSuggestionsView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: promptSuggestionsView.trailingAnchor, constant: -16),
            containerView.centerYAnchor.constraint(equalTo: promptSuggestionsView.centerYAnchor, constant: centerYOffset),
            
            // Header
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            headerView.heightAnchor.constraint(equalToConstant: iconSize),
            
            // Icon
            iconContainerView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconContainerView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: iconSize),
            iconContainerView.heightAnchor.constraint(equalToConstant: iconSize),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            
            // Name
            nameLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            // Grid
            gridContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            gridContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gridContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gridContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            gridContainer.heightAnchor.constraint(equalToConstant: 104) // 2 rows of 48pt + 8pt spacing
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
        config.baseBackgroundColor = UIColor(hex: color)?.withAlphaComponent(0.15)
        config.baseForegroundColor = UIColor(hex: color) ?? UIColor.Papyrus.primaryText
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(
            top: isCompact ? 12 : 16,
            leading: isCompact ? 16 : 20,
            bottom: isCompact ? 12 : 16,
            trailing: isCompact ? 16 : 20
        )
        
        button.configuration = config
        button.layer.borderWidth = 1
        button.layer.borderColor = (UIColor(hex: color) ?? UIColor.Papyrus.aged).cgColor
        button.layer.cornerRadius = isCompact ? 10 : 12
        
        button.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func createCompactPromptButton(with text: String, color: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.backgroundColor = UIColor(hex: color)?.withAlphaComponent(0.08)
        button.layer.cornerRadius = 8
        
        // Create a custom view for the shimmer effect
        let shimmerView = ShimmerBorderView(color: UIColor(hex: color) ?? UIColor.Papyrus.gold)
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        shimmerView.isUserInteractionEnabled = false
        button.addSubview(shimmerView)
        
        // Set button title with multi-line support
        button.setTitle(text, for: .normal)
        button.setTitleColor(UIColor(hex: color)?.withAlphaComponent(0.8) ?? UIColor.Papyrus.primaryText.withAlphaComponent(0.8), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.9
        
        // Add shimmer view constraints
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
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Set the prompt in the text view
        messageTextView.text = prompt
        textViewDidChange(messageTextView)
        
        // Send the message
        sendMessage()
    }
    
    
    private func scrollToBottom() {
        guard viewModel.messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: viewModel.messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    private func animateDeityTransition(completion: @escaping () -> Void) {
        // Create a smooth transition effect
        let transitionView = UIView(frame: view.bounds)
        transitionView.backgroundColor = UIColor.Papyrus.background
        transitionView.alpha = 0
        view.addSubview(transitionView)
        
        // If we have a selected deity, add a deity-themed transition
        if let deity = viewModel.selectedDeity {
            let deityColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
            
            // Create a circular reveal effect from the deity button
            let circleView = UIView()
            circleView.backgroundColor = deityColor.withAlphaComponent(0.3)
            circleView.layer.cornerRadius = 30
            circleView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            // Convert deity button center to view coordinates
            let buttonCenter = view.convert(deitySelectionButton.center, from: deitySelectionButton.superview)
            circleView.center = buttonCenter
            transitionView.addSubview(circleView)
            
            // Animate the circle expanding
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
                circleView.transform = CGAffineTransform(scaleX: 20, y: 20)
                circleView.alpha = 0.1
            })
        }
        
        // Fade out current content
        UIView.animate(withDuration: 0.2, animations: {
            transitionView.alpha = 1.0
            self.tableView.alpha = 0.3
            self.promptSuggestionsView.alpha = 0.3
        }) { _ in
            // Execute the completion (deity change)
            completion()
            
            // Fade in new content
            UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseInOut], animations: {
                transitionView.alpha = 0
                self.tableView.alpha = 1.0
                self.promptSuggestionsView.alpha = 1.0
            }) { _ in
                transitionView.removeFromSuperview()
                
                // Add a subtle bounce to the deity button
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

// MARK: - UITableViewDataSource

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

// MARK: - UITableViewDelegate

extension OracleViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITextViewDelegate

extension OracleViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        // Update send button state
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isEnabled = hasText
        sendButton.alpha = hasText ? 1.0 : 0.5
        
        // Adjust text view height
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        textView.isScrollEnabled = size.height > 120
    }
}

// MARK: - ChatMessageCell

private class ChatMessageCell: UITableViewCell {
    
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()
    private let typingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Constraints that will change based on message type
    private var bubbleTopConstraint: NSLayoutConstraint?
    private var bubbleLeadingConstraint: NSLayoutConstraint?
    private var bubbleTrailingConstraint: NSLayoutConstraint?
    private var bubbleBottomConstraint: NSLayoutConstraint?
    
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
        
        // Add all subviews
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(typingIndicator)
        
        // Setup views
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        typingIndicator.translatesAutoresizingMaskIntoConstraints = false
        typingIndicator.hidesWhenStopped = true
        typingIndicator.color = UIColor.Papyrus.aged
        
        // Setup initial constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Create flexible constraints
        bubbleTopConstraint = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        bubbleBottomConstraint = bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        
        // Message label constraints (fixed)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            // Name label constraints (will be shown/hidden)
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Width constraints - Make bubbles wider for better readability (85% of screen width)
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width * 0.85),
            
            // Typing indicator constraints
            typingIndicator.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            typingIndicator.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])
        
        // Activate initial bubble constraints with lower priority
        bubbleTopConstraint?.priority = UILayoutPriority(999)
        bubbleBottomConstraint?.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            bubbleTopConstraint!,
            bubbleBottomConstraint!
        ])
    }
    
    func configure(with message: OracleViewModel.ChatMessage) {
        // Handle typing indicator for deity messages
        if !message.isUser && message.text.isEmpty {
            // Show typing indicator for empty deity messages
            messageLabel.text = " "  // Add space to maintain minimum bubble size
            messageLabel.isHidden = true
            typingIndicator.startAnimating()
            
            // Set minimum size for typing bubble
            NSLayoutConstraint.activate([
                bubbleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
                bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
            ])
        } else {
            messageLabel.text = message.text
            messageLabel.isHidden = false
            typingIndicator.stopAnimating()
        }
        
        // Deactivate existing dynamic constraints
        bubbleLeadingConstraint?.isActive = false
        bubbleTrailingConstraint?.isActive = false
        
        if message.isUser {
            // User message styling
            bubbleView.backgroundColor = UIColor.Papyrus.hieroglyphBlue
            bubbleView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            messageLabel.textColor = UIColor.Papyrus.beige
            nameLabel.isHidden = true
            
            // Update constraints for right-aligned user message
            bubbleTopConstraint?.constant = 8
            bubbleBottomConstraint?.constant = -8
            
            // Right-aligned bubble
            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
            
            bubbleTrailingConstraint?.isActive = true
            bubbleLeadingConstraint?.isActive = true
        } else {
            // Deity/system message styling
            bubbleView.backgroundColor = UIColor.Papyrus.cardBackground
            bubbleView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            messageLabel.textColor = UIColor.Papyrus.primaryText
            
            if let deity = message.deity {
                nameLabel.isHidden = false
                nameLabel.text = deity.name
                nameLabel.textColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
                
                // Update constraints for deity message with name label
                bubbleTopConstraint?.constant = 28
                bubbleBottomConstraint?.constant = -8
                
                // Position name label above bubble
                NSLayoutConstraint.activate([
                    nameLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -4)
                ])
            } else {
                nameLabel.isHidden = true
                
                // Update constraints for system message without name
                bubbleTopConstraint?.constant = 8
                bubbleBottomConstraint?.constant = -8
            }
            
            // Left-aligned bubble that takes more horizontal space
            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60)
            
            bubbleLeadingConstraint?.isActive = true
            bubbleTrailingConstraint?.isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean up constraints that might have been added dynamically
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            (constraint.firstItem === nameLabel || constraint.secondItem === nameLabel) &&
            constraint.firstAttribute == .bottom
        })
        NSLayoutConstraint.deactivate(bubbleView.constraints.filter { constraint in
            (constraint.firstAttribute == .height || constraint.firstAttribute == .width) &&
            (constraint.firstItem === bubbleView || constraint.secondItem === bubbleView)
        })
        
        typingIndicator.stopAnimating()
        messageLabel.isHidden = false
    }
}

// MARK: - ShimmerBorderView

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
        // Static border layer
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = deityColor.withAlphaComponent(0.15).cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)
        
        // Shimmer layer that will animate
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
        
        // Update both layers with the same path
        borderLayer.path = path.cgPath
        shimmerLayer.path = path.cgPath
        
        borderLayer.frame = rect
        shimmerLayer.frame = rect
    }
    
    private func startAnimation() {
        // Remove existing animations
        shimmerLayer.removeAllAnimations()
        
        // Create the shimmer effect by animating strokeStart and strokeEnd
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