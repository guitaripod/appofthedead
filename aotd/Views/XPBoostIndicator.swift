import UIKit

class XPBoostIndicator: UIView {
    
    private let iconImageView = UIImageView()
    private let multiplierLabel = UILabel()
    private let containerView = UIView()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Container with gradient background
        containerView.backgroundColor = UIColor.systemOrange
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Icon
        iconImageView.image = UIImage(systemName: "bolt.fill")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Multiplier label
        multiplierLabel.text = "2X"
        multiplierLabel.font = .systemFont(ofSize: 14, weight: .bold)
        multiplierLabel.textColor = .white
        multiplierLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(multiplierLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            multiplierLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 4),
            multiplierLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            multiplierLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            containerView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Add pulsing animation
        addPulsingAnimation()
    }
    
    private func addPulsingAnimation() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.1
        scaleAnimation.duration = 1.0
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity
        containerView.layer.add(scaleAnimation, forKey: "pulse")
    }
    
    func updateMultiplier(_ multiplier: Int) {
        multiplierLabel.text = "\(multiplier)X"
    }
}