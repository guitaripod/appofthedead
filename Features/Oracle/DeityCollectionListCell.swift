import UIKit

final class DeityCollectionListCell: UICollectionViewCell {
    
    
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.Papyrus.aged.cgColor
        view.backgroundColor = UIColor.Papyrus.cardBackground
        
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        
        return view
    }()
    
    private lazy var avatarContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor.Papyrus.primaryText
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private lazy var roleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.Papyrus.secondaryText
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var traditionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var selectionIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = UIColor.Papyrus.gold
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
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
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        avatarContainerView.addSubview(avatarImageView)
        
        containerView.addSubview(avatarContainerView)
        containerView.addSubview(textStackView)
        containerView.addSubview(traditionLabel)
        containerView.addSubview(selectionIndicator)
        
        NSLayoutConstraint.activate([
            
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),
            
            
            avatarContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarContainerView.widthAnchor.constraint(equalToConstant: 48),
            avatarContainerView.heightAnchor.constraint(equalToConstant: 48),
            
            
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainerView.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarContainerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 28),
            avatarImageView.heightAnchor.constraint(equalToConstant: 28),
            
            
            textStackView.leadingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor, constant: 12),
            textStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textStackView.trailingAnchor.constraint(lessThanOrEqualTo: traditionLabel.leadingAnchor, constant: -8),
            
            
            traditionLabel.trailingAnchor.constraint(equalTo: selectionIndicator.leadingAnchor, constant: -12),
            traditionLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            traditionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            selectionIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    
    
    func configure(with deity: OracleViewModel.Deity, isSelected: Bool) {
        nameLabel.text = deity.name
        roleLabel.text = deity.role
        traditionLabel.text = deity.tradition.uppercased()
        
        
        let deityColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
        traditionLabel.textColor = deityColor.withAlphaComponent(0.8)
        
        
        avatarContainerView.backgroundColor = deityColor.withAlphaComponent(0.9)
        
        let iconName = deity.avatar
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        
        if let image = UIImage(systemName: iconName) {
            avatarImageView.image = image.withConfiguration(config)
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")?.withConfiguration(config)
        }
        avatarImageView.tintColor = .white
        
        
        selectionIndicator.isHidden = !isSelected
        if isSelected {
            containerView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            containerView.layer.borderWidth = 2
            containerView.backgroundColor = UIColor.Papyrus.cardBackground.withAlphaComponent(0.95)
            
            
            containerView.layer.shadowColor = UIColor.Papyrus.gold.cgColor
            containerView.layer.shadowOpacity = 0.2
            containerView.layer.shadowRadius = 10
        } else {
            containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            containerView.layer.borderWidth = 1
            containerView.backgroundColor = UIColor.Papyrus.cardBackground
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOpacity = 0.1
            containerView.layer.shadowRadius = 6
        }
        
        
        if avatarContainerView.bounds.width > 0 {
            updateAvatarGradient(with: deityColor)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 12).cgPath
        
        
        if avatarContainerView.bounds.width > 0, let deityColor = avatarContainerView.backgroundColor {
            updateAvatarGradient(with: deityColor)
        }
    }
    
    private func updateAvatarGradient(with deityColor: UIColor) {
        
        avatarContainerView.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = avatarContainerView.bounds
        gradientLayer.cornerRadius = 24
        gradientLayer.colors = [
            deityColor.withAlphaComponent(0.8).cgColor,
            deityColor.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        avatarContainerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        roleLabel.text = nil
        traditionLabel.text = nil
        selectionIndicator.isHidden = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        
        
        avatarContainerView.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 6
    }
    
    
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.1) {
                    self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                    self.containerView.layer.shadowOpacity = 0.15
                }
            } else {
                UIView.animate(withDuration: 0.1) {
                    self.containerView.transform = .identity
                    self.containerView.layer.shadowOpacity = 0.1
                }
            }
        }
    }
}