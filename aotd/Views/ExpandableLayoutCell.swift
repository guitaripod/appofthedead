import UIKit

final class ExpandableLayoutCell: UITableViewCell {
    
    // MARK: - Properties
    
    private var isExpanded = false
    private var onLayoutSelected: ((ViewLayoutPreference) -> Void)?
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "View Layout"
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private let currentValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .right
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.Papyrus.cardBackground.withAlphaComponent(0.8)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let expandedContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.Papyrus.cardBackground.withAlphaComponent(0.8)
        view.layer.cornerRadius = 12
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    private let gridButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let listButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        contentView.addSubview(expandedContainer)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(currentValueLabel)
        containerView.addSubview(chevronImageView)
        
        expandedContainer.addSubview(gridButton)
        expandedContainer.addSubview(listButton)
        
        setupConstraints()
        setupButtons()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Chevron
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Current value label
            currentValueLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            currentValueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            currentValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            
            // Expanded container
            expandedContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            expandedContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            expandedContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            expandedContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Grid button
            gridButton.leadingAnchor.constraint(equalTo: expandedContainer.leadingAnchor),
            gridButton.trailingAnchor.constraint(equalTo: expandedContainer.trailingAnchor),
            gridButton.topAnchor.constraint(equalTo: expandedContainer.topAnchor),
            
            // List button
            listButton.leadingAnchor.constraint(equalTo: expandedContainer.leadingAnchor),
            listButton.trailingAnchor.constraint(equalTo: expandedContainer.trailingAnchor),
            listButton.topAnchor.constraint(equalTo: gridButton.bottomAnchor),
            listButton.bottomAnchor.constraint(equalTo: expandedContainer.bottomAnchor)
        ])
        
        // Add flexible height constraints for buttons
        let gridHeightConstraint = gridButton.heightAnchor.constraint(equalToConstant: 60)
        gridHeightConstraint.priority = .defaultHigh
        gridHeightConstraint.isActive = true
        
        let listHeightConstraint = listButton.heightAnchor.constraint(equalToConstant: 60)
        listHeightConstraint.priority = .defaultHigh
        listHeightConstraint.isActive = true
    }
    
    private func setupButtons() {
        setupLayoutButton(gridButton, layout: .grid)
        setupLayoutButton(listButton, layout: .list)
        
        gridButton.addTarget(self, action: #selector(gridTapped), for: .touchUpInside)
        listButton.addTarget(self, action: #selector(listTapped), for: .touchUpInside)
    }
    
    private func setupLayoutButton(_ button: UIButton, layout: ViewLayoutPreference) {
        // Icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = layout == .grid ? 
            UIImage(systemName: "square.grid.2x2.fill") : 
            UIImage(systemName: "list.bullet")
        
        // Title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = layout.title
        titleLabel.font = .systemFont(ofSize: 16)
        
        // Checkmark
        let checkmarkImageView = UIImageView()
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = UIColor.Papyrus.gold
        checkmarkImageView.tag = 100 // Use tag to find it later
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            checkmarkImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Store layout reference
        button.tag = layout == .grid ? 1 : 2
    }
    
    // MARK: - Configuration
    
    func configure(currentLayout: ViewLayoutPreference, onSelection: @escaping (ViewLayoutPreference) -> Void) {
        currentValueLabel.text = currentLayout.title
        onLayoutSelected = onSelection
        updateSelection(currentLayout)
        
        // Ensure proper initial state
        isExpanded = false
        containerView.isHidden = false
        containerView.alpha = 1
        expandedContainer.isHidden = true
        expandedContainer.alpha = 0
        expandedContainer.transform = .identity
        chevronImageView.transform = .identity
    }
    
    private func updateSelection(_ layout: ViewLayoutPreference) {
        // Update colors and checkmarks
        let isGrid = layout == .grid
        
        // Grid button
        if let gridIcon = gridButton.subviews.first as? UIImageView,
           let gridLabel = gridButton.subviews.first(where: { $0 is UILabel }) as? UILabel,
           let gridCheck = gridButton.viewWithTag(100) {
            gridIcon.tintColor = isGrid ? UIColor.Papyrus.gold : UIColor.Papyrus.secondaryText
            gridLabel.textColor = isGrid ? UIColor.Papyrus.gold : UIColor.Papyrus.primaryText
            gridLabel.font = isGrid ? .boldSystemFont(ofSize: 16) : .systemFont(ofSize: 16)
            gridCheck.isHidden = !isGrid
        }
        
        // List button
        if let listIcon = listButton.subviews.first as? UIImageView,
           let listLabel = listButton.subviews.first(where: { $0 is UILabel }) as? UILabel,
           let listCheck = listButton.viewWithTag(100) {
            listIcon.tintColor = !isGrid ? UIColor.Papyrus.gold : UIColor.Papyrus.secondaryText
            listLabel.textColor = !isGrid ? UIColor.Papyrus.gold : UIColor.Papyrus.primaryText
            listLabel.font = !isGrid ? .boldSystemFont(ofSize: 16) : .systemFont(ofSize: 16)
            listCheck.isHidden = isGrid
        }
    }
    
    // MARK: - Actions
    
    @objc private func gridTapped() {
        onLayoutSelected?(.grid)
        currentValueLabel.text = ViewLayoutPreference.grid.title
        updateSelection(.grid)
        animateCollapse()
    }
    
    @objc private func listTapped() {
        onLayoutSelected?(.list)
        currentValueLabel.text = ViewLayoutPreference.list.title
        updateSelection(.list)
        animateCollapse()
    }
    
    // MARK: - Animation
    
    func toggleExpansion() {
        if isExpanded {
            animateCollapse()
        } else {
            animateExpand()
        }
    }
    
    private func animateExpand() {
        isExpanded = true
        
        // Prepare for animation
        expandedContainer.isHidden = false
        expandedContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Find table view and reload row height
        var currentView: UIView? = superview
        while currentView != nil && !(currentView is UITableView) {
            currentView = currentView?.superview
        }
        
        if let tableView = currentView as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.expandedContainer.alpha = 1
            self.expandedContainer.transform = .identity
            self.containerView.alpha = 0
            self.chevronImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        } completion: { _ in
            self.containerView.isHidden = true
        }
    }
    
    private func animateCollapse() {
        isExpanded = false
        
        // Prepare for animation
        containerView.isHidden = false
        
        // Find table view and reload row height
        var currentView: UIView? = superview
        while currentView != nil && !(currentView is UITableView) {
            currentView = currentView?.superview
        }
        
        if let tableView = currentView as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.expandedContainer.alpha = 0
            self.expandedContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.containerView.alpha = 1
            self.chevronImageView.transform = .identity
        } completion: { _ in
            self.expandedContainer.isHidden = true
        }
    }
    
    // MARK: - Height
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let height: CGFloat = isExpanded ? 136 : 52 // 52 to match other cells with padding
        return CGSize(width: targetSize.width, height: height)
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset to collapsed state
        isExpanded = false
        containerView.isHidden = false
        containerView.alpha = 1
        expandedContainer.isHidden = true
        expandedContainer.alpha = 0
        expandedContainer.transform = .identity
        chevronImageView.transform = .identity
    }
}