import UIKit



final class PapyrusAlert {
    
    
    
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
    
    
    
    private let title: String?
    private let message: String?
    private let style: Style
    private var actions: [Action] = []
    private weak var sourceView: UIView?
    private var sourceRect: CGRect?
    
    
    
    init(title: String? = nil, message: String? = nil, style: Style = .alert) {
        self.title = title
        self.message = message
        self.style = style
    }
    
    
    
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



private final class PapyrusAlertViewController: UIViewController {
    
    
    
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    
    
    func setSourceView(_ view: UIView, rect: CGRect) {
        self.sourceView = view
        self.sourceRect = rect
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.alpha = 0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
        
        
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
        
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)
        
        
        if let title = alertTitle {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = UIColor.Papyrus.primaryText
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            
            let titleContainer = UIView()
            titleContainer.addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -20),
                titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor)
            ])
            contentStackView.addArrangedSubview(titleContainer)
        }
        
        
        if let message = message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.font = .systemFont(ofSize: 16)
            messageLabel.textColor = UIColor.Papyrus.secondaryText
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            
            let messageContainer = UIView()
            messageContainer.addSubview(messageLabel)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor),
                messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 20),
                messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -20),
                messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor)
            ])
            contentStackView.addArrangedSubview(messageContainer)
        }
        
        
        let divider = UIView()
        divider.backgroundColor = UIColor.Papyrus.aged
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStackView.addArrangedSubview(divider)
        
        
        
        let totalButtonTextLength = actions.reduce(0) { $0 + $1.title.count }
        let longestButtonTitle = actions.map { $0.title.count }.max() ?? 0
        
        let hasConfirmationStyle = actions.contains { $0.style == .cancel } && 
                                  actions.contains { $0.style == .destructive }
        let shouldUseVerticalLayout = style == .actionSheet || 
                                     totalButtonTextLength > 15 || 
                                     longestButtonTitle > 10 ||
                                     actions.count > 2 ||
                                     hasConfirmationStyle
        
        if shouldUseVerticalLayout {
            
            buttonStackView.axis = .vertical
            buttonStackView.spacing = 0
            buttonStackView.distribution = .fill
            buttonStackView.alignment = .fill
            
            for (index, action) in actions.enumerated() {
                if index > 0 {
                    
                    let divider = UIView()
                    divider.backgroundColor = UIColor.Papyrus.aged
                    divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    buttonStackView.addArrangedSubview(divider)
                }
                
                let button = createButton(for: action, isVertical: true)
                buttonStackView.addArrangedSubview(button)
            }
        } else {
            
            buttonStackView.axis = .horizontal
            buttonStackView.spacing = 1
            buttonStackView.distribution = .fillEqually
            buttonStackView.alignment = .fill
            buttonStackView.backgroundColor = UIColor.Papyrus.aged
            
            for action in actions {
                let button = createButton(for: action, isVertical: false)
                buttonStackView.addArrangedSubview(button)
            }
        }
        
        contentStackView.addArrangedSubview(buttonStackView)
    }
    
    private func createButton(for action: PapyrusAlert.Action, isVertical: Bool) -> UIButton {
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
            
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            
            
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        if style == .alert {
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        } else {
            
            if let sourceView = sourceView {
                
                let sourceFrame = sourceView.convert(sourceRect ?? sourceView.bounds, to: view)
                if sourceFrame.midY < view.bounds.midY {
                    containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: sourceFrame.maxY + 8).isActive = true
                } else {
                    containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.bounds.height - sourceFrame.minY) - 8).isActive = true
                }
            } else {
                
                containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
            }
        }
    }
    
    
    
    @objc private func backgroundTapped() {
        if style == .actionSheet {
            
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
    
    
    
    private func animateIn() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.backgroundView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
        
        
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