import UIKit
extension OracleViewController {
    func updateLayoutForIPad() {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        if AdaptiveLayoutManager.shared.isRegularWidth(traitCollection) {
            setupIPadLayout()
            updateInputAreaForIPad()
            addIPadGestures()
        }
    }
    private func setupIPadLayout() {
        let layoutManager = AdaptiveLayoutManager.shared
        let insets = layoutManager.contentInsets(for: traitCollection)
        let contentInset = UIEdgeInsets(
            top: insets.top,
            left: 0,  
            bottom: insets.bottom + 100, 
            right: 0  
        )
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
        tableView.alwaysBounceHorizontal = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.clipsToBounds = true
        if layoutManager.isRegularWidth(traitCollection) {
            setupPromptSuggestionsPanel()
        }
    }
    private func updateInputAreaForIPad() {
        let layoutManager = AdaptiveLayoutManager.shared
        for constraint in messageTextView.constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = layoutManager.isIPad ? 60 : 40
                break
            }
        }
        messageTextView.font = PapyrusDesignSystem.Typography.body(for: traitCollection)
        messageTextView.textContainerInset = UIEdgeInsets(
            top: layoutManager.isIPad ? 16 : 12,
            left: 16,
            bottom: layoutManager.isIPad ? 16 : 12,
            right: 16
        )
        if layoutManager.isIPad {
            sendButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    private func setupPromptSuggestionsPanel() {
        let suggestionsPanel = PromptSuggestionsPanel()
        suggestionsPanel.translatesAutoresizingMaskIntoConstraints = false
        suggestionsPanel.delegate = self
        view.addSubview(suggestionsPanel)
        NSLayoutConstraint.activate([
            suggestionsPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            suggestionsPanel.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -20),
            suggestionsPanel.widthAnchor.constraint(equalToConstant: 280),
            suggestionsPanel.heightAnchor.constraint(equalToConstant: 200)
        ])
        promptSuggestionsView = suggestionsPanel
    }
    private func addIPadGestures() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerTap))
        twoFingerTap.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerTap)
    }
    @objc private func handleSwipeDown() {
        messageTextView.resignFirstResponder()
    }
    @objc private func handleTwoFingerTap() {
        UIView.animate(withDuration: 0.3) {
            self.promptSuggestionsView.alpha = self.promptSuggestionsView.alpha == 0 ? 1.0 : 0
        }
    }
}
protocol PromptSuggestionsPanelDelegate: AnyObject {
    func didSelectPrompt(_ prompt: String)
}
final class PromptSuggestionsPanel: UIView {
    weak var delegate: PromptSuggestionsPanelDelegate?
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private let suggestions = [
        "What happens after death?",
        "Tell me about the afterlife journey",
        "What is the meaning of life?",
        "How do I prepare for death?",
        "What are the different realms?",
        "Tell me about reincarnation"
    ]
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        layer.borderWidth = 1
        layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        let shadow = PapyrusDesignSystem.Shadow.elevated()
        layer.shadowColor = shadow.color
        layer.shadowOpacity = shadow.opacity
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.radius
        titleLabel.text = "Suggested Questions"
        titleLabel.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for suggestion in suggestions.prefix(4) {
            let button = createSuggestionButton(text: suggestion)
            stackView.addArrangedSubview(button)
        }
        addSubview(titleLabel)
        addSubview(stackView)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    private func createSuggestionButton(text: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = text
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = PapyrusDesignSystem.Typography.footnote(for: self.traitCollection)
            return outgoing
        }
        config.baseBackgroundColor = PapyrusDesignSystem.Colors.Dynamic.background
        config.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        return button
    }
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let title = sender.configuration?.title else { return }
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        delegate?.didSelectPrompt(title)
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        }
    }
}
final class OracleMessageCellIPad: UITableViewCell {
    private let messageContainerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let messageTextView = UITextView()
    private let timestampLabel = UILabel()
    private let layoutManager = AdaptiveLayoutManager.shared
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        messageContainerView.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        messageContainerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        messageContainerView.layer.borderWidth = 1
        messageContainerView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.background
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
        nameLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.font = PapyrusDesignSystem.Typography.body(for: traitCollection)
        messageTextView.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        messageTextView.backgroundColor = .clear
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.textContainerInset = .zero
        messageTextView.textContainer.lineFragmentPadding = 0
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        timestampLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        contentView.addSubview(messageContainerView)
        messageContainerView.addSubview(avatarImageView)
        messageContainerView.addSubview(nameLabel)
        messageContainerView.addSubview(messageTextView)
        messageContainerView.addSubview(timestampLabel)
        let spacing = layoutManager.spacing(for: .medium, traitCollection: traitCollection)
        NSLayoutConstraint.activate([
            messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing/2),
            messageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            messageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            messageContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing/2),
            avatarImageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: spacing),
            avatarImageView.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: spacing),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: spacing),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -spacing),
            messageTextView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: spacing),
            messageTextView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            messageTextView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -spacing),
            messageTextView.bottomAnchor.constraint(equalTo: timestampLabel.topAnchor, constant: -8),
            timestampLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: spacing),
            timestampLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -spacing)
        ])
        if layoutManager.isIPad {
            let shadow = PapyrusDesignSystem.Shadow.papyrus()
            messageContainerView.layer.shadowColor = shadow.color
            messageContainerView.layer.shadowOpacity = shadow.opacity
            messageContainerView.layer.shadowOffset = shadow.offset
            messageContainerView.layer.shadowRadius = shadow.radius
        }
    }
    func configure(with message: OracleViewModel.ChatMessage) {
        if message.isUser {
            nameLabel.text = "You"
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
            messageContainerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.background
        } else {
            nameLabel.text = "Oracle"
            avatarImageView.image = UIImage(systemName: "sparkles")
            avatarImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
            messageContainerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        }
        messageTextView.text = message.text
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timestampLabel.text = formatter.string(from: Date())
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            messageContainerView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        }
        nameLabel.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
        messageTextView.font = PapyrusDesignSystem.Typography.body(for: traitCollection)
        timestampLabel.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
    }
}
extension OracleViewController: PromptSuggestionsPanelDelegate {
    func didSelectPrompt(_ prompt: String) {
        messageTextView.text = prompt
        if let oracleVC = self as? OracleViewController {
            oracleVC.sendMessage()
        }
    }
}