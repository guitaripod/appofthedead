import UIKit
import Combine

final class OracleViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let messageTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let deitySelectionButton = UIButton(type: .system)
    
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
        print("[OracleViewController] viewDidLoad started")
        setupUI()
        setupKeyboardObservers()
        setupBindings()
        checkModelStatus()
        print("[OracleViewController] viewDidLoad completed")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "Oracle"
        
        // Re-check model status when view appears
        checkModelStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        setupTableView()
        setupInputContainer()
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
    }
    
    private func setupInputContainer() {
        inputContainerView.backgroundColor = UIColor.Papyrus.cardBackground
        inputContainerView.layer.borderWidth = 1
        inputContainerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        inputContainerView.layer.shadowColor = UIColor.black.cgColor
        inputContainerView.layer.shadowOpacity = 0.1
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
        messageTextView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        messageTextView.backgroundColor = UIColor.Papyrus.beige
        messageTextView.layer.borderWidth = 1
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        messageTextView.isScrollEnabled = false
        messageTextView.delegate = self
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(messageTextView)
        
        // Send button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = UIColor.Papyrus.gold
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(sendButton)
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
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupDownloadUI() {
        view.addSubview(downloadContainerView)
        downloadContainerView.addSubview(oracleIcon)
        downloadContainerView.addSubview(downloadLabel)
        downloadContainerView.addSubview(downloadDescriptionLabel)
        downloadContainerView.addSubview(downloadButton)
        downloadContainerView.addSubview(progressView)
        downloadContainerView.addSubview(progressLabel)
        downloadContainerView.addSubview(loadingIndicator)
        
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
            
            downloadButton.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
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
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.downloadButton.isHidden = false
                    self?.progressView.isHidden = true
                    self?.progressLabel.isHidden = true
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
                    self?.downloadDescriptionLabel.text = "Download the Qwen3 model (1.7B parameters, ~1GB) to enable on-device AI conversations with ancient deities."
                }
            }
            .store(in: &cancellables)
        
        // Bind model loaded state
        viewModel.$isModelLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoaded in
                self?.downloadContainerView.isHidden = isLoaded
                self?.inputContainerView.isHidden = !isLoaded
                self?.tableView.isHidden = !isLoaded
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
        print("[OracleViewController] Checking model status")
        print("[OracleViewController] ViewModel isModelLoaded: \(viewModel.isModelLoaded)")
        print("[OracleViewController] MLXModelManager isModelLoaded: \(MLXModelManager.shared.isModelLoaded)")
        
        Task {
            let isDownloaded = await MLXModelManager.shared.isModelDownloaded
            print("[OracleViewController] MLXModelManager isModelDownloaded: \(isDownloaded)")
            
            // If model is already loaded in MLXModelManager but not in ViewModel, sync the state
            if MLXModelManager.shared.isModelLoaded && !viewModel.isModelLoaded {
                print("[OracleViewController] Syncing model loaded state from MLXModelManager")
                await MainActor.run {
                    viewModel.syncModelLoadedState()
                }
            }
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
            print("[OracleViewController] Send message attempted with empty text")
            return
        }
        
        print("[OracleViewController] Sending message: \(text)")
        print("[OracleViewController] Selected deity: \(viewModel.selectedDeity?.name ?? "none")")
        
        // Clear input
        messageTextView.text = ""
        textViewDidChange(messageTextView)
        
        // Send message through view model
        Task {
            await viewModel.sendMessage(text)
        }
    }
    
    @objc private func downloadModel() {
        print("[OracleViewController] Download model button tapped")
        Task {
            await viewModel.loadModel()
        }
    }
    
    @objc private func selectDeity() {
        print("[OracleViewController] Select deity button tapped")
        print("[OracleViewController] Available deities: \(viewModel.availableDeities.count)")
        
        let deitySelector = DeitySelectionViewController(
            deities: viewModel.availableDeities,
            currentDeity: viewModel.selectedDeity
        ) { [weak self] selectedDeity in
            print("[OracleViewController] Selected deity: \(selectedDeity.name)")
            self?.viewModel.selectDeity(selectedDeity)
        }
        
        present(deitySelector, animated: true)
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
    
    // MARK: - Helpers
    
    private func updateDeityButton() {
        guard let deity = viewModel.selectedDeity else {
            print("[OracleViewController] updateDeityButton - no deity selected")
            return
        }
        
        print("[OracleViewController] Updating deity button for: \(deity.name)")
        
        // Use SF Symbol directly since deity.avatar contains SF Symbol names
        if let iconImage = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            deitySelectionButton.setImage(iconImage.withConfiguration(config), for: .normal)
            deitySelectionButton.tintColor = deity.uiColor
        } else {
            print("[OracleViewController] Warning: Could not load icon \(deity.avatar)")
            // Fallback icon
            deitySelectionButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
            deitySelectionButton.tintColor = deity.uiColor
        }
    }
    
    
    private func scrollToBottom() {
        guard viewModel.messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: viewModel.messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    
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
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        
        // Setup views
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            // Avatar constraints (will be shown/hidden)
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Width constraints
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
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
        messageLabel.text = message.text
        
        // Deactivate existing dynamic constraints
        bubbleLeadingConstraint?.isActive = false
        bubbleTrailingConstraint?.isActive = false
        
        if message.isUser {
            // User message styling
            bubbleView.backgroundColor = UIColor.Papyrus.hieroglyphBlue
            bubbleView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            messageLabel.textColor = UIColor.Papyrus.beige
            avatarImageView.isHidden = true
            nameLabel.isHidden = true
            
            // Update constraints for right-aligned user message
            bubbleTopConstraint?.constant = 8
            bubbleBottomConstraint?.constant = -8
            
            // Right-aligned bubble
            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 80)
            
            bubbleTrailingConstraint?.isActive = true
            bubbleLeadingConstraint?.isActive = true
        } else {
            // Deity/system message styling
            bubbleView.backgroundColor = UIColor.Papyrus.cardBackground
            bubbleView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            messageLabel.textColor = UIColor.Papyrus.primaryText
            
            if let deity = message.deity {
                avatarImageView.isHidden = false
                nameLabel.isHidden = false
                
                // Use SF Symbol directly
                if let image = UIImage(systemName: deity.avatar) {
                    let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                    avatarImageView.image = image.withConfiguration(config)
                    avatarImageView.tintColor = deity.uiColor
                } else {
                    // Fallback
                    avatarImageView.image = UIImage(systemName: "person.circle.fill")
                    avatarImageView.tintColor = deity.uiColor
                }
                
                nameLabel.text = deity.name
                nameLabel.textColor = deity.uiColor
                
                // Update constraints for deity message with avatar
                bubbleTopConstraint?.constant = 28
                bubbleBottomConstraint?.constant = -8
                
                // Position avatar
                avatarImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
                
                // Position name label
                nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
                nameLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -4).isActive = true
                
                // Left-aligned bubble with space for avatar
                bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56)
                bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80)
            } else {
                avatarImageView.isHidden = true
                nameLabel.isHidden = true
                
                // Update constraints for system message without avatar
                bubbleTopConstraint?.constant = 8
                bubbleBottomConstraint?.constant = -8
                
                // Left-aligned bubble
                bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
                bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80)
            }
            
            bubbleLeadingConstraint?.isActive = true
            bubbleTrailingConstraint?.isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean up constraints that might have been added dynamically
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            (constraint.firstItem === nameLabel || constraint.secondItem === nameLabel) &&
            (constraint.firstAttribute == .bottom || constraint.firstAttribute == .leading)
        })
        NSLayoutConstraint.deactivate(contentView.constraints.filter { constraint in
            (constraint.firstItem === avatarImageView || constraint.secondItem === avatarImageView) &&
            constraint.firstAttribute == .top
        })
    }
}