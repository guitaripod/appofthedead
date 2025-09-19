import UIKit

class TransparentCardCell: UITableViewCell {
    
    
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.Papyrus.cardBackground.withAlphaComponent(0.8)
        view.layer.cornerRadius = 12
        return view
    }()
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        
        
        let heightConstraint = containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
    
    
    
    func configure(text: String, detailText: String? = nil, textColor: UIColor? = nil, accessoryType: UITableViewCell.AccessoryType = .none) {
        
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = text
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = textColor ?? UIColor.Papyrus.primaryText
        containerView.addSubview(titleLabel)
        
        
        if let detailText = detailText {
            let detailLabel = UILabel()
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            detailLabel.text = detailText
            detailLabel.font = .systemFont(ofSize: 17)
            detailLabel.textColor = UIColor.Papyrus.secondaryText
            detailLabel.textAlignment = .right
            containerView.addSubview(detailLabel)
            
            NSLayoutConstraint.activate([
                detailLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                detailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: accessoryType == .disclosureIndicator ? -32 : -16)
            ])
        }
        
        
        if accessoryType == .disclosureIndicator {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.translatesAutoresizingMaskIntoConstraints = false
            chevron.tintColor = UIColor.Papyrus.tertiaryText
            chevron.contentMode = .scaleAspectFit
            containerView.addSubview(chevron)
            
            NSLayoutConstraint.activate([
                chevron.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                chevron.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                chevron.widthAnchor.constraint(equalToConstant: 12),
                chevron.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -60)
        ])
    }
    
    func addSwitch(isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.isOn = isOn
        switchControl.onTintColor = UIColor.Papyrus.gold
        
        switchControl.addAction(UIAction { _ in
            onToggle(switchControl.isOn)
        }, for: .valueChanged)
        
        containerView.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            switchControl.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            switchControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    
    
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                self.containerView.alpha = 0.7
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
                self.containerView.alpha = 1.0
            }
        }
    }
}



class TransparentSectionHeaderView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.Papyrus.secondaryText
        return label
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        
        titleLabel.text = title.uppercased()
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}