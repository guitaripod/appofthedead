import UIKit

final class HomeViewController: UIViewController, ViewLayoutConfigurable {
    
    
    
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
    
    
    
    private lazy var collectionDataSource = createCollectionDataSource()
    
    
    
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppLogger.logViewControllerLifecycle("HomeViewController", event: "viewDidLoad")
        setupUI()
        bindViewModel()
        setupLayout(for: currentLayoutPreference)
        setupNotifications()
        viewModel.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppLogger.logViewControllerLifecycle("HomeViewController", event: "viewWillAppear")
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        
        viewModel.loadData()
    }
    
    
    
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePurchaseCompleted(_:)),
            name: StoreManager.purchaseCompletedNotification,
            object: nil
        )
    }
    
    @objc private func handleLayoutPreferenceChanged(_ notification: Notification) {
        if let layout = notification.userInfo?["layout"] as? ViewLayoutPreference {
            switchToLayout(layout)
        }
    }
    
    @objc private func handlePurchaseCompleted(_ notification: Notification) {
        
        if let productId = notification.object as? ProductIdentifier,
           productId.beliefSystemId != nil {
            
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.setContentOffset(.zero, animated: true)
            }
        }
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.applySnapshot()
                self?.updateHeader()
            }
        }
        
        viewModel.onUserDataUpdate = { [weak self] user in
            DispatchQueue.main.async {
                self?.updateHeader()
            }
        }
        
        viewModel.onPathSelected = { [weak self] beliefSystem in
            guard let self = self else { return }
            
            
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = scene.delegate as? SceneDelegate else { return }
            
            let coordinator = sceneDelegate.learningPathCoordinator ?? {
                let newCoordinator = LearningPathCoordinator(
                    navigationController: self.navigationController ?? UINavigationController(),
                    beliefSystem: beliefSystem,
                    contentLoader: self.viewModel.contentLoader
                )
                sceneDelegate.learningPathCoordinator = newCoordinator
                return newCoordinator
            }()
            
            coordinator.start()
        }
    }
    
    private func updateHeader() {
        
        let snapshot = collectionDataSource.snapshot()
        collectionDataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 0
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
            guard let self = self else { return nil }
            
            if self.currentLayoutPreference == .grid {
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(190))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
                section.interGroupSpacing = 8
                
                
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
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
                section.interGroupSpacing = 0
                
                
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
        
        let gridCellRegistration = UICollectionView.CellRegistration<PathCollectionViewCell, PathItem> { [weak self] cell, indexPath, item in
            let preview = self?.viewModel.pathPreview(for: item.id)
            cell.configure(with: item, preview: preview)
        }
        
        
        let listCellRegistration = UICollectionView.CellRegistration<PathListCell, PathItem> { [weak self] cell, indexPath, item in
            let preview = self?.viewModel.pathPreview(for: item.id)
            cell.configure(with: item, preview: preview)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<HomeHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] headerView, elementKind, indexPath in
            guard let self = self, let user = self.viewModel.currentUser else { return }
            headerView.configure(xp: user.totalXP, streak: user.currentStreak, isSignedIn: true)
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
        
        collectionDataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    
    
    
    func switchToLayout(_ layout: ViewLayoutPreference) {
        currentLayoutPreference = layout
        setupLayout(for: layout)
        
        
        collectionView.collectionViewLayout.invalidateLayout()
        applySnapshot()
    }
    
    func setupLayout(for preference: ViewLayoutPreference) {
        
        
        currentLayoutPreference = preference
    }
}



extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = collectionDataSource.itemIdentifier(for: indexPath) else { return }
        
        AppLogger.logUserAction("selectPath", parameters: [
            "pathId": item.id,
            "pathName": item.name,
            "isUnlocked": item.isUnlocked,
            "status": "\(item.status)"
        ])
        
        if item.isUnlocked {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            
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
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = collectionDataSource.itemIdentifier(for: indexPath) else { return nil }
        
        
        guard item.isUnlocked else { return nil }
        
        
        guard let beliefSystem = viewModel.beliefSystems.first(where: { $0.id == item.id }) else { return nil }
        let progress = viewModel.userProgress[item.id]
        let preview = viewModel.pathPreview(for: item.id)
        
        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: {
                return PathPreviewViewController(
                    beliefSystem: beliefSystem,
                    progress: progress,
                    pathPreview: preview
                )
            },
            actionProvider: { [weak self] suggestedActions in
                return self?.createContextMenuActions(for: item, beliefSystem: beliefSystem, progress: progress)
            }
        )
    }
    
    private func createContextMenuActions(for item: PathItem, beliefSystem: BeliefSystem, progress: Progress?) -> UIMenu? {
        var actions: [UIMenuElement] = []
        
        
        let primaryTitle = (progress?.earnedXP ?? 0) > 0 ? "Continue Learning" : "Start Path"
        let primaryAction = UIAction(
            title: primaryTitle,
            image: UIImage(systemName: "play.fill"),
            attributes: []
        ) { [weak self] _ in
            self?.viewModel.selectPath(item)
        }
        actions.append(primaryAction)
        
        
        if let user = viewModel.currentUser {
            do {
                let mistakeCount = try DatabaseManager.shared.getMistakeCount(userId: user.id, beliefSystemId: item.id)
                AppLogger.ui.info("Context menu mistake count", metadata: [
                    "beliefSystemId": item.id,
                    "mistakeCount": mistakeCount
                ])
                
                if mistakeCount > 0 {
                    let mistakeAction = UIAction(
                        title: "Review Mistakes (\(mistakeCount))",
                        image: UIImage(systemName: "exclamationmark.circle.fill"),
                        attributes: []
                    ) { [weak self] _ in
                        self?.startMistakeReview(for: item, beliefSystem: beliefSystem)
                    }
                    actions.append(mistakeAction)
                }
            } catch {
                AppLogger.logError(error, context: "Getting mistake count for context menu", logger: AppLogger.ui)
            }
        }
        
        
        if let progress = progress, progress.earnedXP > 0 {
            let resetAction = UIAction(
                title: "Reset Progress",
                image: UIImage(systemName: "arrow.counterclockwise"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.showResetProgressConfirmation(for: item, beliefSystem: beliefSystem)
            }
            actions.append(resetAction)
        }
        
        
        
        
        let shareAction = UIAction(
            title: "Share Path",
            image: UIImage(systemName: "square.and.arrow.up"),
            attributes: []
        ) { [weak self] _ in
            self?.sharePath(beliefSystem)
        }
        actions.append(shareAction)
        
        return UIMenu(title: "", children: actions)
    }
    
    private func showResetProgressConfirmation(for item: PathItem, beliefSystem: BeliefSystem) {
        PapyrusAlert(
            title: "Reset Progress?",
            message: "This will reset all your progress for \(beliefSystem.name). You'll lose your XP and completed lessons.",
            style: .alert
        )
        .addAction(PapyrusAlert.Action(title: "Cancel", style: .cancel))
        .addAction(PapyrusAlert.Action(title: "Reset", style: .destructive) { [weak self] in
            self?.viewModel.resetProgress(for: item.id)
        })
        .present(from: self)
    }
    
    
    private func sharePath(_ beliefSystem: BeliefSystem) {
        let shareText = "I'm learning about \(beliefSystem.name) in App of the Dead!"
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true)
    }
}



extension HomeViewController {
    private func showLockedPathAlert(for item: PathItem) {
        let paywall = PaywallViewController(reason: .lockedPath(beliefSystemId: item.id))
        present(paywall, animated: true)
    }
    
    private func showCompletionOptions(for item: PathItem) {
        
        guard let beliefSystem = viewModel.beliefSystems.first(where: { $0.id == item.id }),
              let progress = viewModel.userProgress[item.id] else { return }
        
        
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
    
    private func startMistakeReview(for item: PathItem, beliefSystem: BeliefSystem) {
        guard let user = viewModel.currentUser else { return }
        
        do {
            
            let mistakes = try DatabaseManager.shared.getMistakes(userId: user.id, beliefSystemId: item.id)
            
            guard !mistakes.isEmpty else {
                PapyrusAlert.showSimpleAlert(
                    title: "No Mistakes",
                    message: "Great job! You haven't made any mistakes in this path.",
                    from: self
                )
                return
            }
            
            
            let session = try DatabaseManager.shared.startMistakeSession(userId: user.id, beliefSystemId: item.id)
            
            
            let mistakeReviewVC = MistakeReviewViewController(
                beliefSystem: beliefSystem,
                mistakes: mistakes,
                session: session,
                contentLoader: viewModel.contentLoader
            )
            
            mistakeReviewVC.delegate = self
            
            let navController = UINavigationController(rootViewController: mistakeReviewVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
            
            AppLogger.learning.info("Started mistake review", metadata: [
                "beliefSystemId": item.id,
                "mistakeCount": mistakes.count
            ])
            
        } catch {
            AppLogger.logError(error, context: "Starting mistake review", logger: AppLogger.learning)
            PapyrusAlert.showSimpleAlert(
                title: "Error",
                message: "Unable to start mistake review. Please try again.",
                from: self
            )
        }
    }
}



extension HomeViewController {
    enum Section {
        case main
    }
}



extension HomeViewController: HomeHeaderViewDelegate {
    func profileButtonTapped() {
        AppLogger.logUserAction("profileButtonTapped")
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 1
        }
    }
    

}







extension HomeViewController: MistakeReviewViewControllerDelegate {
    func mistakeReviewCompleted(correctCount: Int, totalCount: Int, xpEarned: Int) {
        
        viewModel.loadData()
        
        
        DispatchQueue.main.async { [weak self] in
            
            self?.collectionView.reloadData()
            self?.updateHeader()
        }
        
        let accuracy = Int((Double(correctCount) / Double(totalCount)) * 100)
        PapyrusAlert.showSimpleAlert(
            title: "Review Complete!",
            message: "You got \(correctCount) out of \(totalCount) correct (\(accuracy)%). Earned \(xpEarned) XP!",
            from: self
        )
    }
    
    func mistakeReviewCancelled() {
        
        viewModel.loadData()
        
        
        DispatchQueue.main.async { [weak self] in
            
            self?.collectionView.reloadData()
        }
    }
}