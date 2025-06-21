import UIKit

class PathPreviewViewController: UIViewController {
    private let beliefSystem: BeliefSystem
    private let progress: Progress?
    private let pathPreview: PathPreview?
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statsContainer = UIView()
    
    init(beliefSystem: BeliefSystem, progress: Progress?, pathPreview: PathPreview?) {
        self.beliefSystem = beliefSystem
        self.progress = progress
        self.pathPreview = pathPreview
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate the required height based on content
        let targetSize = CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        preferredContentSize = CGSize(width: 320, height: size.height)
    }
    
    private func setupViews() {
        view.backgroundColor = PapyrusDesignSystem.Colors.background
        
        // Container view with padding
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Icon and title container
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(hex: beliefSystem.color)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.font = PapyrusDesignSystem.Typography.title2()
        titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.font = PapyrusDesignSystem.Typography.body()
        descriptionLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stats container
        statsContainer.backgroundColor = PapyrusDesignSystem.Colors.secondaryBackground
        statsContainer.layer.cornerRadius = 12
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views
        headerContainer.addSubview(iconImageView)
        headerContainer.addSubview(titleLabel)
        containerView.addSubview(headerContainer)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(statsContainer)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container view fills the view with padding
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            // Header container
            headerContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 40),
            
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Stats container
            statsContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            statsContainer.heightAnchor.constraint(equalToConstant: 80),
            statsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func configure() {
        // Icon and title
        iconImageView.image = IconProvider.beliefSystemIcon(for: beliefSystem.icon, color: UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf, size: 40)
        titleLabel.text = beliefSystem.name
        
        // Description
        descriptionLabel.text = beliefSystem.description
        
        // Stats
        setupStatsView()
    }
    
    private func setupStatsView() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor)
        ])
        
        // Lessons count
        let lessonsView = createStatView(
            value: "\(beliefSystem.lessons.count)",
            label: "Lessons",
            icon: UIImage(systemName: "book.fill")
        )
        
        // Total XP
        let totalXP = beliefSystem.totalXP
        let xpView = createStatView(
            value: "\(totalXP)",
            label: "Total XP",
            icon: UIImage(systemName: "star.fill")
        )
        
        // Progress indicator
        let currentXP = progress?.earnedXP ?? 0
        let progressPercentage = beliefSystem.totalXP > 0 ? Float(currentXP) / Float(beliefSystem.totalXP) * 100 : 0
        let progressView = createStatView(
            value: "\(Int(progressPercentage))%",
            label: "Progress",
            icon: UIImage(systemName: "chart.pie.fill")
        )
        
        stackView.addArrangedSubview(lessonsView)
        stackView.addArrangedSubview(xpView)
        stackView.addArrangedSubview(progressView)
    }
    
    private func createStatView(value: String, label: String, icon: UIImage?) -> UIView {
        let container = UIView()
        
        let iconView = UIImageView(image: icon)
        iconView.tintColor = UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = PapyrusDesignSystem.Typography.title3().withSize(18)
        valueLabel.textColor = PapyrusDesignSystem.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = PapyrusDesignSystem.Typography.caption1()
        titleLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            valueLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
}