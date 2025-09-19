import UIKit

final class HomeHeaderView: UICollectionReusableView {
    
    
    
    weak var delegate: HomeHeaderViewDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "App of the Dead"
        
        if let papyrusFont = UIFont(name: "Papyrus", size: 34) {
            label.font = papyrusFont
        } else {
            label.font = .systemFont(ofSize: 34, weight: .bold)
        }
        label.textColor = UIColor.Papyrus.primaryText
        label.layer.shadowColor = UIColor.Papyrus.gold.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.3
        label.layer.shadowRadius = 2
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Explore afterlife beliefs across cultures"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor.Papyrus.secondaryText
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
        button.backgroundColor = UIColor.Papyrus.aged
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.Papyrus.gold.cgColor
        button.tintColor = UIColor.Papyrus.primaryText
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
        view.backgroundColor = UIColor.Papyrus.cardBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.Papyrus.aged.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
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
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.Papyrus.gold
        label.text = "0"
        return label
    }()
    
    private lazy var xpDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "XP"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.Papyrus.secondaryText
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
        view.backgroundColor = UIColor.Papyrus.separator
        view.widthAnchor.constraint(equalToConstant: 1.5).isActive = true
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
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.Papyrus.tombRed
        label.text = "0"
        return label
    }()
    
    private lazy var streakDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Day Streak"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.Papyrus.secondaryText
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
        stack.spacing = 10
        stack.layoutMargins = UIEdgeInsets(top: 6, left: 20, bottom: 8, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupUI() {
        backgroundColor = UIColor.Papyrus.background
        
        addSubview(mainStackView)
        statsContainer.addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            statsContainer.heightAnchor.constraint(equalToConstant: 56),
            
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40),
            
            statsStackView.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor)
        ])
    }
    
    
    
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
    
    
    
    @objc private func profileButtonTapped() {
        delegate?.profileButtonTapped()
    }
}



protocol HomeHeaderViewDelegate: AnyObject {
    func profileButtonTapped()
}