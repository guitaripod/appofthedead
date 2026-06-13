import UIKit
import SafariServices

class PaywallViewController: UIViewController {

    private let viewModel: PaywallViewModel

    private let dismissButton = UIButton()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let featuresStackView = UIStackView()
    private let plansStackView = UIStackView()
    private let timelineContainer = UIStackView()
    private let noPaymentLabel = UILabel()
    private let aLaCarteButton = UIButton(type: .system)
    private let bottomBar = UIVisualEffectView(effect: PapyrusDesignSystem.Glass.effect())
    private let ctaButton = UIButton(type: .system)
    private let disclosureLabel = UILabel()
    private let legalStackView = UIStackView()

    private var planCardViews: [PlanCardView] = []
    private var pathPreviewAnimator: PathPreviewAnimator?
    private var pathPreviews: [String: PathPreview] = [:]
    private var beliefSystems: [BeliefSystem] = []
    private var purchaseLoadingView: UIActivityIndicatorView?

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    init(reason: PaywallReason = .generalUpgrade) {
        self.viewModel = PaywallViewModel(reason: reason)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadPathPreviews()
        loadBeliefSystems()
        viewModel.loadProducts()
        selectionFeedback.prepare()

        pathPreviewAnimator = PathPreviewAnimator(containerView: view)
    }

    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.background

        setupDismissButton()
        setupBottomBar()
        setupScrollContent()
    }

    private func setupDismissButton() {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))
        config.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        dismissButton.configuration = config

        let glassCircle = PapyrusDesignSystem.Glass.makeCard(cornerRadius: 18, interactive: true)
        glassCircle.isUserInteractionEnabled = false
        glassCircle.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.insertSubview(glassCircle, at: 0)

        dismissButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            glassCircle.topAnchor.constraint(equalTo: dismissButton.topAnchor),
            glassCircle.leadingAnchor.constraint(equalTo: dismissButton.leadingAnchor),
            glassCircle.trailingAnchor.constraint(equalTo: dismissButton.trailingAnchor),
            glassCircle.bottomAnchor.constraint(equalTo: dismissButton.bottomAnchor),

            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.medium),
            dismissButton.widthAnchor.constraint(equalToConstant: 36),
            dismissButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupBottomBar() {
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        if #unavailable(iOS 26.0) {
            bottomBar.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        }
        view.addSubview(bottomBar)

        configureCTAButton()
        ctaButton.isEnabled = false
        ctaButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.purchaseSelectedPlan()
        }, for: .touchUpInside)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        disclosureLabel.font = PapyrusDesignSystem.Typography.caption1()
        disclosureLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        disclosureLabel.textAlignment = .center
        disclosureLabel.numberOfLines = 0
        disclosureLabel.translatesAutoresizingMaskIntoConstraints = false

        setupLegalLinks()

        bottomBar.contentView.addSubview(ctaButton)
        bottomBar.contentView.addSubview(disclosureLabel)
        bottomBar.contentView.addSubview(legalStackView)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ctaButton.topAnchor.constraint(equalTo: bottomBar.contentView.topAnchor, constant: PapyrusDesignSystem.Spacing.small),
            ctaButton.leadingAnchor.constraint(equalTo: bottomBar.contentView.leadingAnchor, constant: PapyrusDesignSystem.Spacing.large),
            ctaButton.trailingAnchor.constraint(equalTo: bottomBar.contentView.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.large),
            ctaButton.heightAnchor.constraint(equalToConstant: 54),

            disclosureLabel.topAnchor.constraint(equalTo: ctaButton.bottomAnchor, constant: PapyrusDesignSystem.Spacing.xSmall),
            disclosureLabel.leadingAnchor.constraint(equalTo: ctaButton.leadingAnchor),
            disclosureLabel.trailingAnchor.constraint(equalTo: ctaButton.trailingAnchor),

            legalStackView.topAnchor.constraint(equalTo: disclosureLabel.bottomAnchor, constant: PapyrusDesignSystem.Spacing.xSmall),
            legalStackView.centerXAnchor.constraint(equalTo: bottomBar.contentView.centerXAnchor),
            legalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.xSmall)
        ])
    }

    private func configureCTAButton() {
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .prominentGlass()
        } else {
            config = .filled()
        }
        config.baseBackgroundColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        config.baseForegroundColor = PapyrusDesignSystem.Colors.Core.ancientInk
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            return updated
        }
        ctaButton.configuration = config
    }

    private func setupLegalLinks() {
        legalStackView.axis = .horizontal
        legalStackView.spacing = PapyrusDesignSystem.Spacing.medium
        legalStackView.translatesAutoresizingMaskIntoConstraints = false

        let restore = makeFooterLink(title: "Restore Purchases") { [weak self] in
            self?.handleRestorePurchases()
        }
        let terms = makeFooterLink(title: "Terms of Use") { [weak self] in
            self?.openLegalLink(LegalLinks.termsOfService)
        }
        let privacy = makeFooterLink(title: "Privacy Policy") { [weak self] in
            self?.openLegalLink(LegalLinks.privacyPolicy)
        }

        [restore, terms, privacy].forEach { legalStackView.addArrangedSubview($0) }
    }

    private func makeFooterLink(title: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: PapyrusDesignSystem.Typography.caption1(),
            .foregroundColor: PapyrusDesignSystem.Colors.Dynamic.secondaryText,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]))
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func setupScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.insertSubview(scrollView, belowSubview: dismissButton)

        contentStackView.axis = .vertical
        contentStackView.spacing = PapyrusDesignSystem.Spacing.large
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        setupHeader()
        setupFeatures()
        setupPlans()
        setupTimeline()
        setupNoPaymentLabel()
        setupALaCarteButton()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: PapyrusDesignSystem.Spacing.xSmall),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: PapyrusDesignSystem.Spacing.small),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: PapyrusDesignSystem.Spacing.large),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -PapyrusDesignSystem.Spacing.large),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -PapyrusDesignSystem.Spacing.large),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * PapyrusDesignSystem.Spacing.large)
        ])
    }

    private func setupHeader() {
        titleLabel.text = viewModel.reason.title
        titleLabel.font = PapyrusDesignSystem.Typography.title1()
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = viewModel.reason.subtitle
        subtitleLabel.font = PapyrusDesignSystem.Typography.body()
        subtitleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = PapyrusDesignSystem.Spacing.xSmall
        contentStackView.addArrangedSubview(headerStack)
    }

    private func setupFeatures() {
        featuresStackView.axis = .vertical
        featuresStackView.spacing = PapyrusDesignSystem.Spacing.medium

        for feature in viewModel.features {
            featuresStackView.addArrangedSubview(
                createFeatureRow(icon: feature.icon, title: feature.title, description: feature.description))
        }

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
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
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

            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: PapyrusDesignSystem.Spacing.medium),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func setupPlans() {
        plansStackView.axis = .vertical
        plansStackView.spacing = PapyrusDesignSystem.Spacing.small
        contentStackView.addArrangedSubview(plansStackView)

        showPlansLoadingIndicator()
    }

    private func showPlansLoadingIndicator() {
        plansStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.startAnimating()
        plansStackView.addArrangedSubview(loadingView)
    }

    private func setupTimeline() {
        timelineContainer.axis = .vertical
        timelineContainer.spacing = PapyrusDesignSystem.Spacing.small
        timelineContainer.isHidden = true
        contentStackView.addArrangedSubview(timelineContainer)
    }

    private func setupNoPaymentLabel() {
        noPaymentLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        noPaymentLabel.textColor = PapyrusDesignSystem.Colors.Core.scarabGreen
        noPaymentLabel.textAlignment = .center
        let checkConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let checkAttachment = NSTextAttachment()
        checkAttachment.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig)?
            .withTintColor(PapyrusDesignSystem.Colors.Core.scarabGreen, renderingMode: .alwaysOriginal)
        let noPaymentText = NSMutableAttributedString(attachment: checkAttachment)
        noPaymentText.append(NSAttributedString(string: " No payment due now"))
        noPaymentLabel.attributedText = noPaymentText
        noPaymentLabel.isHidden = true
        contentStackView.addArrangedSubview(noPaymentLabel)
    }

    private func setupALaCarteButton() {
        aLaCarteButton.isHidden = true
        aLaCarteButton.titleLabel?.font = PapyrusDesignSystem.Typography.subheadline()
        aLaCarteButton.setTitleColor(PapyrusDesignSystem.Colors.Dynamic.secondaryText, for: .normal)
        aLaCarteButton.addAction(UIAction { [weak self] _ in
            self?.handleALaCarteTapped()
        }, for: .touchUpInside)
        contentStackView.addArrangedSubview(aLaCarteButton)
    }

    private func bindViewModel() {
        viewModel.onPlansUpdated = { [weak self] in
            self?.rebuildPlanCards()
            self?.refreshSelectionDependentUI()
        }
        viewModel.onSelectionChanged = { [weak self] in
            self?.selectionFeedback.selectionChanged()
            self?.refreshSelectionDependentUI()
        }
        viewModel.onALaCartePriceUpdated = { [weak self] in
            self?.refreshALaCarteButton()
        }
        viewModel.onPurchaseStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handlePurchaseState(state)
            }
        }
    }

    private func rebuildPlanCards() {
        plansStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        planCardViews = viewModel.planCards.map { card in
            let cardView = PlanCardView(card: card)
            cardView.addAction(UIAction { [weak self] _ in
                self?.viewModel.select(cardView.plan)
            }, for: .touchUpInside)
            plansStackView.addArrangedSubview(cardView)
            return cardView
        }
        ctaButton.isEnabled = !planCardViews.isEmpty
        if planCardViews.isEmpty {
            showPlansUnavailableState()
        }
        refreshALaCarteButton()
    }

    private func showPlansUnavailableState() {
        let label = UILabel()
        label.text = "Plans couldn't be loaded. Check your connection and try again."
        label.font = PapyrusDesignSystem.Typography.subheadline()
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0

        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Retry", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: PapyrusDesignSystem.Colors.goldLeaf
        ]))
        let retryButton = UIButton(configuration: config)
        retryButton.addAction(UIAction { [weak self] _ in
            self?.showPlansLoadingIndicator()
            self?.viewModel.loadProducts()
        }, for: .touchUpInside)

        plansStackView.addArrangedSubview(label)
        plansStackView.addArrangedSubview(retryButton)
    }

    private func refreshSelectionDependentUI() {
        for cardView in planCardViews {
            cardView.isSelected = cardView.plan == viewModel.selectedPlan
        }

        ctaButton.configuration?.title = viewModel.ctaTitle
        disclosureLabel.text = viewModel.disclosureText
        noPaymentLabel.isHidden = !viewModel.showsNoPaymentDueNow

        rebuildTimeline()
    }

    private func rebuildTimeline() {
        timelineContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let steps = viewModel.timelineSteps else {
            timelineContainer.isHidden = true
            return
        }

        timelineContainer.isHidden = false
        for step in steps {
            timelineContainer.addArrangedSubview(
                createFeatureRow(icon: step.icon, title: step.title, description: step.detail))
        }
    }

    private func refreshALaCarteButton() {
        guard let text = viewModel.aLaCarteText else {
            aLaCarteButton.isHidden = true
            return
        }
        aLaCarteButton.isHidden = false
        let attributed = NSAttributedString(string: text, attributes: [
            .font: PapyrusDesignSystem.Typography.subheadline(),
            .foregroundColor: PapyrusDesignSystem.Colors.Dynamic.secondaryText,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])
        aLaCarteButton.setAttributedTitle(attributed, for: .normal)
    }

    private func handleALaCarteTapped() {
        guard let product = viewModel.aLaCarteProduct else { return }

        if case .lockedPath = viewModel.reason,
           let beliefSystemId = product.beliefSystemId,
           let preview = pathPreviews[beliefSystemId],
           let beliefSystem = beliefSystems.first(where: { $0.id == beliefSystemId }) {
            let price = StoreManager.shared.formattedPrice(for: product) ?? "—"
            let previewView = PathPreviewView()
            previewView.configure(with: preview, beliefSystem: beliefSystem, price: price) { [weak self] _ in
                self?.pathPreviewAnimator?.dismiss(animated: true) {
                    self?.viewModel.purchaseALaCarte()
                }
            }
            pathPreviewAnimator?.present(pathPreview: previewView, from: aLaCarteButton, animated: true)
        } else {
            viewModel.purchaseALaCarte()
        }
    }

    private func handlePurchaseState(_ state: PaywallViewModel.PurchaseState) {
        switch state {
        case .idle:
            break
        case .purchasing:
            view.isUserInteractionEnabled = false
            let loadingView = UIActivityIndicatorView(style: .large)
            loadingView.center = view.center
            loadingView.startAnimating()
            view.addSubview(loadingView)
            purchaseLoadingView = loadingView
        case .success:
            purchaseLoadingView?.removeFromSuperview()
            view.isUserInteractionEnabled = true
            notificationFeedback.notificationOccurred(.success)
            showSuccessAndDismiss()
        case .cancelled:
            purchaseLoadingView?.removeFromSuperview()
            view.isUserInteractionEnabled = true
        case .failure(let error):
            purchaseLoadingView?.removeFromSuperview()
            view.isUserInteractionEnabled = true
            notificationFeedback.notificationOccurred(.error)
            showAlert(title: "Purchase Failed", message: error.localizedDescription)
        }
    }

    private func handleRestorePurchases() {
        viewModel.restore { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(true):
                    self.notificationFeedback.notificationOccurred(.success)
                    let alert = UIAlertController(
                        title: "Purchases Restored",
                        message: "Welcome back. Everything you own is unlocked again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true)
                    })
                    self.present(alert, animated: true)
                case .success(false):
                    self.showAlert(
                        title: "Nothing to Restore",
                        message: "No previous purchases were found for this Apple Account."
                    )
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func openLegalLink(_ url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = PapyrusDesignSystem.Colors.goldLeaf
        present(safariVC, animated: true)
    }

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

    private func showSuccessAndDismiss() {
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
        checkmark.tintColor = PapyrusDesignSystem.Colors.Core.scarabGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Welcome to the Journey"
        label.font = PapyrusDesignSystem.Typography.title2()
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        successView.addSubview(checkmark)
        successView.addSubview(label)

        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: successView.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: successView.centerYAnchor, constant: -40),
            checkmark.widthAnchor.constraint(equalToConstant: 80),
            checkmark.heightAnchor.constraint(equalToConstant: 80),

            label.topAnchor.constraint(equalTo: checkmark.bottomAnchor, constant: PapyrusDesignSystem.Spacing.large),
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
