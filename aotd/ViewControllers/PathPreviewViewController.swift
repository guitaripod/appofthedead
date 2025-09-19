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
    private let topicsContainer = UIView()
    
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
        
        
        let targetSize = CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        preferredContentSize = CGSize(width: 320, height: size.height)
    }
    
    private func setupViews() {
        
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                PapyrusDesignSystem.Colors.Core.darkCard : 
                PapyrusDesignSystem.Colors.Dynamic.background
        }
        
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(hex: beliefSystem.color)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        
        titleLabel.font = PapyrusDesignSystem.Typography.title2()
        titleLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : PapyrusDesignSystem.Colors.primaryText
        }
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        descriptionLabel.font = PapyrusDesignSystem.Typography.body()
        descriptionLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(white: 0.7, alpha: 1.0) : 
                PapyrusDesignSystem.Colors.secondaryText
        }
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        statsContainer.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        statsContainer.layer.cornerRadius = 12
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        
        topicsContainer.backgroundColor = PapyrusDesignSystem.Colors.Core.aged.withAlphaComponent(0.3)
        topicsContainer.layer.cornerRadius = 12
        topicsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        
        headerContainer.addSubview(iconImageView)
        headerContainer.addSubview(titleLabel)
        containerView.addSubview(headerContainer)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(statsContainer)
        containerView.addSubview(topicsContainer)
        
        
        NSLayoutConstraint.activate([
            
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            
            headerContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 40),
            
            
            iconImageView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            
            descriptionLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            
            statsContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            statsContainer.heightAnchor.constraint(equalToConstant: 80),
            
            
            topicsContainer.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 20),
            topicsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topicsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topicsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func configure() {
        
        iconImageView.image = IconProvider.beliefSystemIcon(for: beliefSystem.icon, color: UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf, size: 40)
        titleLabel.text = beliefSystem.name
        
        
        descriptionLabel.text = beliefSystem.description
        
        
        setupStatsView()
        
        
        setupTopicsView()
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
        
        
        let lessonsView = createStatView(
            value: "\(beliefSystem.lessons.count)",
            label: "Lessons",
            icon: UIImage(systemName: "book.fill")
        )
        
        
        let totalXP = beliefSystem.totalXP
        let xpView = createStatView(
            value: "\(totalXP)",
            label: "Total XP",
            icon: UIImage(systemName: "star.fill")
        )
        
        
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
        valueLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : PapyrusDesignSystem.Colors.primaryText
        }
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = PapyrusDesignSystem.Typography.caption1()
        titleLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(white: 0.6, alpha: 1.0) : 
                PapyrusDesignSystem.Colors.secondaryText
        }
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
    
    private func setupTopicsView() {
        let titleLabel = UILabel()
        titleLabel.text = "Key Topics"
        titleLabel.font = PapyrusDesignSystem.Typography.headline()
        titleLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : PapyrusDesignSystem.Colors.primaryText
        }
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let topicsStackView = UIStackView()
        topicsStackView.axis = .vertical
        topicsStackView.spacing = 8
        topicsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        topicsContainer.addSubview(titleLabel)
        topicsContainer.addSubview(topicsStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topicsContainer.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: topicsContainer.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: topicsContainer.trailingAnchor, constant: -12),
            
            topicsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            topicsStackView.leadingAnchor.constraint(equalTo: topicsContainer.leadingAnchor, constant: 12),
            topicsStackView.trailingAnchor.constraint(equalTo: topicsContainer.trailingAnchor, constant: -12),
            topicsStackView.bottomAnchor.constraint(equalTo: topicsContainer.bottomAnchor, constant: -12)
        ])
        
        
        let topics = pathPreview?.keyTopics ?? []
        for (index, topic) in topics.prefix(3).enumerated() {
            let topicView = createTopicView(topic: topic, index: index + 1)
            topicsStackView.addArrangedSubview(topicView)
        }
        
        
        if topics.isEmpty {
            for (index, lesson) in beliefSystem.lessons.prefix(3).enumerated() {
                let topicView = createTopicView(topic: lesson.title, index: index + 1)
                topicsStackView.addArrangedSubview(topicView)
            }
        }
    }
    
    private func createTopicView(topic: String, index: Int) -> UIView {
        let container = UIView()
        
        let numberLabel = UILabel()
        numberLabel.text = "\(index)."
        numberLabel.font = PapyrusDesignSystem.Typography.body().withSize(14)
        numberLabel.textColor = UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let topicLabel = UILabel()
        topicLabel.text = topic
        topicLabel.font = PapyrusDesignSystem.Typography.body().withSize(14)
        topicLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(white: 0.85, alpha: 1.0) : 
                PapyrusDesignSystem.Colors.primaryText
        }
        topicLabel.numberOfLines = 2  
        topicLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(numberLabel)
        container.addSubview(topicLabel)
        
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: container.topAnchor),
            numberLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 24),
            
            topicLabel.topAnchor.constraint(equalTo: container.topAnchor),
            topicLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor),
            topicLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topicLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
}