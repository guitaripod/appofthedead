import UIKit

class PapyrusModal: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Properties
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let keywordLabel = UILabel()
    private let contentTextView = UITextView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let grabberView = UIView()
    private var gradientLayer: CAGradientLayer?
    
    private let deity: Deity
    private let keyword: String
    private let mlxService: MLXService
    private var streamingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(deity: Deity, keyword: String, mlxService: MLXService) {
        self.deity = deity
        self.keyword = keyword
        self.mlxService = mlxService
        super.init(nibName: nil, bundle: nil)
        
        // Configure for sheet presentation
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = PapyrusDesignSystem.CornerRadius.xLarge
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startStreamingExplanation()
        
        // Set presentation controller delegate to detect actual dismissal
        presentationController?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't cancel here anymore - wait for actual dismissal
        #if DEBUG
        print("🔮 PapyrusModal: viewWillDisappear - modal is being dismissed")
        #endif
    }
    
    deinit {
        // Ensure task is cancelled if view controller is deallocated
        #if DEBUG
        print("🔮 PapyrusModal: deinit - ensuring task is cancelled")
        #endif
        streamingTask?.cancel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame
        gradientLayer?.frame = headerView.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateGradientColors()
            updateBorderColors()
            updateShadows()
            updateBackgroundColor()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Add blur effect for modal background
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        } else {
            view.backgroundColor = PapyrusDesignSystem.Colors.background
        }
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .automatic
        view.addSubview(scrollView)
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = PapyrusDesignSystem.Spacing.large
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Header view with gradient
        headerView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray6
                : PapyrusDesignSystem.Colors.sandstone
        }
        headerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        headerView.layer.borderWidth = 1
        
        // Add shadow for depth in dark mode
        if traitCollection.userInterfaceStyle == .dark {
            headerView.layer.shadowColor = UIColor(hex: deity.color)?.cgColor ?? UIColor.systemPurple.cgColor
            headerView.layer.shadowOpacity = 0.3
            headerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            headerView.layer.shadowRadius = 8
        }
        
        // Store gradient layer for updates
        let gradientLayer = CAGradientLayer()
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        headerView.layer.insertSublayer(gradientLayer, at: 0)
        self.gradientLayer = gradientLayer
        updateGradientColors()
        updateBorderColors()
        
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = PapyrusDesignSystem.Spacing.medium
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerStackView)
        
        // Avatar - using UIImageView for SF Symbol
        let avatarImageView = UIImageView()
        if let symbolImage = UIImage(systemName: deity.avatar) {
            avatarImageView.image = symbolImage
            avatarImageView.tintColor = UIColor { [weak self] traitCollection in
                let baseColor = UIColor(hex: self?.deity.color ?? "") ?? UIColor.systemPurple
                return traitCollection.userInterfaceStyle == .dark
                    ? baseColor
                    : baseColor.withAlphaComponent(0.9)
            }
        } else {
            // Fallback if not a valid SF Symbol
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = PapyrusDesignSystem.Colors.foreground
        }
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title and keyword
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.spacing = PapyrusDesignSystem.Spacing.xxSmall
        
        titleLabel.text = "\(deity.name), \(deity.role)"
        titleLabel.font = PapyrusDesignSystem.Typography.subheadline()
        titleLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.label
                : PapyrusDesignSystem.Colors.secondaryText
        }
        
        keywordLabel.text = keyword
        keywordLabel.font = PapyrusDesignSystem.Typography.headline(weight: .semibold)
        keywordLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.label
                : PapyrusDesignSystem.Colors.primaryText
        }
        
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(keywordLabel)
        
        headerStackView.addArrangedSubview(avatarImageView)
        headerStackView.addArrangedSubview(titleStackView)
        headerStackView.addArrangedSubview(UIView()) // Spacer
        
        // Content text view
        contentTextView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray5
                : PapyrusDesignSystem.Colors.secondaryBackground
        }
        contentTextView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        contentTextView.font = PapyrusDesignSystem.Typography.body()
        contentTextView.textColor = PapyrusDesignSystem.Colors.foreground
        contentTextView.isEditable = false
        contentTextView.isScrollEnabled = false
        contentTextView.textContainerInset = UIEdgeInsets(
            top: PapyrusDesignSystem.Spacing.medium,
            left: PapyrusDesignSystem.Spacing.medium,
            bottom: PapyrusDesignSystem.Spacing.medium,
            right: PapyrusDesignSystem.Spacing.medium
        )
        
        // Loading indicator
        loadingIndicator.style = traitCollection.userInterfaceStyle == .dark ? .large : .medium
        loadingIndicator.color = UIColor { [weak self] traitCollection in
            let baseColor = UIColor(hex: self?.deity.color ?? "") ?? UIColor.systemPurple
            return traitCollection.userInterfaceStyle == .dark
                ? baseColor
                : baseColor.withAlphaComponent(0.8)
        }
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to content stack
        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(contentTextView)
        
        // Add loading indicator to content text view
        contentTextView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content stack view
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -PapyrusDesignSystem.Spacing.medium * 2),
            
            // Header view
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Header stack view inside header view
            headerStackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            headerStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            headerStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            headerStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            
            // Content text view
            contentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: contentTextView.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: contentTextView.topAnchor, constant: PapyrusDesignSystem.Spacing.large),
            
            // Avatar image view
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    
    // MARK: - Data Loading
    
    private func startStreamingExplanation() {
        contentTextView.text = ""
        loadingIndicator.startAnimating()
        
        streamingTask = Task {
            do {
                // Ensure model is loaded
                if !mlxService.isModelLoaded {
                    try await mlxService.loadModel { progress in
                        // Progress handled internally
                    }
                }
                let prompt = "Explain the concept of '\(keyword)' in the context of afterlife beliefs. Be informative yet concise, speaking in character as \(deity.name)."
                
                let messages = [
                    ChatMessage(role: .system, content: deity.systemPrompt),
                    ChatMessage(role: .user, content: prompt)
                ]
                
                let config = MLXService.GenerationConfig(
                    temperature: 0.7,
                    maxTokens: 400,
                    topP: 0.95,
                    repetitionPenalty: 1.1
                )
                
                let stream = try await mlxService.generate(messages: messages, config: config)
                
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                }
                
                var fullText = ""
                for try await chunk in stream {
                    // Check for cancellation
                    try Task.checkCancellation()
                    guard !Task.isCancelled else { break }
                    
                    fullText += chunk
                    
                    await MainActor.run {
                        self.contentTextView.text = fullText
                        
                        // Auto-scroll to bottom as text streams in
                        if self.contentTextView.contentSize.height > self.contentTextView.bounds.height {
                            let bottomOffset = CGPoint(
                                x: 0,
                                y: self.contentTextView.contentSize.height - self.contentTextView.bounds.size.height + self.contentTextView.contentInset.bottom
                            )
                            self.contentTextView.setContentOffset(bottomOffset, animated: false)
                        }
                    }
                }
            } catch {
                // Don't show error if task was cancelled
                if error is CancellationError || Task.isCancelled {
                    return
                }
                
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.contentTextView.text = "I apologize, but I cannot channel the divine wisdom at this moment. The connection to the eternal realm seems disrupted. Please try again later."
                }
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateGradientColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            // More vibrant gradient in dark mode
            gradientLayer?.colors = [
                (UIColor(hex: deity.color)?.withAlphaComponent(0.4) ?? UIColor.clear).cgColor,
                (UIColor(hex: deity.color)?.withAlphaComponent(0.1) ?? UIColor.clear).cgColor
            ]
        } else {
            // Subtle gradient in light mode
            gradientLayer?.colors = [
                (UIColor(hex: deity.color)?.withAlphaComponent(0.15) ?? UIColor.clear).cgColor,
                (UIColor(hex: deity.color)?.withAlphaComponent(0.05) ?? UIColor.clear).cgColor
            ]
        }
    }
    
    private func updateBorderColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            // Use the deity color more prominently in dark mode
            headerView.layer.borderColor = UIColor(hex: deity.color)?.withAlphaComponent(0.6).cgColor ?? UIColor.systemPurple.cgColor
            headerView.layer.borderWidth = 1.5
        } else {
            headerView.layer.borderColor = UIColor(hex: deity.color)?.withAlphaComponent(0.3).cgColor ?? PapyrusDesignSystem.Colors.aged.cgColor
            headerView.layer.borderWidth = 1
        }
    }
    
    private func updateShadows() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            headerView.layer.shadowColor = UIColor(hex: deity.color)?.cgColor ?? UIColor.systemPurple.cgColor
            headerView.layer.shadowOpacity = 0.3
            headerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            headerView.layer.shadowRadius = 8
        } else {
            headerView.layer.shadowColor = UIColor.clear.cgColor
            headerView.layer.shadowOpacity = 0
        }
    }
    
    private func updateBackgroundColor() {
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        } else {
            view.backgroundColor = PapyrusDesignSystem.Colors.background
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Modal has been fully dismissed
        #if DEBUG
        print("🔮 PapyrusModal: presentationControllerDidDismiss - modal fully dismissed, cancelling task")
        #endif
        streamingTask?.cancel()
        streamingTask = nil
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismissal at any time
        return true
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        // Modal is about to be dismissed but user can still cancel the gesture
        #if DEBUG
        print("🔮 PapyrusModal: presentationControllerWillDismiss - dismissal gesture started")
        #endif
    }
}

