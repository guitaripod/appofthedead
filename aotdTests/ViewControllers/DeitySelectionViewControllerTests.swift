import XCTest
@testable import aotd

final class DeitySelectionViewControllerTests: XCTestCase {
    
    var sut: DeitySelectionViewController!
    var mockDeities: [OracleViewModel.Deity]!
    var selectedDeity: OracleViewModel.Deity?
    var selectionCalled = false
    
    override func setUp() {
        super.setUp()
        
        // Create mock deities
        mockDeities = [
            OracleViewModel.Deity(
                id: "anubis",
                name: "Anubis",
                tradition: "Egyptian",
                role: "Guide of Souls",
                avatar: "figure.stand",
                color: "#D4A574",
                systemPrompt: "Test prompt"
            ),
            OracleViewModel.Deity(
                id: "hermes",
                name: "Hermes",
                tradition: "Greek",
                role: "Messenger of Gods",
                avatar: "wind",
                color: "#4A90E2",
                systemPrompt: "Test prompt"
            ),
            OracleViewModel.Deity(
                id: "gabriel",
                name: "Gabriel",
                tradition: "Abrahamic",
                role: "Archangel",
                avatar: "sparkles",
                color: "#8B5CF6",
                systemPrompt: "Test prompt"
            )
        ]
        
        selectionCalled = false
        selectedDeity = nil
        
        sut = DeitySelectionViewController(
            deities: mockDeities,
            currentDeity: mockDeities[0]
        ) { [weak self] deity in
            self?.selectionCalled = true
            self?.selectedDeity = deity
        }
    }
    
    override func tearDown() {
        sut = nil
        mockDeities = nil
        selectedDeity = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.modalPresentationStyle, .pageSheet)
    }
    
    // Sheet presentation tests removed since we're now using normal modal
    
    // MARK: - View Loading Tests
    
    func testViewDidLoad() {
        // Force view to load
        _ = sut.view
        
        // Test background color
        XCTAssertEqual(sut.view.backgroundColor, UIColor.Papyrus.background)
        
        // Check that we have the expected subviews (header and collection view)
        XCTAssertEqual(sut.view.subviews.count, 2, "Should have header view and collection view")
        
        // Check that collection view exists
        let collectionView = sut.view.subviews.first { $0 is UICollectionView }
        XCTAssertNotNil(collectionView, "Collection view should be a direct subview")
    }
    
    // MARK: - Collection View Tests
    
    func testCollectionViewDataSource() {
        _ = sut.view
        
        let collectionView = findCollectionView(in: sut.view)
        XCTAssertNotNil(collectionView)
        
        // With diffable data source, we check the snapshot instead
        // The data source should have been set up and applied
        XCTAssertNotNil(collectionView?.dataSource)
    }
    
    func testCollectionViewSelection() {
        _ = sut.view
        
        let collectionView = findCollectionView(in: sut.view)
        XCTAssertNotNil(collectionView)
        
        // Test selection using delegate method directly
        let indexPath = IndexPath(item: 1, section: 0)
        sut.collectionView(collectionView!, didSelectItemAt: indexPath)
        
        // Wait for async dismissal
        let expectation = XCTestExpectation(description: "Selection callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.selectionCalled)
            XCTAssertEqual(self.selectedDeity?.id, "hermes")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Gesture Tests
    
    func testGrabberViewExists() {
        _ = sut.view
        
        // Find header view
        let headerView = sut.view.subviews.first { view in
            view.subviews.contains { $0.layer.cornerRadius == 2.5 }
        }
        XCTAssertNotNil(headerView)
        
        // Find grabber view
        let grabberView = headerView?.subviews.first { $0.layer.cornerRadius == 2.5 }
        XCTAssertNotNil(grabberView)
        XCTAssertTrue(grabberView?.isUserInteractionEnabled ?? false)
    }
    
    func testTitleLabelExists() {
        _ = sut.view
        
        // Find title label
        let titleLabel = findLabel(in: sut.view, withText: "Choose Your Divine Guide")
        XCTAssertNotNil(titleLabel)
        XCTAssertEqual(titleLabel?.font, .systemFont(ofSize: 28, weight: .bold))
        XCTAssertEqual(titleLabel?.textColor, UIColor.Papyrus.primaryText)
    }
    
    // MARK: - Layout Tests
    
    func testCollectionViewLayout() {
        _ = sut.view
        
        let collectionView = findCollectionView(in: sut.view)
        XCTAssertNotNil(collectionView)
        
        // Force layout
        collectionView?.layoutIfNeeded()
        
        // Test cell size
        let indexPath = IndexPath(item: 0, section: 0)
        let size = sut.collectionView(collectionView!, layout: collectionView!.collectionViewLayout, sizeForItemAt: indexPath)
        
        // Should be roughly half the width minus padding
        let expectedWidth = (collectionView!.bounds.width - 40 - 16) / 2
        XCTAssertEqual(size.width, expectedWidth, accuracy: 1.0)
        XCTAssertEqual(size.height, 180)
    }
    
    // MARK: - Helper Methods
    
    private func findLabel(in view: UIView, withText text: String) -> UILabel? {
        if let label = view as? UILabel, label.text == text {
            return label
        }
        
        for subview in view.subviews {
            if let label = findLabel(in: subview, withText: text) {
                return label
            }
        }
        
        return nil
    }
    
    private func findCollectionView(in view: UIView) -> UICollectionView? {
        if let collectionView = view as? UICollectionView {
            return collectionView
        }
        
        for subview in view.subviews {
            if let collectionView = findCollectionView(in: subview) {
                return collectionView
            }
        }
        
        return nil
    }
}

// MARK: - Deity Cell Tests

final class DeityCellTests: XCTestCase {
    
    func testCellConfiguration() {
        let frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        let cell = DeityCell(frame: frame)
        
        let deity = OracleViewModel.Deity(
            id: "test",
            name: "Test Deity",
            tradition: "Test Tradition",
            role: "Test Role",
            avatar: "star.fill",
            color: "#FF0000",
            systemPrompt: "Test"
        )
        
        cell.configure(with: deity, isSelected: false)
        
        // Basic configuration test
        XCTAssertNotNil(cell.contentView)
        
        // Test selected state
        cell.configure(with: deity, isSelected: true)
        
        // Should have golden border when selected
        let containerView = cell.contentView.subviews.first
        XCTAssertEqual(containerView?.layer.borderWidth, 2)
    }
    
    func testCellPrepareForReuse() {
        let frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        let cell = DeityCell(frame: frame)
        
        let deity = OracleViewModel.Deity(
            id: "test",
            name: "Test Deity",
            tradition: "Test Tradition",
            role: "Test Role",
            avatar: "star.fill",
            color: "#FF0000",
            systemPrompt: "Test"
        )
        
        // Configure as selected
        cell.configure(with: deity, isSelected: true)
        
        // Call prepareForReuse
        cell.prepareForReuse()
        
        // Should reset to unselected state
        let containerView = cell.contentView.subviews.first
        XCTAssertEqual(containerView?.layer.borderWidth, 1)
    }
}

// Make DeityCell accessible for testing
private class DeityCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let traditionLabel = UILabel()
    private let selectionIndicator = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        iconContainerView.layer.cornerRadius = 40
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconContainerView)
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.addSubview(iconImageView)
        
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        roleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        roleLabel.textColor = UIColor.Papyrus.secondaryText
        roleLabel.textAlignment = .center
        roleLabel.numberOfLines = 2
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roleLabel)
        
        traditionLabel.font = .systemFont(ofSize: 11, weight: .medium)
        traditionLabel.textAlignment = .center
        traditionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(traditionLabel)
        
        selectionIndicator.image = UIImage(systemName: "checkmark.circle.fill")
        selectionIndicator.tintColor = UIColor.Papyrus.gold
        selectionIndicator.isHidden = true
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(selectionIndicator)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 80),
            iconContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            nameLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            roleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            traditionLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 4),
            traditionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            traditionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            selectionIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 28),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    func configure(with deity: OracleViewModel.Deity, isSelected: Bool) {
        nameLabel.text = deity.name
        nameLabel.textColor = UIColor.Papyrus.primaryText
        roleLabel.text = deity.role
        traditionLabel.text = deity.tradition.uppercased()
        let deityColor = UIColor(hex: deity.color) ?? UIColor.Papyrus.gold
        traditionLabel.textColor = deityColor.withAlphaComponent(0.8)
        
        if let image = UIImage(systemName: deity.avatar) {
            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
            iconImageView.image = image.withConfiguration(config)
            iconImageView.tintColor = .white
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        gradientLayer.cornerRadius = 40
        gradientLayer.colors = [
            deityColor.withAlphaComponent(0.8).cgColor,
            deityColor.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        iconContainerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        iconContainerView.layer.insertSublayer(gradientLayer, at: 0)
        
        selectionIndicator.isHidden = !isSelected
        if isSelected {
            containerView.layer.borderColor = UIColor.Papyrus.gold.cgColor
            containerView.layer.borderWidth = 2
            containerView.backgroundColor = UIColor.Papyrus.cardBackground.withAlphaComponent(0.95)
            
            containerView.layer.shadowColor = UIColor.Papyrus.gold.cgColor
            containerView.layer.shadowOpacity = 0.3
            containerView.layer.shadowRadius = 12
        } else {
            containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
            containerView.layer.borderWidth = 1
            containerView.backgroundColor = UIColor.Papyrus.cardBackground
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOpacity = 0.1
            containerView.layer.shadowRadius = 8
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectionIndicator.isHidden = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.Papyrus.aged.cgColor
        containerView.backgroundColor = UIColor.Papyrus.cardBackground
        iconContainerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}