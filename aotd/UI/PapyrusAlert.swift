import UIKit

// MARK: - PapyrusAlert

final class PapyrusAlert {
    
    // MARK: - Types
    
    enum Style {
        case alert
        case actionSheet
    }
    
    enum ActionStyle {
        case `default`
        case cancel
        case destructive
    }
    
    struct Action {
        let title: String
        let style: ActionStyle
        let handler: (() -> Void)?
        
        init(title: String, style: ActionStyle = .default, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }
    
    // MARK: - Properties
    
    private let title: String?
    private let message: String?
    private let style: Style
    private var actions: [Action] = []
    private weak var sourceView: UIView?
    private var sourceRect: CGRect?
    
    // MARK: - Initialization
    
    init(title: String? = nil, message: String? = nil, style: Style = .alert) {
        self.title = title
        self.message = message
        self.style = style
    }
    
    // MARK: - Configuration
    
    @discardableResult
    func addAction(_ action: Action) -> Self {
        actions.append(action)
        return self
    }
    
    @discardableResult
    func setSourceView(_ view: UIView, rect: CGRect? = nil) -> Self {
        self.sourceView = view
        self.sourceRect = rect ?? view.bounds
        return self
    }
    
    // MARK: - Presentation
    
    func present(from viewController: UIViewController) {
        let alertViewController = PapyrusAlertViewController(
            title: title,
            message: message,
            style: style,
            actions: actions
        )
        
        if style == .actionSheet, let sourceView = sourceView {
            alertViewController.setSourceView(sourceView, rect: sourceRect ?? sourceView.bounds)
        }
        
        alertViewController.modalPresentationStyle = .overCurrentContext
        alertViewController.modalTransitionStyle = .crossDissolve
        viewController.present(alertViewController, animated: true)
    }
    
    // MARK: - Convenience Methods
    
    static func showSimpleAlert(
        title: String? = nil,
        message: String? = nil,
        buttonTitle: String = "OK",
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        PapyrusAlert(title: title, message: message)
            .addAction(Action(title: buttonTitle, handler: completion))
            .present(from: viewController)
    }
    
    static func showConfirmationAlert(
        title: String? = nil,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        confirmStyle: ActionStyle = .default,
        from viewController: UIViewController,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        PapyrusAlert(title: title, message: message)
            .addAction(Action(title: cancelTitle, style: .cancel, handler: onCancel))
            .addAction(Action(title: confirmTitle, style: confirmStyle, handler: onConfirm))
            .present(from: viewController)
    }
}

// MARK: - PapyrusAlertViewController

private final class PapyrusAlertViewController: UIViewController {
    
    // MARK: - Properties
    
    private let alertTitle: String?
    private let message: String?
    private let style: PapyrusAlert.Style
    private let actions: [PapyrusAlert.Action]
    
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let contentStackView = UIStackView()
    private let buttonStackView = UIStackView()
    
    private var sourceView: UIView?
    private var sourceRect: CGRect?
    
    // MARK: - Initialization
    
    init(title: String?, message: String?, style: PapyrusAlert.Style, actions: [PapyrusAlert.Action]) {
        self.alertTitle = title
        self.message = message
        self.style = style
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    
    func setSourceView(_ view: UIView, rect: CGRect) {
        self.sourceView = view
        self.sourceRect = rect
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Background
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.alpha = 0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
        
        // Container
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.Papyrus.gold.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        containerView.alpha = 0
        view.addSubview(containerView)
        
        // Content stack
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)
        
        // Title
        if let title = alertTitle {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = UIColor.Papyrus.primaryText
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            contentStackView.addArrangedSubview(titleLabel)
        }
        
        // Message
        if let message = message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.font = .systemFont(ofSize: 16)
            messageLabel.textColor = UIColor.Papyrus.secondaryText
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            contentStackView.addArrangedSubview(messageLabel)
        }
        
        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor.Papyrus.aged
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStackView.addArrangedSubview(divider)
        
        // Buttons
        buttonStackView.axis = style == .alert ? .horizontal : .vertical
        buttonStackView.spacing = style == .alert ? 1 : 0
        buttonStackView.distribution = .fillEqually
        buttonStackView.backgroundColor = UIColor.Papyrus.aged
        contentStackView.addArrangedSubview(buttonStackView)
        
        // Add vertical dividers for alert style
        if style == .alert && actions.count > 1 {
            buttonStackView.spacing = 0
        }
        
        for (index, action) in actions.enumerated() {
            let button = createButton(for: action)
            
            if style == .alert && index > 0 {
                // Add vertical divider
                let verticalDivider = UIView()
                verticalDivider.backgroundColor = UIColor.Papyrus.aged
                verticalDivider.widthAnchor.constraint(equalToConstant: 1).isActive = true
                buttonStackView.addArrangedSubview(verticalDivider)
            } else if style == .actionSheet && index > 0 {
                // Add horizontal divider
                let horizontalDivider = UIView()
                horizontalDivider.backgroundColor = UIColor.Papyrus.aged
                horizontalDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                buttonStackView.addArrangedSubview(horizontalDivider)
            }
            
            buttonStackView.addArrangedSubview(button)
        }
    }
    
    private func createButton(for action: PapyrusAlert.Action) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = action.style == .cancel ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
        
        switch action.style {
        case .default:
            button.setTitleColor(UIColor.Papyrus.hieroglyphBlue, for: .normal)
        case .cancel:
            button.setTitleColor(UIColor.Papyrus.primaryText, for: .normal)
        case .destructive:
            button.setTitleColor(UIColor.Papyrus.tombRed, for: .normal)
        }
        
        button.backgroundColor = UIColor.Papyrus.cardBackground
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        button.addAction(UIAction { [weak self] _ in
            self?.handleAction(action)
        }, for: .touchUpInside)
        
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container - different positioning for alert vs action sheet
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            
            // Content
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        if style == .alert {
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        } else {
            // Action sheet positioning
            if let sourceView = sourceView {
                // Position near source view
                let sourceFrame = sourceView.convert(sourceRect ?? sourceView.bounds, to: view)
                if sourceFrame.midY < view.bounds.midY {
                    containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: sourceFrame.maxY + 8).isActive = true
                } else {
                    containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.bounds.height - sourceFrame.minY) - 8).isActive = true
                }
            } else {
                // Default to bottom
                containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTapped() {
        if style == .actionSheet {
            // Find cancel action or dismiss
            if let cancelAction = actions.first(where: { $0.style == .cancel }) {
                handleAction(cancelAction)
            } else {
                animateOut()
            }
        }
    }
    
    private func handleAction(_ action: PapyrusAlert.Action) {
        animateOut { [weak self] in
            action.handler?()
            self?.dismiss(animated: false)
        }
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.backgroundView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            completion?()
        }
    }
}