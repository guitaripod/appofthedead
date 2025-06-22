import UIKit

final class BookLibraryViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: BookLibraryViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Section, BookItem>!
    
    private enum Section: CaseIterable {
        case available
        case reading
        case completed
        
        var title: String {
            switch self {
            case .available:
                return "Available Books"
            case .reading:
                return "Currently Reading"
            case .completed:
                return "Completed"
            }
        }
    }
    
    private struct BookItem: Hashable {
        let book: Book
        let progress: BookProgress?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(book.id)
        }
        
        static func == (lhs: BookItem, rhs: BookItem) -> Bool {
            return lhs.book.id == rhs.book.id
        }
    }
    
    // MARK: - UI Components
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = PapyrusDesignSystem.Colors.background
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        
        let imageView = UIImageView(image: UIImage(systemName: "books.vertical"))
        imageView.tintColor = PapyrusDesignSystem.Colors.secondaryText
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "No books available yet"
        label.font = PapyrusDesignSystem.Typography.body()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    init(viewModel: BookLibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Library"
        tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "books.vertical"), tag: 3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        bindViewModel()
        viewModel.loadBooks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshBooks()
    }
    
    @objc private func layoutPreferenceChanged() {
        // Force complete reload with new layout
        let newLayout = createCompositionalLayout()
        
        // Disable animations to prevent visual glitches
        UIView.performWithoutAnimation {
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.setCollectionViewLayout(newLayout, animated: false)
            collectionView.layoutIfNeeded()
        }
        
        // Apply snapshot after layout is complete
        DispatchQueue.main.async { [weak self] in
            self?.updateSnapshot()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.background
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Register cells
        collectionView.register(BookCollectionViewCell.self, forCellWithReuseIdentifier: "BookCell")
        collectionView.register(BookListCell.self, forCellWithReuseIdentifier: "BookListCell")
        collectionView.register(BookSectionHeaderView.self, 
                               forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                               withReuseIdentifier: "HeaderView")
        
        // Listen for layout preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layoutPreferenceChanged),
            name: NSNotification.Name("ViewLayoutPreferenceChanged"),
            object: nil
        )
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            let isListView = UserDefaults.standard.object(forKey: "viewLayoutPreference") as? String == "list"
            
            if isListView {
                // List layout
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                
                // Add header
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                
                return section
            } else {
                // Grid layout
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.5),
                    heightDimension: .estimated(280)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(280)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                
                // Add header
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                
                return section
            }
        }
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, BookItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, bookItem in
            let isListView = UserDefaults.standard.object(forKey: "viewLayoutPreference") as? String == "list"
            
            if isListView {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "BookListCell",
                    for: indexPath
                ) as! BookListCell
                
                let beliefSystem = self.viewModel.beliefSystem(for: bookItem.book)
                cell.configure(with: bookItem.book, progress: bookItem.progress, beliefSystem: beliefSystem)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "BookCell",
                    for: indexPath
                ) as! BookCollectionViewCell
                
                let beliefSystem = self.viewModel.beliefSystem(for: bookItem.book)
                cell.configure(with: bookItem.book, progress: bookItem.progress, beliefSystem: beliefSystem)
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "HeaderView",
                for: indexPath
            ) as! BookSectionHeaderView
            
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            header.configure(with: section.title)
            return header
        }
    }
    
    private func bindViewModel() {
        viewModel.onBooksUpdate = { [weak self] in
            self?.updateSnapshot()
        }
    }
    
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, BookItem>()
        
        // Currently reading (sorted by progress descending)
        let readingBooks = viewModel.readingBooks
            .sorted { $0.progress.readingProgress > $1.progress.readingProgress }
            .map { BookItem(book: $0.book, progress: $0.progress) }
        if !readingBooks.isEmpty {
            snapshot.appendSections([.reading])
            snapshot.appendItems(readingBooks, toSection: .reading)
        }
        
        // Completed books
        let completedBooks = viewModel.completedBooks.map { BookItem(book: $0.book, progress: $0.progress) }
        if !completedBooks.isEmpty {
            snapshot.appendSections([.completed])
            snapshot.appendItems(completedBooks, toSection: .completed)
        }
        
        // Available books
        let availableBooks = viewModel.availableBooks.map { BookItem(book: $0, progress: nil) }
        if !availableBooks.isEmpty {
            snapshot.appendSections([.available])
            snapshot.appendItems(availableBooks, toSection: .available)
        }
        
        // Show empty state if no books
        emptyStateView.isHidden = !snapshot.itemIdentifiers.isEmpty
        
        // Don't animate if we're changing layouts
        let shouldAnimate = !collectionView.isDragging && !collectionView.isDecelerating
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}

// MARK: - UICollectionViewDelegate

extension BookLibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let bookItem = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let bookReaderViewModel = BookReaderViewModel(
            book: bookItem.book,
            userId: viewModel.userId
        )
        let bookReaderVC = BookReaderViewController(viewModel: bookReaderViewModel)
        present(bookReaderVC, animated: true)
    }
}

// MARK: - BookCollectionViewCell

private class BookCollectionViewCell: UICollectionViewCell {
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = PapyrusDesignSystem.Colors.goldLeaf.withAlphaComponent(0.1)
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.body().withSize(14)
        label.textColor = PapyrusDesignSystem.Colors.primaryText
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = PapyrusDesignSystem.Colors.goldLeaf
        progress.trackTintColor = PapyrusDesignSystem.Colors.secondaryText.withAlphaComponent(0.2)
        progress.isHidden = true
        return progress
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(coverImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(statusLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            coverImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            coverImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor, multiplier: 1.4),
            
            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with book: Book, progress: BookProgress?, beliefSystem: BeliefSystem? = nil) {
        titleLabel.text = book.title
        
        // Set cover image with belief system icon
        if let beliefSystem = beliefSystem {
            coverImageView.image = IconProvider.beliefSystemIcon(for: beliefSystem.icon, color: UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf)
            coverImageView.tintColor = UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        } else {
            coverImageView.image = UIImage(systemName: "book.closed.fill")
            coverImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        }
        
        if let progress = progress {
            progressView.isHidden = false
            progressView.progress = Float(progress.readingProgress)
            
            if progress.isCompleted {
                statusLabel.isHidden = false
                statusLabel.text = "Completed"
                statusLabel.textColor = PapyrusDesignSystem.Colors.goldLeaf
            } else {
                statusLabel.isHidden = false
                statusLabel.text = "\(Int(progress.readingProgress * 100))% Complete"
            }
        } else {
            progressView.isHidden = true
            statusLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        statusLabel.text = nil
        progressView.progress = 0
        progressView.isHidden = true
        statusLabel.isHidden = true
        coverImageView.image = nil
        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - BookSectionHeaderView

private class BookSectionHeaderView: UICollectionReusableView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.title3()
        label.textColor = PapyrusDesignSystem.Colors.ancientInk
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}