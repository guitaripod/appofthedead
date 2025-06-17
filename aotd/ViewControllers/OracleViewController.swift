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
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var downloadLabel: UILabel = {
        let label = UILabel()
        label.text = "Oracle requires divine knowledge to be downloaded"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Papyrus.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Download Oracle Model", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.Papyrus.gold
        button.setTitleColor(UIColor.Papyrus.ink, for: .normal)
        button.layer.cornerRadius = 8
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "Oracle"
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
        downloadContainerView.addSubview(downloadLabel)
        downloadContainerView.addSubview(downloadButton)
        downloadContainerView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            downloadContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            downloadContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            downloadContainerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            
            downloadLabel.topAnchor.constraint(equalTo: downloadContainerView.topAnchor, constant: 24),
            downloadLabel.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            downloadLabel.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            
            downloadButton.topAnchor.constraint(equalTo: downloadLabel.bottomAnchor, constant: 16),
            downloadButton.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor, constant: 24),
            downloadButton.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor, constant: -24),
            downloadButton.heightAnchor.constraint(equalToConstant: 44),
            downloadButton.bottomAnchor.constraint(equalTo: downloadContainerView.bottomAnchor, constant: -24),
            
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
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.downloadButton.isHidden = false
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
        if MLXModelManager.shared.isModelLoaded {
            downloadContainerView.isHidden = true
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
              !text.isEmpty else { return }
        
        // Clear input
        messageTextView.text = ""
        textViewDidChange(messageTextView)
        
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
        let alert = PapyrusAlert(title: "Choose Your Oracle", message: nil, style: .actionSheet)
            .setSourceView(deitySelectionButton)
        
        for deity in viewModel.availableDeities {
            alert.addAction(PapyrusAlert.Action(title: "\(deity.name) - \(deity.tradition)") { [weak self] in
                self?.viewModel.selectDeity(deity)
            })
        }
        
        alert.addAction(PapyrusAlert.Action(title: "Cancel", style: .cancel))
        alert.present(from: self)
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
        guard let deity = viewModel.selectedDeity else { return }
        
        let iconImage = IconProvider.beliefSystemIcon(
            for: deity.avatar,
            color: deity.uiColor,
            size: 24
        )
        deitySelectionButton.setImage(iconImage, for: .normal)
        deitySelectionButton.tintColor = deity.uiColor
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
        
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.borderWidth = 1
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        
        nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
    }
    
    func configure(with message: OracleViewModel.ChatMessage) {
        messageLabel.text = message.text
        
        if message.isUser {
            // User message styling
            bubbleView.backgroundColor = UIColor.Papyrus.hieroglyphBlue
            bubbleView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            messageLabel.textColor = UIColor.Papyrus.beige
            avatarImageView.isHidden = true
            nameLabel.isHidden = true
            
            NSLayoutConstraint.deactivate(contentView.constraints)
            NSLayoutConstraint.activate([
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
                
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
            ])
        } else {
            // Deity/system message styling
            bubbleView.backgroundColor = UIColor.Papyrus.cardBackground
            bubbleView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            messageLabel.textColor = UIColor.Papyrus.primaryText
            
            if let deity = message.deity {
                avatarImageView.isHidden = false
                nameLabel.isHidden = false
                
                avatarImageView.image = IconProvider.beliefSystemIcon(
                    for: deity.avatar,
                    color: deity.uiColor,
                    size: 24
                )
                avatarImageView.tintColor = deity.uiColor
                
                nameLabel.text = deity.name
                nameLabel.textColor = deity.uiColor
            } else {
                avatarImageView.isHidden = true
                nameLabel.isHidden = true
            }
            
            NSLayoutConstraint.deactivate(contentView.constraints)
            
            var constraints = [
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: message.deity != nil ? 56 : 16),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
                
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
            ]
            
            if message.deity != nil {
                constraints.append(contentsOf: [
                    avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                    avatarImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor),
                    avatarImageView.widthAnchor.constraint(equalToConstant: 32),
                    avatarImageView.heightAnchor.constraint(equalToConstant: 32),
                    
                    nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
                    nameLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -4)
                ])
            }
            
            NSLayoutConstraint.activate(constraints)
        }
    }
}