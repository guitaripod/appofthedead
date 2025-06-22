import UIKit

protocol OracleTextExplanationViewDelegate: AnyObject {
    func oracleTextExplanationViewDidDismiss(_ view: OracleTextExplanationView)
    func oracleTextExplanationView(_ view: OracleTextExplanationView, didSaveExplanation: String, for text: String)
}

final class OracleTextExplanationViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Properties
    
    weak var delegate: OracleTextExplanationViewDelegate?
    weak var wrapperView: OracleTextExplanationView?
    private let selectedText: String
    private let bookContext: String
    private let deityId: String
    private var oracleResponse: String = ""
    private var streamingTask: Task<Void, Never>?
    private let mlxService = MLXService.shared
    private let mlxManager = MLXModelManager.shared
    private var deity: Deity?
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let deityImageView = UIImageView()
    private let selectedTextContainer = UIView()
    private let selectedTextLabel = UILabel()
    private let responseTextView = UITextView()
    private let loadingView = PapyrusLoadingView(style: .oracle)
    private let saveButton = UIButton(type: .system)
    
    // Download UI components
    private let downloadContainerView = UIView()
    private let downloadLoadingView = PapyrusLoadingView(style: .download)
    private let downloadButton = UIButton(type: .system)
    
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Initialization
    
    init(selectedText: String, bookContext: String, deityId: String) {
        self.selectedText = selectedText
        self.bookContext = bookContext
        self.deityId = deityId
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
        loadDeity()
        setupUI()
        
        // Check if model is loaded
        if mlxManager.isModelLoaded {
            // Model is loaded, start streaming
            downloadContainerView.isHidden = true
            responseTextView.isHidden = false
            startStreamingExplanation()
        } else {
            // Model needs to be downloaded
            downloadContainerView.isHidden = false
            responseTextView.isHidden = true
            setupDownloadUI()
        }
        
        // Set presentation controller delegate to detect actual dismissal
        presentationController?.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame
        gradientLayer?.frame = headerView.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateColors()
        }
    }
    
    deinit {
        streamingTask?.cancel()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.background
        
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
        
        // Header with gradient
        setupHeader()
        
        // Selected text section
        setupSelectedTextSection()
        
        // Response section
        setupResponseSection()
        
        // Save button
        setupSaveButton()
        
        // Download container
        setupDownloadContainer()
        
        // Add to content stack
        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(selectedTextContainer)
        contentStackView.addArrangedSubview(responseTextView)
        contentStackView.addArrangedSubview(downloadContainerView)
        contentStackView.addArrangedSubview(saveButton)
        
        setupConstraints()
    }
    
    private func setupHeader() {
        headerView.backgroundColor = PapyrusDesignSystem.Colors.secondaryBackground
        headerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        headerView.layer.borderWidth = 1
        
        // Add gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        headerView.layer.insertSublayer(gradientLayer, at: 0)
        self.gradientLayer = gradientLayer
        
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = PapyrusDesignSystem.Spacing.medium
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerStackView)
        
        // Deity image
        deityImageView.contentMode = .scaleAspectFit
        deityImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "Oracle's Wisdom"
        titleLabel.font = PapyrusDesignSystem.Typography.headline(weight: .bold)
        titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
        titleLabel.numberOfLines = 0
        
        headerStackView.addArrangedSubview(deityImageView)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(UIView()) // Spacer
        
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            headerStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            headerStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            headerStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            
            deityImageView.widthAnchor.constraint(equalToConstant: 44),
            deityImageView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupSelectedTextSection() {
        selectedTextContainer.backgroundColor = PapyrusDesignSystem.Colors.secondaryBackground
        selectedTextContainer.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        selectedTextContainer.layer.borderWidth = 1
        selectedTextContainer.layer.borderColor = PapyrusDesignSystem.Colors.aged.cgColor
        
        selectedTextLabel.text = "\"\(selectedText)\""
        selectedTextLabel.font = PapyrusDesignSystem.Typography.bodyItalic()
        selectedTextLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        selectedTextLabel.numberOfLines = 0
        selectedTextLabel.textAlignment = .center
        selectedTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        selectedTextContainer.addSubview(selectedTextLabel)
        
        NSLayoutConstraint.activate([
            selectedTextLabel.topAnchor.constraint(equalTo: selectedTextContainer.topAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            selectedTextLabel.leadingAnchor.constraint(equalTo: selectedTextContainer.leadingAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            selectedTextLabel.trailingAnchor.constraint(equalTo: selectedTextContainer.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            selectedTextLabel.bottomAnchor.constraint(equalTo: selectedTextContainer.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.medium)
        ])
    }
    
    private func setupResponseSection() {
        responseTextView.backgroundColor = PapyrusDesignSystem.Colors.secondaryBackground
        responseTextView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        responseTextView.font = PapyrusDesignSystem.Typography.body()
        responseTextView.textColor = PapyrusDesignSystem.Colors.foreground
        responseTextView.isEditable = false
        responseTextView.isScrollEnabled = false
        responseTextView.textContainerInset = UIEdgeInsets(
            top: PapyrusDesignSystem.Spacing.medium,
            left: PapyrusDesignSystem.Spacing.medium,
            bottom: PapyrusDesignSystem.Spacing.medium,
            right: PapyrusDesignSystem.Spacing.medium
        )
        
        // Add loading view to response text view
        responseTextView.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            responseTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            loadingView.centerXAnchor.constraint(equalTo: responseTextView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: responseTextView.centerYAnchor),
            loadingView.widthAnchor.constraint(equalTo: responseTextView.widthAnchor),
            loadingView.heightAnchor.constraint(equalTo: responseTextView.heightAnchor)
        ])
    }
    
    private func setupSaveButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Save to Highlights"
        config.image = UIImage(systemName: "bookmark")
        config.imagePadding = 8
        config.baseBackgroundColor = PapyrusDesignSystem.Colors.goldLeaf
        config.baseForegroundColor = PapyrusDesignSystem.Colors.ancientInk
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        saveButton.configuration = config
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.isHidden = true
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupDownloadContainer() {
        downloadContainerView.backgroundColor = PapyrusDesignSystem.Colors.secondaryBackground
        downloadContainerView.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        downloadContainerView.layer.borderWidth = 1
        downloadContainerView.isHidden = true
        downloadContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add download loading view
        downloadContainerView.addSubview(downloadLoadingView)
        downloadLoadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            downloadContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            downloadLoadingView.topAnchor.constraint(equalTo: downloadContainerView.topAnchor),
            downloadLoadingView.leadingAnchor.constraint(equalTo: downloadContainerView.leadingAnchor),
            downloadLoadingView.trailingAnchor.constraint(equalTo: downloadContainerView.trailingAnchor),
            downloadLoadingView.bottomAnchor.constraint(equalTo: downloadContainerView.bottomAnchor)
        ])
    }
    
    private func setupDownloadUI() {
        // Update download loading view
        if DeviceUtility.isSimulator {
            downloadLoadingView.updateTitle("Simulator Mode")
            downloadLoadingView.updateSubtitle("The Oracle runs on device. Use a physical device to experience divine wisdom.")
        } else {
            downloadLoadingView.updateTitle("Oracle Model Required")
            downloadLoadingView.updateSubtitle("Download the Oracle model to unlock divine explanations.")
        }
        
        // Add download button
        downloadButton.setTitle(DeviceUtility.isSimulator ? "Use Physical Device" : "Download Oracle Model", for: .normal)
        downloadButton.titleLabel?.font = PapyrusDesignSystem.Typography.body(weight: .semibold)
        downloadButton.backgroundColor = deity?.color != nil ? UIColor(hex: deity!.color) : PapyrusDesignSystem.Colors.goldLeaf
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        downloadButton.isEnabled = !DeviceUtility.isSimulator
        downloadButton.alpha = DeviceUtility.isSimulator ? 0.5 : 1.0
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        
        downloadContainerView.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            downloadButton.centerXAnchor.constraint(equalTo: downloadContainerView.centerXAnchor),
            downloadButton.bottomAnchor.constraint(equalTo: downloadContainerView.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.xLarge),
            downloadButton.widthAnchor.constraint(equalToConstant: 250),
            downloadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupConstraints() {
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
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadDeity() {
        // Load deity from content loader or use default
        let contentLoader = ContentLoader()
        let loadedDeities = contentLoader.loadDeities()
        if let matchedDeity = loadedDeities.values.first(where: { $0.id.lowercased() == deityId.lowercased() }) {
            self.deity = matchedDeity
            updateDeityUI()
        }
    }
    
    private func updateDeityUI() {
        guard let deity = deity else { return }
        
        // Update deity image
        if let symbolImage = UIImage(systemName: deity.avatar) {
            deityImageView.image = symbolImage
            deityImageView.tintColor = UIColor(hex: deity.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        } else {
            deityImageView.image = UIImage(systemName: "sparkle.magnifyingglass")
            deityImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        }
        
        // Update title with deity name
        titleLabel.text = "\(deity.name)'s Wisdom"
        
        // Update colors
        let deityColor = UIColor(hex: deity.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        loadingView.setDeityColor(deityColor)
        downloadLoadingView.setDeityColor(deityColor)
        updateColors()
    }
    
    private func updateColors() {
        let deityColor = deity?.color != nil ? UIColor(hex: deity!.color) : PapyrusDesignSystem.Colors.goldLeaf
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update gradient
        if isDarkMode {
            gradientLayer?.colors = [
                (deityColor?.withAlphaComponent(0.3) ?? UIColor.clear).cgColor,
                (deityColor?.withAlphaComponent(0.1) ?? UIColor.clear).cgColor
            ]
        } else {
            gradientLayer?.colors = [
                (deityColor?.withAlphaComponent(0.15) ?? UIColor.clear).cgColor,
                (deityColor?.withAlphaComponent(0.05) ?? UIColor.clear).cgColor
            ]
        }
        
        // Update borders
        headerView.layer.borderColor = deityColor?.withAlphaComponent(0.3).cgColor ?? PapyrusDesignSystem.Colors.aged.cgColor
        downloadContainerView.layer.borderColor = deityColor?.withAlphaComponent(0.3).cgColor ?? PapyrusDesignSystem.Colors.aged.cgColor
    }
    
    // MARK: - Oracle Integration
    
    private func startStreamingExplanation() {
        responseTextView.text = ""
        loadingView.startAnimating()
        
        streamingTask = Task {
            do {
                // Ensure model is loaded
                if !mlxService.isModelLoaded {
                    try await mlxService.loadModel { progress in
                        // Progress handled internally
                    }
                }
                
                let deityName = deity?.name ?? "the Oracle"
                let deityPrompt = deity?.systemPrompt ?? "You are a wise oracle providing mystical insights about sacred texts."
                
                let prompt = """
                As \(deityName), explain the following text from the book in your unique voice and perspective:
                
                Selected text: "\(selectedText)"
                
                Book context: \(bookContext)
                
                Provide a mystical and insightful explanation that helps the reader understand the deeper meaning of this passage. Keep your response concise but enlightening.
                """
                
                let messages = [
                    ChatMessage(role: .system, content: deityPrompt),
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
                    // Update title to "The Eternal" when streaming starts
                    self.titleLabel.text = "The Eternal"
                    self.loadingView.stopAnimating()
                    self.loadingView.isHidden = true
                }
                
                var fullText = ""
                for try await chunk in stream {
                    // Check for cancellation
                    try Task.checkCancellation()
                    guard !Task.isCancelled else { break }
                    
                    fullText += chunk
                    
                    await MainActor.run {
                        self.responseTextView.text = fullText
                        
                        // Auto-scroll to bottom as text streams in
                        if self.responseTextView.contentSize.height > self.responseTextView.bounds.height {
                            let bottomOffset = CGPoint(
                                x: 0,
                                y: self.responseTextView.contentSize.height - self.responseTextView.bounds.size.height + self.responseTextView.contentInset.bottom
                            )
                            self.responseTextView.setContentOffset(bottomOffset, animated: false)
                        }
                    }
                }
                
                self.oracleResponse = fullText
                
                await MainActor.run {
                    self.saveButton.isHidden = false
                }
                
            } catch {
                // Don't show error if task was cancelled
                if error is CancellationError || Task.isCancelled {
                    return
                }
                
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.loadingView.isHidden = true
                    self.responseTextView.text = "The oracle's wisdom could not be reached at this time. Please try again later."
                    AppLogger.mlx.error("Failed to get oracle explanation: \(error)")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func downloadButtonTapped() {
        guard !DeviceUtility.isSimulator else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        downloadButton.isHidden = true
        downloadLoadingView.startAnimating()
        downloadLoadingView.updateProgress(0, withText: "Preparing divine connection...")
        
        Task {
            do {
                try await mlxManager.downloadModel { [weak self] progress in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        let progressPercent = Int(progress.progress * 100)
                        let statusText: String
                        
                        if progressPercent < 10 {
                            statusText = "Gathering sacred texts..."
                        } else if progressPercent < 30 {
                            statusText = "Channeling divine wisdom..."
                        } else if progressPercent < 50 {
                            statusText = "Deciphering ancient knowledge..."
                        } else if progressPercent < 70 {
                            statusText = "Binding ethereal essence..."
                        } else if progressPercent < 90 {
                            statusText = "Preparing the Oracle..."
                        } else {
                            statusText = "Finalizing divine connection..."
                        }
                        
                        self.downloadLoadingView.updateProgress(progress.progress, withText: statusText)
                        
                        // Check if download completed
                        if progress.progress >= 1.0 {
                            UIView.animate(withDuration: 0.3) {
                                self.downloadContainerView.alpha = 0
                                self.responseTextView.alpha = 1
                            } completion: { _ in
                                self.downloadContainerView.isHidden = true
                                self.responseTextView.isHidden = false
                                self.startStreamingExplanation()
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.downloadButton.isHidden = false
                    self.downloadLoadingView.stopAnimating()
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Download Failed",
                        message: "Unable to download the Oracle model. Please check your internet connection and try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func saveTapped() {
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.saveButton.transform = .identity
            }
        }
        
        // Notify delegate
        if let wrapper = wrapperView {
            delegate?.oracleTextExplanationView(wrapper, didSaveExplanation: oracleResponse, for: selectedText)
        }
        
        // Change button state
        var config = saveButton.configuration
        config?.title = "Saved!"
        config?.image = UIImage(systemName: "bookmark.fill")
        saveButton.configuration = config
        saveButton.isEnabled = false
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.dismiss(animated: true)
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        streamingTask?.cancel()
        streamingTask = nil
        if let wrapper = wrapperView {
            delegate?.oracleTextExplanationViewDidDismiss(wrapper)
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}

// MARK: - Compatibility Wrapper

/// Legacy wrapper for compatibility with existing code
final class OracleTextExplanationView {
    weak var delegate: OracleTextExplanationViewDelegate?
    private let selectedText: String
    private let bookContext: String
    private let deityId: String
    
    init(selectedText: String, bookContext: String, deityId: String) {
        self.selectedText = selectedText
        self.bookContext = bookContext
        self.deityId = deityId
    }
    
    func show(in parentView: UIView) {
        // Find the parent view controller
        guard let parentViewController = parentView.parentViewController else { return }
        
        // Summon The Eternal instead of using deity-specific oracle
        parentViewController.summonTheEternal(for: selectedText, context: bookContext, from: parentViewController)
        
        // For backwards compatibility with delegate pattern
        // The Eternal doesn't use delegates, so we simulate the save callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.delegate?.oracleTextExplanationView(self, didSaveExplanation: "The Eternal's wisdom has been received", for: self.selectedText)
        }
    }
}

// MARK: - UIView Extension

private extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}