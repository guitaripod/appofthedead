import UIKit
import AuthenticationServices

final class HomeViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding, ViewLayoutConfigurable {
    
    // MARK: - Properties
    
    private let viewModel: HomeViewModel
    var currentLayoutPreference: ViewLayoutPreference = UserDefaults.standard.viewLayoutPreference
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.Papyrus.background
        collectionView.delegate = self
        return collectionView
    }()
    
    // Removed tableView and tableHeaderView - now using single collectionView with compositional layout
    
    private lazy var collectionDataSource = createCollectionDataSource()
    
    // MARK: - Initialization
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupLayout(for: currentLayoutPreference)
        setupNotifications()
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
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLayoutPreferenceChanged(_:)),
            name: .viewLayoutPreferenceChanged,
            object: nil
        )
    }
    
    @objc private func handleLayoutPreferenceChanged(_ notification: Notification) {
        if let layout = notification.userInfo?["layout"] as? ViewLayoutPreference {
            switchToLayout(layout)
        }
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
        guard let user = viewModel.currentUser else { return }
        let isSignedIn = UserDefaults.standard.string(forKey: "appleUserId") != nil
        
        // Force the collection view header to update
        let snapshot = collectionDataSource.snapshot()
        collectionDataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    // MARK: - Collection View Configuration
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 0
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
            guard let self = self else { return nil }
            
            if self.currentLayoutPreference == .grid {
                // Grid layout
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(190))
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
            } else {
                // List layout with custom item size
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
                section.interGroupSpacing = 0
                
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
        }, configuration: configuration)
    }
    
    private func createCollectionDataSource() -> UICollectionViewDiffableDataSource<Section, PathItem> {
        // Grid cell registration
        let gridCellRegistration = UICollectionView.CellRegistration<PathCollectionViewCell, PathItem> { cell, indexPath, item in
            cell.configure(with: item)
        }
        
        // List cell registration
        let listCellRegistration = UICollectionView.CellRegistration<PathListCell, PathItem> { cell, indexPath, item in
            cell.configure(with: item)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<HomeHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] headerView, elementKind, indexPath in
            guard let self = self, let user = self.viewModel.currentUser else { return }
            let isSignedIn = UserDefaults.standard.string(forKey: "appleUserId") != nil
            headerView.configure(xp: user.totalXP, streak: user.currentStreak, isSignedIn: isSignedIn)
            headerView.delegate = self
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, PathItem>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return nil }
            
            if self.currentLayoutPreference == .grid {
                return collectionView.dequeueConfiguredReusableCell(using: gridCellRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
            }
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
        collectionDataSource.apply(snapshot, animatingDifferences: false)
    }
    
    
    // MARK: - ViewLayoutConfigurable
    
    func switchToLayout(_ layout: ViewLayoutPreference) {
        currentLayoutPreference = layout
        setupLayout(for: layout)
        
        // Force layout update
        collectionView.collectionViewLayout.invalidateLayout()
        applySnapshot()
    }
    
    func setupLayout(for preference: ViewLayoutPreference) {
        // Layout will be handled by compositional layout
        // Just update the current preference which the layout uses
        currentLayoutPreference = preference
    }
}

// MARK: - UICollectionViewDelegate

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = collectionDataSource.itemIdentifier(for: indexPath) else { return }
        
        if item.isUnlocked {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            // Check if path is completed and show options
            if item.status == Progress.ProgressStatus.completed || item.status == Progress.ProgressStatus.mastered {
                showCompletionOptions(for: item)
            } else {
                viewModel.selectPath(item)
            }
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
            
            showLockedPathAlert(for: item)
        }
    }
}

// MARK: - Helper Methods

extension HomeViewController {
    private func showLockedPathAlert(for item: PathItem) {
        let paywall = PaywallViewController(reason: .lockedPath(beliefSystemId: item.id))
        present(paywall, animated: true)
    }
    
    private func showCompletionOptions(for item: PathItem) {
        // Find the corresponding belief system
        guard let beliefSystem = viewModel.beliefSystems.first(where: { $0.id == item.id }),
              let progress = viewModel.userProgress[item.id] else { return }
        
        // Get the coordinator from SceneDelegate
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = scene.delegate as? SceneDelegate else { return }
        
        let coordinator = sceneDelegate.learningPathCoordinator ?? {
            let newCoordinator = LearningPathCoordinator(
                navigationController: self.navigationController ?? UINavigationController(),
                beliefSystem: beliefSystem,
                contentLoader: viewModel.contentLoader
            )
            sceneDelegate.learningPathCoordinator = newCoordinator
            return newCoordinator
        }()
        
        let completionVC = PathCompletionOptionsViewController(
            beliefSystem: beliefSystem,
            progress: progress,
            coordinator: coordinator
        )
        present(completionVC, animated: true)
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