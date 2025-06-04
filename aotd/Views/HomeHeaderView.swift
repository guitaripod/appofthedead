import UIKit

final class HomeHeaderView: UICollectionReusableView {
    
    // MARK: - Properties
    
    weak var delegate: HomeHeaderViewDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "App of the Dead"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Explore afterlife beliefs across cultures"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var headerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    private lazy var profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 20
        button.tintColor = .label
        button.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var topRowStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerStackView, profileButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    
    private lazy var statsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var xpIconLabel: UILabel = {
        let label = UILabel()
        label.text = "⭐"
        label.font = .systemFont(ofSize: 24)
        return label
    }()
    
    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.text = "0"
        return label
    }()
    
    private lazy var xpDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "XP"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var xpStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [xpIconLabel, xpLabel, xpDescriptionLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.setCustomSpacing(4, after: xpLabel)
        return stack
    }()
    
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.widthAnchor.constraint(equalToConstant: 1).isActive = true
        view.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return view
    }()
    
    private lazy var streakIconLabel: UILabel = {
        let label = UILabel()
        label.text = "🔥"
        label.font = .systemFont(ofSize: 24)
        return label
    }()
    
    private lazy var streakLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.text = "0"
        return label
    }()
    
    private lazy var streakDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Day Streak"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var streakStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [streakIconLabel, streakLabel, streakDescriptionLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.setCustomSpacing(4, after: streakLabel)
        return stack
    }()
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [xpStackView, divider, streakStackView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [topRowStackView, statsContainer])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(mainStackView)
        statsContainer.addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            statsContainer.heightAnchor.constraint(equalToConstant: 48),
            
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40),
            
            statsStackView.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(xp: Int, streak: Int, isSignedIn: Bool = false, userName: String? = nil) {
        xpLabel.text = "\(xp)"
        streakLabel.text = "\(streak)"
        
        if isSignedIn {
            let image = UIImage(systemName: "person.fill")
            profileButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "person.badge.plus")
            profileButton.setImage(image, for: .normal)
        }
        
        if streak > 0 {
            UIView.animate(withDuration: 0.3) {
                self.streakIconLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.streakIconLabel.transform = .identity
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func profileButtonTapped() {
        delegate?.profileButtonTapped()
    }
}

// MARK: - HomeHeaderViewDelegate

protocol HomeHeaderViewDelegate: AnyObject {
    func profileButtonTapped()
}