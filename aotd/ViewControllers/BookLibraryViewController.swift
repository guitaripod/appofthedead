import UIKit

final class BookLibraryViewController: UIViewController {
    
    
    
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
        let isUnlocked: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(book.id)
            hasher.combine(progress?.readingProgress ?? 0)
            hasher.combine(progress?.isCompleted ?? false)
            hasher.combine(isUnlocked)
        }
        
        static func == (lhs: BookItem, rhs: BookItem) -> Bool {
            return lhs.book.id == rhs.book.id &&
                   lhs.progress?.readingProgress == rhs.progress?.readingProgress &&
                   lhs.progress?.isCompleted == rhs.progress?.isCompleted &&
                   lhs.isUnlocked == rhs.isUnlocked
        }
    }
    
    
    
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
        
        if dataSource != nil {
            updateSnapshot()
        }
    }
    
    @objc private func layoutPreferenceChanged() {
        
        let isListView = UserDefaults.standard.object(forKey: "viewLayoutPreference") as? String == "list"
        
        
        let newLayout = createCompositionalLayout()
        
        
        UIView.performWithoutAnimation { [weak self] in
            guard let self = self else { return }
            
            
            let offset = self.collectionView.contentOffset
            
            
            self.collectionView.setCollectionViewLayout(newLayout, animated: false)
            
            
            self.configureDataSource()
            
            
            self.updateSnapshot(animatingDifferences: false)
            
            
            self.collectionView.contentOffset = offset
        }
    }
    
    
    
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
        
        
        collectionView.register(BookCollectionViewCell.self, forCellWithReuseIdentifier: "BookCell")
        collectionView.register(BookListCell.self, forCellWithReuseIdentifier: "BookListCell")
        collectionView.register(BookSectionHeaderView.self, 
                               forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                               withReuseIdentifier: "HeaderView")
        
        
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
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.5),
                    heightDimension: .absolute(260)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(260)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                
                
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
                cell.configure(with: bookItem.book, progress: bookItem.progress, beliefSystem: beliefSystem, isUnlocked: bookItem.isUnlocked)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "BookCell",
                    for: indexPath
                ) as! BookCollectionViewCell
                
                let beliefSystem = self.viewModel.beliefSystem(for: bookItem.book)
                cell.configure(with: bookItem.book, progress: bookItem.progress, beliefSystem: beliefSystem, isUnlocked: bookItem.isUnlocked)
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
    
    private func updateSnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, BookItem>()
        
        
        let readingBooks = viewModel.readingBooks
            .sorted { $0.progress.readingProgress > $1.progress.readingProgress }
            .map { BookItem(book: $0.book, progress: $0.progress, isUnlocked: $0.isUnlocked) }
        if !readingBooks.isEmpty {
            snapshot.appendSections([.reading])
            snapshot.appendItems(readingBooks, toSection: .reading)
        }
        
        
        let completedBooks = viewModel.completedBooks.map { BookItem(book: $0.book, progress: $0.progress, isUnlocked: $0.isUnlocked) }
        if !completedBooks.isEmpty {
            snapshot.appendSections([.completed])
            snapshot.appendItems(completedBooks, toSection: .completed)
        }
        
        
        let availableBooks = viewModel.availableBooks.map { book in
            BookItem(book: book, progress: nil, isUnlocked: viewModel.isBookUnlocked(book))
        }
        if !availableBooks.isEmpty {
            snapshot.appendSections([.available])
            snapshot.appendItems(availableBooks, toSection: .available)
        }
        
        
        emptyStateView.isHidden = !snapshot.itemIdentifiers.isEmpty
        
        
        let shouldAnimate = animatingDifferences && !collectionView.isDragging && !collectionView.isDecelerating
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
}



extension BookLibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let bookItem = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if bookItem.isUnlocked {
            
            let bookReaderViewModel = BookReaderViewModel(
                book: bookItem.book,
                userId: viewModel.userId
            )
            let bookReaderVC = BookReaderViewController(viewModel: bookReaderViewModel)
            present(bookReaderVC, animated: true)
        } else {
            
            let paywall = PaywallViewController(reason: .lockedPath(beliefSystemId: bookItem.book.beliefSystemId))
            present(paywall, animated: true)
        }
    }
}



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
        imageView.contentMode = .scaleAspectFit
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
        label.lineBreakMode = .byTruncatingTail
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
    
    private lazy var lockIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = PapyrusDesignSystem.Colors.aged
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
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
        containerView.addSubview(lockIconImageView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        lockIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            coverImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 80),
            coverImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            
            lockIconImageView.centerXAnchor.constraint(equalTo: coverImageView.centerXAnchor),
            lockIconImageView.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor),
            lockIconImageView.widthAnchor.constraint(equalToConstant: 32),
            lockIconImageView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(with book: Book, progress: BookProgress?, beliefSystem: BeliefSystem? = nil, isUnlocked: Bool = true) {
        titleLabel.text = book.title
        
        
        if isUnlocked {
            containerView.backgroundColor = PapyrusDesignSystem.Colors.beige
            containerView.layer.shadowOpacity = 0.15
            titleLabel.textColor = PapyrusDesignSystem.Colors.primaryText
            statusLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
            coverImageView.alpha = 1.0
            lockIconImageView.isHidden = true
        } else {
            containerView.backgroundColor = PapyrusDesignSystem.Colors.aged.withAlphaComponent(0.2)
            containerView.layer.shadowOpacity = 0.05
            titleLabel.textColor = PapyrusDesignSystem.Colors.tertiaryText
            statusLabel.textColor = PapyrusDesignSystem.Colors.tertiaryText
            coverImageView.alpha = 0.3
            lockIconImageView.isHidden = false
        }
        
        
        if let beliefSystem = beliefSystem {
            coverImageView.image = IconProvider.beliefSystemIcon(for: beliefSystem.icon, color: UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf)
            coverImageView.tintColor = UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        } else {
            coverImageView.image = UIImage(systemName: "book.closed.fill")
            coverImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        }
        
        if let progress = progress, isUnlocked {
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
        } else if !isUnlocked {
            progressView.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "Locked"
        } else {
            progressView.isHidden = true
            statusLabel.isHidden = true
        }
        
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        statusLabel.text = nil
        progressView.progress = 0
        progressView.isHidden = true
        statusLabel.isHidden = true
        coverImageView.image = nil
        coverImageView.alpha = 1.0
        lockIconImageView.isHidden = true
        containerView.backgroundColor = PapyrusDesignSystem.Colors.beige
        containerView.layer.shadowOpacity = 0.15
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}



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