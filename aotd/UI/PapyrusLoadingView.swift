import UIKit


final class PapyrusLoadingView: UIView {
    
    
    
    enum LoadingStyle {
        case oracle
        case standard
        case download
    }
    
    
    
    private let style: LoadingStyle
    private let deityColor: UIColor?
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.headline(weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.body()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = PapyrusDesignSystem.Spacing.medium
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    
    init(style: LoadingStyle = .standard, deityColor: UIColor? = nil) {
        self.style = style
        self.deityColor = deityColor
        super.init(frame: .zero)
        setupUI()
        configureForStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerStackView)
        
        
        if style == .oracle || style == .download {
            containerStackView.addArrangedSubview(iconImageView)
        }
        
        containerStackView.addArrangedSubview(loadingIndicator)
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(subtitleLabel)
        
        if style == .download {
            containerStackView.addArrangedSubview(progressView)
            containerStackView.addArrangedSubview(progressLabel)
        }
        
        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: PapyrusDesignSystem.Spacing.large),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -PapyrusDesignSystem.Spacing.large),
            
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            progressView.widthAnchor.constraint(equalToConstant: 200),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    private func configureForStyle() {
        switch style {
        case .oracle:
            iconImageView.image = UIImage(systemName: "sparkles")
            iconImageView.tintColor = deityColor ?? PapyrusDesignSystem.Colors.goldLeaf
            loadingIndicator.color = deityColor ?? PapyrusDesignSystem.Colors.goldLeaf
            titleLabel.text = "Consulting the Oracle..."
            subtitleLabel.text = "Divine wisdom is being channeled"
            titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
            subtitleLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
            
        case .standard:
            loadingIndicator.color = PapyrusDesignSystem.Colors.goldLeaf
            titleLabel.text = "Loading..."
            subtitleLabel.isHidden = true
            titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
            
        case .download:
            iconImageView.image = UIImage(systemName: "arrow.down.circle.fill")
            iconImageView.tintColor = deityColor ?? PapyrusDesignSystem.Colors.goldLeaf
            loadingIndicator.color = deityColor ?? PapyrusDesignSystem.Colors.goldLeaf
            titleLabel.text = "Downloading Oracle Model"
            subtitleLabel.text = "Preparing divine connection..."
            progressView.progressTintColor = deityColor ?? PapyrusDesignSystem.Colors.goldLeaf
            progressView.trackTintColor = PapyrusDesignSystem.Colors.aged.withAlphaComponent(0.3)
            titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
            subtitleLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
            progressLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        }
    }
    
    
    
    func startAnimating() {
        loadingIndicator.startAnimating()
        
        if style == .oracle {
            
            UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.iconImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.iconImageView.alpha = 0.8
            })
        }
    }
    
    func stopAnimating() {
        loadingIndicator.stopAnimating()
        
        if style == .oracle {
            iconImageView.layer.removeAllAnimations()
            iconImageView.transform = .identity
            iconImageView.alpha = 1.0
        }
    }
    
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func updateSubtitle(_ subtitle: String) {
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = false
    }
    
    func updateProgress(_ progress: Float, withText text: String? = nil) {
        guard style == .download else { return }
        
        progressView.isHidden = false
        progressView.setProgress(progress, animated: true)
        
        if let text = text {
            progressLabel.text = text
            progressLabel.isHidden = false
        }
    }
    
    func setDeityColor(_ color: UIColor) {
        iconImageView.tintColor = color
        loadingIndicator.color = color
        progressView.progressTintColor = color
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            
            titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
            subtitleLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
            progressLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        }
    }
}