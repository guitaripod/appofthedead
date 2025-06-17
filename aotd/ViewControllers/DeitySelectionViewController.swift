import UIKit

final class DeitySelectionViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private let dismissButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let deities: [OracleViewModel.Deity]
    private let onSelection: (OracleViewModel.Deity) -> Void
    private let currentDeity: OracleViewModel.Deity?
    
    // MARK: - Initialization
    
    init(deities: [OracleViewModel.Deity], currentDeity: OracleViewModel.Deity?, onSelection: @escaping (OracleViewModel.Deity) -> Void) {
        self.deities = deities
        self.currentDeity = currentDeity
        self.onSelection = onSelection
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Background
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.alpha = 0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
        
        // Container
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.cornerRadius = 24
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.Papyrus.gold.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        containerView.alpha = 0
        view.addSubview(containerView)
        
        // Title
        titleLabel.text = "Choose Your Oracle"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(DeityCell.self, forCellWithReuseIdentifier: "DeityCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(collectionView)
        
        // Dismiss button
        dismissButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        dismissButton.tintColor = UIColor.Papyrus.secondaryText
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dismissButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 340),
            containerView.heightAnchor.constraint(equalToConstant: 500),
            
            // Dismiss button
            dismissButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Collection view
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTapped() {
        animateOut()
    }
    
    @objc private func dismissTapped() {
        animateOut()
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.backgroundView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension DeitySelectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return deities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeityCell", for: indexPath) as! DeityCell
        let deity = deities[indexPath.item]
        cell.configure(with: deity, isSelected: deity.name == currentDeity?.name)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension DeitySelectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDeity = deities[indexPath.item]
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        animateOut { [weak self] in
            self?.onSelection(selectedDeity)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DeitySelectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 * 3 // left, right, and middle spacing
        let availableWidth = collectionView.bounds.width - padding
        let itemWidth = availableWidth / 2
        return CGSize(width: itemWidth, height: 140)
    }
}

// MARK: - DeityCell

private class DeityCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let traditionLabel = UILabel()
    private let selectionIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        // Container
        containerView.backgroundColor = UIColor.Papyrus.beige
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Name
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Tradition
        traditionLabel.font = .systemFont(ofSize: 12)
        traditionLabel.textColor = UIColor.Papyrus.secondaryText
        traditionLabel.textAlignment = .center
        traditionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(traditionLabel)
        
        // Selection indicator
        selectionIndicator.backgroundColor = UIColor.Papyrus.gold
        selectionIndicator.layer.cornerRadius = 14
        selectionIndicator.isHidden = true
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(selectionIndicator)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            traditionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            traditionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            traditionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            selectionIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -7),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -7),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 28),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    func configure(with deity: OracleViewModel.Deity, isSelected: Bool) {
        nameLabel.text = deity.name
        nameLabel.textColor = deity.uiColor
        traditionLabel.text = deity.tradition
        
        if let image = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
            iconImageView.image = image.withConfiguration(config)
            iconImageView.tintColor = deity.uiColor
        }
        
        selectionIndicator.isHidden = !isSelected
        containerView.layer.borderColor = isSelected ? UIColor.Papyrus.gold.cgColor : UIColor.Papyrus.aged.cgColor
        containerView.layer.borderWidth = isSelected ? 3 : 2
        
        if isSelected {
            containerView.backgroundColor = UIColor.Papyrus.beige.withAlphaComponent(0.9)
        } else {
            containerView.backgroundColor = UIColor.Papyrus.beige
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectionIndicator.isHidden = true
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.backgroundColor = UIColor.Papyrus.beige
    }
}