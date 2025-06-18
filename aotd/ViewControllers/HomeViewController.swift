import UIKit
import AuthenticationServices

final class HomeViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding {
    
    // MARK: - Properties
    
    private let viewModel: HomeViewModel
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.Papyrus.background
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var dataSource = createDataSource()
    
    // MARK: - Initialization
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Refresh data when returning to home screen to pick up any XP changes
        viewModel.loadData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            self?.applySnapshot()
        }
        
        viewModel.onUserDataUpdate = { [weak self] user in
            self?.updateHeader()
        }
    }
    
    private func updateHeader() {
        // Force the header to update by invalidating the supplementary views
        let snapshot = dataSource.snapshot()
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    // MARK: - Collection View Configuration
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
            section.interGroupSpacing = 8
            
            // Add header
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            header.pinToVisibleBounds = false
            section.boundarySupplementaryItems = [header]
            
            return section
        }
    }
    
    private func createDataSource() -> UICollectionViewDiffableDataSource<Section, PathItem> {
        let cellRegistration = UICollectionView.CellRegistration<PathCollectionViewCell, PathItem> { cell, indexPath, item in
            cell.configure(with: item)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<HomeHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] headerView, elementKind, indexPath in
            guard let self = self, let user = self.viewModel.currentUser else { return }
            let isSignedIn = UserDefaults.standard.string(forKey: "appleUserId") != nil
            headerView.configure(xp: user.totalXP, streak: user.currentStreak, isSignedIn: isSignedIn)
            headerView.delegate = self
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, PathItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        
        return dataSource
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, PathItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.pathItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if item.isUnlocked {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            viewModel.selectPath(item)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
            
            showLockedPathAlert(for: item)
        }
    }
    
    private func showLockedPathAlert(for item: PathItem) {
        PapyrusAlert.showSimpleAlert(
            title: "Path Locked",
            message: "Complete other paths to unlock \(item.name)",
            from: self
        )
    }
}

// MARK: - Section

extension HomeViewController {
    enum Section {
        case main
    }
}

// MARK: - HomeHeaderViewDelegate

extension HomeViewController: HomeHeaderViewDelegate {
    func profileButtonTapped() {
        let isSignedIn = UserDefaults.standard.string(forKey: "appleUserId") != nil
        
        if isSignedIn {
            showProfileViewController()
        } else {
            showSignInOptions()
        }
    }
    
    private func showProfileViewController() {
        // Switch to the Profile tab instead of presenting modally
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 1 // Profile is the second tab
        }
    }
    
    private func showSignInOptions() {
        let signInVC = SignInViewController()
        signInVC.delegate = self
        signInVC.modalPresentationStyle = .pageSheet
        if let sheet = signInVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(signInVC, animated: true)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

// MARK: - AuthenticationManagerDelegate

extension HomeViewController: AuthenticationManagerDelegate {
    func authenticationDidComplete(userId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadData()
            self.updateHeader()
            
            PapyrusAlert.showSimpleAlert(
                title: "Success",
                message: "You are now signed in!",
                from: self
            )
        }
    }
    
    func authenticationDidFail(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            PapyrusAlert.showSimpleAlert(
                title: "Sign In Failed",
                message: error.localizedDescription,
                from: self
            )
        }
    }
}

// MARK: - SignInViewControllerDelegate

extension HomeViewController: SignInViewControllerDelegate {
    func signInDidComplete() {
        viewModel.loadData()
        updateHeader()
        
        PapyrusAlert.showSimpleAlert(
            title: "Success",
            message: "You are now signed in!",
            from: self
        )
    }
    
    func signInDidCancel() {
        // No action needed
    }
}