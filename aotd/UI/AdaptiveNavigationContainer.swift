import UIKit

private enum LayoutConstants {
    static let sidebarHeaderHeight: CGFloat = 120
    static let sidebarMinWidth: CGFloat = 280
    static let sidebarMaxWidth: CGFloat = 400
    static let sidebarPreferredWidthFraction: CGFloat = 0.3
    static let headerLogoSize: CGFloat = 60
    static let headerLogoPointSize: CGFloat = 40
    static let headerTopPadding: CGFloat = 20
    static let defaultPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let separatorHeight: CGFloat = 0.5
    static let tabBarFontSize: CGFloat = 10
}

final class AdaptiveNavigationContainer: UIViewController {
    private let homeNavigationController: UINavigationController
    private let profileNavigationController: UINavigationController
    private let oracleNavigationController: UINavigationController
    private let libraryNavigationController: UINavigationController
    private let settingsNavigationController: UINavigationController
    private var embeddedTabBarController: UITabBarController?
    private var embeddedSplitViewController: UISplitViewController?
    private var sidebarViewController: SidebarViewController?
    private let adaptiveLayoutManager = AdaptiveLayoutManager.shared
    init(
        homeNav: UINavigationController,
        profileNav: UINavigationController,
        oracleNav: UINavigationController,
        libraryNav: UINavigationController,
        settingsNav: UINavigationController
    ) {
        self.homeNavigationController = homeNav
        self.profileNavigationController = profileNav
        self.oracleNavigationController = oracleNav
        self.libraryNavigationController = libraryNav
        self.settingsNavigationController = settingsNav
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationForCurrentTraits()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.setupNavigationForCurrentTraits()
        })
    }
    private func setupNavigationForCurrentTraits() {
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        if adaptiveLayoutManager.shouldUseSplitView(for: traitCollection) {
            setupSplitViewController()
        } else {
            setupTabBarController()
        }
    }
    private func setupTabBarController() {
        let tabBar = UITabBarController()
        homeNavigationController.tabBarItem = UITabBarItem(
            title: "Learn",
            image: UIImage(systemName: "book.fill"),
            selectedImage: UIImage(systemName: "book.fill")
        )
        profileNavigationController.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle.fill"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
        oracleNavigationController.tabBarItem = UITabBarItem(
            title: "Oracle",
            image: UIImage(systemName: "bubble.left.and.exclamationmark.bubble.right.fill"),
            selectedImage: UIImage(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
        )
        libraryNavigationController.tabBarItem = UITabBarItem(
            title: "Library",
            image: UIImage(systemName: "books.vertical"),
            selectedImage: UIImage(systemName: "books.vertical")
        )
        settingsNavigationController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape.fill"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        tabBar.viewControllers = [
            homeNavigationController,
            profileNavigationController,
            oracleNavigationController,
            libraryNavigationController,
            settingsNavigationController
        ]
        configureTabBarAppearance(tabBar.tabBar)
        addChild(tabBar)
        view.addSubview(tabBar.view)
        tabBar.view.frame = view.bounds
        tabBar.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tabBar.didMove(toParent: self)
        self.embeddedTabBarController = tabBar
        self.embeddedSplitViewController = nil
        self.sidebarViewController = nil
    }
    private func setupSplitViewController() {
        let splitVC = UISplitViewController(style: .doubleColumn)
        let sidebar = SidebarViewController()
        sidebar.delegate = self
        splitVC.setViewController(sidebar, for: .primary)
        splitVC.setViewController(homeNavigationController, for: .secondary)
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.preferredSplitBehavior = .tile
        splitVC.presentsWithGesture = true
        addSidebarToggleButtons(to: splitVC)
        splitVC.minimumPrimaryColumnWidth = LayoutConstants.sidebarMinWidth
        splitVC.preferredPrimaryColumnWidthFraction = LayoutConstants.sidebarPreferredWidthFraction
        splitVC.maximumPrimaryColumnWidth = LayoutConstants.sidebarMaxWidth
        splitVC.view.backgroundColor = PapyrusDesignSystem.Colors.background
        addChild(splitVC)
        view.addSubview(splitVC.view)
        splitVC.view.frame = view.bounds
        splitVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        splitVC.didMove(toParent: self)
        self.embeddedSplitViewController = splitVC
        self.sidebarViewController = sidebar
        self.embeddedTabBarController = nil
    }
    private func configureTabBarAppearance(_ tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        appearance.shadowColor = PapyrusDesignSystem.Colors.aged
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = PapyrusDesignSystem.Colors.tertiaryText
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: PapyrusDesignSystem.Colors.tertiaryText,
            .font: UIFont.systemFont(ofSize: LayoutConstants.tabBarFontSize, weight: .medium)
        ]
        itemAppearance.selected.iconColor = PapyrusDesignSystem.Colors.goldLeaf
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: PapyrusDesignSystem.Colors.goldLeaf,
            .font: UIFont.systemFont(ofSize: LayoutConstants.tabBarFontSize, weight: .bold)
        ]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = PapyrusDesignSystem.Colors.goldLeaf
    }
    private func addSidebarToggleButtons(to splitViewController: UISplitViewController) {
        let navControllers = [
            homeNavigationController,
            profileNavigationController,
            oracleNavigationController,
            libraryNavigationController,
            settingsNavigationController
        ]
        for navController in navControllers {
            if let rootVC = navController.viewControllers.first {
                rootVC.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                rootVC.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    func selectViewController(at index: Int) {
        if let tabBar = embeddedTabBarController {
            tabBar.selectedIndex = index
        } else if let sidebar = sidebarViewController {
            sidebar.selectItem(at: index)
            let viewControllers = [
                homeNavigationController,
                profileNavigationController,
                oracleNavigationController,
                libraryNavigationController,
                settingsNavigationController
            ]
            if index < viewControllers.count {
                embeddedSplitViewController?.setViewController(viewControllers[index], for: .secondary)
            }
        }
    }
}
extension AdaptiveNavigationContainer: SidebarViewControllerDelegate {
    func sidebar(_ sidebar: SidebarViewController, didSelectItemAt index: Int) {
        let viewControllers = [
            homeNavigationController,
            profileNavigationController,
            oracleNavigationController,
            libraryNavigationController,
            settingsNavigationController
        ]
        if index < viewControllers.count {
            let selectedNavController = viewControllers[index]
            embeddedSplitViewController?.setViewController(selectedNavController, for: .secondary)
            if let rootVC = selectedNavController.viewControllers.first {
                rootVC.navigationItem.leftBarButtonItem = embeddedSplitViewController?.displayModeButtonItem
                rootVC.navigationItem.leftItemsSupplementBackButton = true
            }
            if traitCollection.horizontalSizeClass == .compact {
                embeddedSplitViewController?.preferredDisplayMode = .secondaryOnly
            }
        }
    }
}
protocol SidebarViewControllerDelegate: AnyObject {
    func sidebar(_ sidebar: SidebarViewController, didSelectItemAt index: Int)
}
final class SidebarViewController: UIViewController {
    weak var delegate: SidebarViewControllerDelegate?
    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
        config.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        return collectionView
    }()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>?
    private var selectedIndexPath: IndexPath?
    enum Section {
        case main
    }
    struct Item: Hashable {
        let title: String
        let image: UIImage?
        let index: Int
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        applyInitialSnapshot()
    }
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        let headerView = createHeaderView()
        view.addSubview(headerView)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: LayoutConstants.sidebarHeaderHeight),
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    private func createHeaderView() -> UIView {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
        let logoImageView = UIImageView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        let config = UIImage.SymbolConfiguration(pointSize: LayoutConstants.headerLogoPointSize, weight: .bold)
        logoImageView.image = UIImage(systemName: "pyramid.fill", withConfiguration: config)
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "App of the Dead"
        titleLabel.font = PapyrusDesignSystem.Typography.title2(for: traitCollection)
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        titleLabel.textAlignment = .center
        headerView.addSubview(logoImageView)
        headerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: LayoutConstants.headerTopPadding),
            logoImageView.widthAnchor.constraint(equalToConstant: LayoutConstants.headerLogoSize),
            logoImageView.heightAnchor.constraint(equalToConstant: LayoutConstants.headerLogoSize),
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: LayoutConstants.smallPadding),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: LayoutConstants.defaultPadding),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -LayoutConstants.defaultPadding)
        ])
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.separator
        headerView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: LayoutConstants.defaultPadding),
            separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -LayoutConstants.defaultPadding),
            separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: LayoutConstants.separatorHeight)
        ])
        return headerView
    }
    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = item.image
            content.imageProperties.tintColor = PapyrusDesignSystem.Colors.goldLeaf
            content.textProperties.font = PapyrusDesignSystem.Typography.headline(for: self.traitCollection)
            content.textProperties.color = PapyrusDesignSystem.Colors.Dynamic.primaryText
            cell.contentConfiguration = content
            var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
            backgroundConfig.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.cardBackground
            cell.backgroundConfiguration = backgroundConfig
        }
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        let items = [
            Item(title: "Learn", image: UIImage(systemName: "book.fill"), index: 0),
            Item(title: "Profile", image: UIImage(systemName: "person.circle.fill"), index: 1),
            Item(title: "Oracle", image: UIImage(systemName: "bubble.left.and.exclamationmark.bubble.right.fill"), index: 2),
            Item(title: "Library", image: UIImage(systemName: "books.vertical"), index: 3),
            Item(title: "Settings", image: UIImage(systemName: "gearshape.fill"), index: 4)
        ]
        snapshot.appendItems(items)
        dataSource?.apply(snapshot, animatingDifferences: false)
        if let firstItem = items.first {
            selectItem(at: firstItem.index)
        }
    }
    func selectItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
        selectedIndexPath = indexPath
    }
}
extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource?.itemIdentifier(for: indexPath) {
            delegate?.sidebar(self, didSelectItemAt: item.index)
            selectedIndexPath = indexPath
        }
    }
}