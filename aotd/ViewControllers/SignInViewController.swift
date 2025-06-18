import UIKit
import AuthenticationServices

protocol SignInViewControllerDelegate: AnyObject {
    func signInDidComplete()
    func signInDidCancel()
}

final class SignInViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding {
    
    // MARK: - Properties
    
    weak var delegate: SignInViewControllerDelegate?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let signInWithAppleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Title
        titleLabel.text = "Sign In"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message
        messageLabel.text = "Sign in to sync your progress across devices"
        messageLabel.font = .systemFont(ofSize: 17)
        messageLabel.textColor = UIColor.Papyrus.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Button stack
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.alignment = .fill
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStackView)
        
        // Sign in with Apple button
        signInWithAppleButton.addTarget(self, action: #selector(signInWithAppleTapped), for: .touchUpInside)
        signInWithAppleButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signInWithAppleButton.cornerRadius = 12
        buttonStackView.addArrangedSubview(signInWithAppleButton)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.setTitleColor(UIColor.Papyrus.hieroglyphBlue, for: .normal)
        cancelButton.backgroundColor = UIColor.Papyrus.cardBackground
        cancelButton.layer.cornerRadius = 12
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.borderColor = UIColor.Papyrus.aged.cgColor
        cancelButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(cancelButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Button stack
            buttonStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func signInWithAppleTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        AuthenticationManager.shared.delegate = self
        AuthenticationManager.shared.signInWithApple(presentingViewController: self)
    }
    
    @objc private func cancelTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        dismiss(animated: true) { [weak self] in
            self?.delegate?.signInDidCancel()
        }
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

// MARK: - AuthenticationManagerDelegate

extension SignInViewController: AuthenticationManagerDelegate {
    func authenticationDidComplete(userId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true) { [weak self] in
                self?.delegate?.signInDidComplete()
            }
        }
    }
    
    func authenticationDidFail(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            PapyrusAlert.showSimpleAlert(
                title: "Sign In Failed",
                message: error.localizedDescription,
                from: self
            )
        }
    }
}