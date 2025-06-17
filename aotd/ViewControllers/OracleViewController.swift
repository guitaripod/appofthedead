import UIKit

final class OracleViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let messageTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let deitySelectionButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private var messages: [ChatMessage] = []
    private var selectedDeity: Deity?
    private var inputContainerBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Types
    
    struct ChatMessage {
        let text: String
        let isUser: Bool
        let deity: Deity?
        let timestamp: Date
    }
    
    struct Deity {
        let id: String
        let name: String
        let tradition: String
        let role: String
        let avatar: String // SF Symbol name
        let color: UIColor
    }
    
    // Available deities for conversation
    private let availableDeities: [Deity] = [
        Deity(id: "anubis", name: "Anubis", tradition: "Egyptian", role: "Guide of Souls", 
              avatar: "figure.stand", color: UIColor.Papyrus.gold),
        Deity(id: "hermes", name: "Hermes", tradition: "Greek", role: "Messenger of Gods", 
              avatar: "wind", color: UIColor.Papyrus.hieroglyphBlue),
        Deity(id: "gabriel", name: "Gabriel", tradition: "Abrahamic", role: "Archangel", 
              avatar: "sparkles", color: UIColor.Papyrus.mysticPurple),
        Deity(id: "yama", name: "Yama", tradition: "Hindu/Buddhist", role: "Lord of Death", 
              avatar: "flame", color: UIColor.Papyrus.tombRed),
        Deity(id: "mictlantecuhtli", name: "Mictlantecuhtli", tradition: "Aztec", role: "Lord of Mictlan", 
              avatar: "moon.stars", color: UIColor.Papyrus.burnishedGold)
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        addWelcomeMessage()
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
        
        // Set default deity
        selectedDeity = availableDeities.first
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
        
        // Add user message
        let userMessage = ChatMessage(text: text, isUser: true, deity: nil, timestamp: Date())
        messages.append(userMessage)
        
        // Clear input
        messageTextView.text = ""
        textViewDidChange(messageTextView)
        
        // Reload table
        tableView.reloadData()
        scrollToBottom()
        
        // Simulate deity response (will be replaced with MLX integration)
        simulateDeityResponse(to: text)
    }
    
    @objc private func selectDeity() {
        let actionSheet = UIAlertController(title: "Choose Your Oracle", message: nil, preferredStyle: .actionSheet)
        
        for deity in availableDeities {
            let action = UIAlertAction(title: "\(deity.name) - \(deity.tradition)", style: .default) { [weak self] _ in
                self?.selectedDeity = deity
                self?.updateDeityButton()
                self?.addDeityGreeting(deity)
            }
            actionSheet.addAction(action)
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = deitySelectionButton
            popover.sourceRect = deitySelectionButton.bounds
        }
        
        present(actionSheet, animated: true)
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
        guard let deity = selectedDeity else { return }
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        deitySelectionButton.setImage(UIImage(systemName: deity.avatar, withConfiguration: config), for: .normal)
        deitySelectionButton.tintColor = deity.color
    }
    
    private func addWelcomeMessage() {
        let welcomeText = "Welcome to the Oracle! Here you can converse with divine beings from various traditions. Select a deity to begin your dialogue."
        let welcomeMessage = ChatMessage(text: welcomeText, isUser: false, deity: nil, timestamp: Date())
        messages.append(welcomeMessage)
        tableView.reloadData()
    }
    
    private func addDeityGreeting(_ deity: Deity) {
        let greetings: [String: String] = [
            "anubis": "I am Anubis, Guardian of the Scales. I have witnessed countless souls on their journey through the afterlife. What wisdom do you seek?",
            "hermes": "Greetings, mortal! I am Hermes, swift messenger between realms. I traverse both the world of the living and the dead. How may I guide you?",
            "gabriel": "Peace be upon you. I am Gabriel, herald of divine messages. I bring tidings from the celestial realm. What questions weigh upon your heart?",
            "yama": "I am Yama, the first to die and thus the guide for all who follow. I maintain the cosmic order between life and death. Speak, and I shall answer.",
            "mictlantecuhtli": "I am Mictlantecuhtli, Lord of the Bone Palace. In Mictlan, all souls find their rest. What do you wish to know about the journey ahead?"
        ]
        
        if let greeting = greetings[deity.id] {
            let message = ChatMessage(text: greeting, isUser: false, deity: deity, timestamp: Date())
            messages.append(message)
            tableView.reloadData()
            scrollToBottom()
        }
    }
    
    private func simulateDeityResponse(to userMessage: String) {
        guard let deity = selectedDeity else { return }
        
        // Show typing indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            // Placeholder response - will be replaced with MLX integration
            let response = "This is where the MLX-powered response from \(deity.name) would appear. The AI would respond in character, drawing from the knowledge of \(deity.tradition) traditions about the afterlife."
            
            let message = ChatMessage(text: response, isUser: false, deity: deity, timestamp: Date())
            self?.messages.append(message)
            self?.tableView.reloadData()
            self?.scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource

extension OracleViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        let message = messages[indexPath.row]
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
    
    func configure(with message: OracleViewController.ChatMessage) {
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
            messageLabel.textColor = UIColor.Papyrus.ink
            
            if let deity = message.deity {
                avatarImageView.isHidden = false
                nameLabel.isHidden = false
                
                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                avatarImageView.image = UIImage(systemName: deity.avatar, withConfiguration: config)
                avatarImageView.tintColor = deity.color
                
                nameLabel.text = deity.name
                nameLabel.textColor = deity.color
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