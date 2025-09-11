import UIKit

class PaywallViewController: UIViewController {
    
    // MARK: - Properties
    private let dismissButton = UIButton()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let featuresStackView = UIStackView()
    private let productsStackView = UIStackView()
    private let restoreButton = UIButton(type: .system)
    private let termsLabel = UILabel()
    
    private var selectedProduct: ProductIdentifier?
    private let reason: PaywallReason
    private var pathPreviewAnimator: PathPreviewAnimator?
    private var pathPreviews: [String: PathPreview] = [:]
    private var beliefSystems: [BeliefSystem] = []
    
    enum PaywallReason {
        case lockedPath(beliefSystemId: String)
        case oracleLimit(deityId: String, deityName: String)
        case generalUpgrade
        
        var title: String {
            switch self {
            case .lockedPath:
                return "Unlock Your Journey"
            case .oracleLimit:
                return "Continue the Conversation"
            case .generalUpgrade:
                return "Unlock Everything"
            }
        }
        
        var subtitle: String {
            switch self {
            case .lockedPath:
                return "Explore new belief systems and expand your understanding"
            case .oracleLimit:
                return "Get unlimited access to divine wisdom"
            case .generalUpgrade:
                return "Access all paths, deities, and exclusive features"
            }
        }
    }
    
    // MARK: - Initialization
    init(reason: PaywallReason = .generalUpgrade) {
        self.reason = reason
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPathPreviews()
        loadBeliefSystems()
        fetchOfferings()
        
        // Setup preview animator
        pathPreviewAnimator = PathPreviewAnimator(containerView: view)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.background
        
        // Dismiss button
        dismissButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        dismissButton.tintColor = .secondaryLabel
        dismissButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        
        // ScrollView setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Header
        setupHeader()
        
        // Features
        setupFeatures()
        
        // Products
        setupProducts()
        
        // Restore button
        restoreButton.setTitle("Restore Purchases", for: .normal)
        restoreButton.titleLabel?.font = PapyrusDesignSystem.Typography.subheadline()
        restoreButton.addAction(UIAction { [weak self] _ in
            self?.handleRestorePurchases()
        }, for: .touchUpInside)
        contentStackView.addArrangedSubview(restoreButton)
        
        // Terms
        termsLabel.text = "Payment will be charged to your Apple ID account. By purchasing, you agree to our Terms of Service and Privacy Policy."
        termsLabel.font = UIFont.systemFont(ofSize: 12)
        termsLabel.textColor = .secondaryLabel
        termsLabel.textAlignment = .center
        termsLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(termsLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),
            
            scrollView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func setupHeader() {
        titleLabel.text = reason.title
        titleLabel.font = PapyrusDesignSystem.Typography.title1()
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        subtitleLabel.text = reason.subtitle
        subtitleLabel.font = PapyrusDesignSystem.Typography.body()
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        contentStackView.addArrangedSubview(headerStack)
    }
    
    private func setupFeatures() {
        let features: [(icon: String, title: String, description: String)]
        
        switch reason {
        case .lockedPath:
            features = [
                ("book.fill", "Complete Learning Path", "Access all lessons and quizzes"),
                ("star.fill", "Exclusive Achievements", "Unlock path-specific badges"),
                ("infinity", "Lifetime Access", "Learn at your own pace forever")
            ]
        case .oracleLimit:
            features = [
                ("bubble.left.and.bubble.right.fill", "Unlimited Consultations", "Chat without limits"),
                ("sparkles", "Deeper Wisdom", "Access advanced guidance"),
                ("clock.fill", "Conversation History", "Review past insights")
            ]
        case .generalUpgrade:
            features = [
                ("lock.open.fill", "All Belief Systems", "9+ paths to explore"),
                ("person.3.fill", "All 21 Deities", "Unlimited Oracle access"),
                ("star.fill", "Premium Features", "Exclusive content & insights"),
                ("crown.fill", "Exclusive Content", "Special achievements & features")
            ]
        }
        
        for feature in features {
            let featureView = createFeatureRow(icon: feature.icon, title: feature.title, description: feature.description)
            featuresStackView.addArrangedSubview(featureView)
        }
        
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 16
        contentStackView.addArrangedSubview(featuresStackView)
    }
    
    private func createFeatureRow(icon: String, title: String, description: String) -> UIView {
        let container = UIView()
        
        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconImageView)
        container.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func setupProducts() {
        productsStackView.axis = .vertical
        productsStackView.spacing = 12
        contentStackView.addArrangedSubview(productsStackView)
        
        // Add loading indicator
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.startAnimating()
        productsStackView.addArrangedSubview(loadingView)
    }
    
    // MARK: - Data Loading
    private func loadPathPreviews() {
        guard let url = Bundle.main.url(forResource: "path_previews", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        
        do {
            pathPreviews = try JSONDecoder().decode([String: PathPreview].self, from: data)
        } catch {
            AppLogger.logError(error, context: "Loading path previews", logger: AppLogger.content)
        }
    }
    
    private func loadBeliefSystems() {
        beliefSystems = DatabaseManager.shared.loadBeliefSystems()
    }
    
    // MARK: - Product Cards
    private func createProductCard(for product: ProductIdentifier, price: String, recommended: Bool = false) -> UIView {
        let card = UIView()
        card.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 2
        card.layer.borderColor = UIColor.clear.cgColor
        
        if recommended {
            card.layer.borderColor = PapyrusDesignSystem.Colors.goldLeaf.cgColor
        }
        
        let titleLabel = UILabel()
        titleLabel.text = product.displayName
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        let descLabel = UILabel()
        descLabel.text = product.description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        priceLabel.textColor = PapyrusDesignSystem.Colors.goldLeaf
        
        let buyButton = UIButton(type: .system)
        buyButton.setTitle(recommended ? "Best Value" : "Select", for: .normal)
        buyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        buyButton.backgroundColor = recommended ? PapyrusDesignSystem.Colors.Core.goldLeaf : PapyrusDesignSystem.Colors.Core.aged
        buyButton.setTitleColor(recommended ? PapyrusDesignSystem.Colors.Core.ancientInk : PapyrusDesignSystem.Colors.Dynamic.primaryText, for: .normal)
        buyButton.layer.cornerRadius = 8
        
        // Different action based on whether it's a path product
        if case .lockedPath = reason, product.beliefSystemId != nil {
            buyButton.addAction(UIAction { [weak self, weak buyButton] _ in
                self?.handlePathProductTapped(product, from: buyButton)
            }, for: .touchUpInside)
        } else {
            buyButton.addAction(UIAction { [weak self] _ in
                self?.handleProductSelected(product)
            }, for: .touchUpInside)
        }
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, descLabel, priceLabel, buyButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            
            buyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return card
    }
    
    // MARK: - Actions
    
    private func handleProductSelected(_ product: ProductIdentifier) {
        selectedProduct = product
        purchaseProduct(product)
    }
    
    private func handlePathProductTapped(_ product: ProductIdentifier, from sourceView: UIView?) {
        guard let beliefSystemId = product.beliefSystemId,
              let preview = pathPreviews[beliefSystemId],
              let beliefSystem = beliefSystems.first(where: { $0.id == beliefSystemId }) else {
            // Fallback to direct purchase if preview not available
            handleProductSelected(product)
            return
        }
        
        // Get price
        let price = StoreManager.shared.formattedPrice(for: product) ?? "$--"
        
        // Create and show preview
        let previewView = PathPreviewView()
        previewView.configure(with: preview, beliefSystem: beliefSystem, price: price) { [weak self] selectedProduct in
            self?.selectedProduct = selectedProduct
            self?.pathPreviewAnimator?.dismiss(animated: true) {
                self?.purchaseProduct(selectedProduct)
            }
        }
        
        pathPreviewAnimator?.present(pathPreview: previewView, from: sourceView ?? view, animated: true)
    }
    
    private func handleRestorePurchases() {
        restoreButton.isEnabled = false
        
        StoreManager.shared.restorePurchases { [weak self] result in
            DispatchQueue.main.async {
                self?.restoreButton.isEnabled = true
                
                switch result {
                case .success:
                    self?.showAlert(title: "Success", message: "Purchases restored successfully!")
                    self?.dismiss(animated: true)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Store Operations
    private func fetchOfferings() {
        StoreManager.shared.fetchOfferings { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let offerings):
                    self?.displayProducts(offerings)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: "Unable to load products: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func displayProducts(_ offerings: Any) {
        // Clear loading indicator
        productsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Determine which products to show based on reason
        let productsToShow: [ProductIdentifier]
        
        switch reason {
        case .lockedPath(let beliefSystemId):
            // Show the specific path and ultimate pack
            if let pathProduct = ProductIdentifier.allCases.first(where: { $0.beliefSystemId == beliefSystemId }) {
                productsToShow = [pathProduct, .ultimateEnlightenment]
            } else {
                productsToShow = [.ultimateEnlightenment]
            }
        case .oracleLimit(let deityId, _):
            // Check if deity is in a pack
            var products: [ProductIdentifier] = []
            
            // Check which pack contains this deity (using exact IDs from UserPurchaseExtensions)
            let egyptianDeities = ["anubis", "kali", "baron_samedi"]
            let greekDeities = ["hermes", "hecate", "pachamama"]
            let easternDeities = ["yama", "meng_po", "izanami"]
            
            if egyptianDeities.contains(deityId) {
                products.append(.egyptianPantheon)
            } else if greekDeities.contains(deityId) {
                products.append(.greekGuides)
            } else if easternDeities.contains(deityId) {
                products.append(.easternWisdom)
            }
            
            // Always add oracle wisdom and ultimate as options
            products.append(.oracleWisdom)
            products.append(.ultimateEnlightenment)
            
            productsToShow = products
        case .generalUpgrade:
            productsToShow = [.oracleWisdom, .ultimateEnlightenment]
        }
        
        // Add product cards
        for productId in productsToShow {
            let price = StoreManager.shared.formattedPrice(for: productId) ?? "$--"
            let isRecommended = productId == .ultimateEnlightenment
            let card = createProductCard(for: productId, price: price, recommended: isRecommended)
            productsStackView.addArrangedSubview(card)
        }
    }
    
    private func purchaseProduct(_ product: ProductIdentifier) {
        // Disable UI during purchase
        view.isUserInteractionEnabled = false
        
        // Show loading
        let loadingView = UIActivityIndicatorView(style: .large)
        loadingView.center = view.center
        loadingView.startAnimating()
        view.addSubview(loadingView)
        
        StoreManager.shared.purchase(productId: product) { [weak self] result in
            DispatchQueue.main.async {
                loadingView.removeFromSuperview()
                self?.view.isUserInteractionEnabled = true
                
                switch result {
                case .success:
                    self?.showSuccessAndDismiss()
                case .failure(let error):
                    self?.showAlert(title: "Purchase Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showSuccessAndDismiss() {
        // Refresh customer info to ensure entitlements are up to date
        StoreManager.shared.refreshCustomerInfo { [weak self] in
            DispatchQueue.main.async {
                self?.showSuccessAnimation()
            }
        }
    }
    
    private func showSuccessAnimation() {
        let successView = UIView()
        successView.backgroundColor = PapyrusDesignSystem.Colors.background
        successView.alpha = 0
        view.addSubview(successView)
        successView.frame = view.bounds
        
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Purchase Successful!"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        successView.addSubview(checkmark)
        successView.addSubview(label)
        
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: successView.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: successView.centerYAnchor, constant: -40),
            checkmark.widthAnchor.constraint(equalToConstant: 80),
            checkmark.heightAnchor.constraint(equalToConstant: 80),
            
            label.topAnchor.constraint(equalTo: checkmark.bottomAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: successView.centerXAnchor)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            successView.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss(animated: true)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}