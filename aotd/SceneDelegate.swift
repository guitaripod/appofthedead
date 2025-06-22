import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var learningPathCoordinator: LearningPathCoordinator?
    private let databaseManager = DatabaseManager.shared
    
    private struct SessionState {
        static let currentBeliefSystemKey = "currentBeliefSystemId"
    }

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        AppLogger.ui.info("Scene will connect to session")
        let sceneSetupActivity = AppLogger.beginActivity("SceneSetup")
        
        self.window = UIWindow(windowScene: windowScene)
        
        // Initialize custom icons
        let iconsActivity = AppLogger.beginActivity("IconProvider.createCustomIcons")
        IconProvider.createCustomIcons()
        AppLogger.endActivity("IconProvider.createCustomIcons", id: iconsActivity)
        
        // Initialize content loader
        let contentLoaderActivity = AppLogger.beginActivity("ContentLoader.init")
        let contentLoader = ContentLoader()
        AppLogger.endActivity("ContentLoader.init", id: contentLoaderActivity)
        
        // Set the content loader in database manager to avoid duplicates
        databaseManager.setContentLoader(contentLoader)
        
        // Generate books if needed (runs in background)
        DispatchQueue.global(qos: .background).async {
            let bookGenerator = BookContentGenerator(
                databaseManager: self.databaseManager,
                contentLoader: contentLoader
            )
            bookGenerator.generateAndSaveAllBooks()
        }
        
        // Initialize Home screen
        let homeActivity = AppLogger.beginActivity("HomeViewController.setup")
        let homeViewModel = HomeViewModel(
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        let homeNavigationController = UINavigationController(rootViewController: homeViewController)
        AppLogger.endActivity("HomeViewController.setup", id: homeActivity)
        
        // Initialize Profile screen
        let profileActivity = AppLogger.beginActivity("ProfileViewController.setup")
        let profileViewModel = ProfileViewModel(databaseManager: databaseManager)
        let profileViewController = ProfileViewController(viewModel: profileViewModel)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)
        AppLogger.endActivity("ProfileViewController.setup", id: profileActivity)
        
        // Initialize Settings screen
        let settingsViewController = SettingsViewController()
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        
        // Initialize Oracle screen
        let oracleViewController = OracleViewController()
        let oracleNavigationController = UINavigationController(rootViewController: oracleViewController)
        
        // Initialize Library screen
        let libraryActivity = AppLogger.beginActivity("BookLibraryViewController.setup")
        let libraryViewModel = BookLibraryViewModel(
            userId: databaseManager.fetchUser()?.id ?? "",
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let libraryViewController = BookLibraryViewController(viewModel: libraryViewModel)
        let libraryNavigationController = UINavigationController(rootViewController: libraryViewController)
        AppLogger.endActivity("BookLibraryViewController.setup", id: libraryActivity)
        
        // Create Tab Bar Controller
        let tabBarController = UITabBarController()
        
        // Configure tab bar items
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
        
        // Set view controllers
        tabBarController.viewControllers = [homeNavigationController, profileNavigationController, oracleNavigationController, libraryNavigationController, settingsNavigationController]
        
        // Configure appearance with Papyrus theme
        configureNavigationBarAppearance()
        configureTabBarAppearance(tabBarController.tabBar)
        
        // Set up navigation flow
        setupNavigationFlow(
            homeViewModel: homeViewModel,
            navigationController: homeNavigationController,
            contentLoader: contentLoader
        )
        
        self.window?.rootViewController = tabBarController
        self.window?.makeKeyAndVisible()
        
        // Clear any stored session to prevent auto-navigation
        UserDefaults.standard.removeObject(forKey: SessionState.currentBeliefSystemKey)
        
        AppLogger.endActivity("SceneSetup", id: sceneSetupActivity, metadata: [
            "viewControllerCount": tabBarController.viewControllers?.count ?? 0
        ])
        AppLogger.ui.info("Scene setup complete")
    }
    
    private func setupNavigationFlow(
        homeViewModel: HomeViewModel,
        navigationController: UINavigationController,
        contentLoader: ContentLoader
    ) {
        homeViewModel.onPathSelected = { [weak self, weak navigationController] beliefSystem in
            guard let self = self, let navigationController = navigationController else { return }
            self.startLearningPath(
                beliefSystem: beliefSystem,
                navigationController: navigationController,
                contentLoader: contentLoader
            )
        }
    }
    
    private func startLearningPath(
        beliefSystem: BeliefSystem,
        navigationController: UINavigationController,
        contentLoader: ContentLoader
    ) {
        AppLogger.logUserAction("startLearningPath", parameters: [
            "beliefSystemId": beliefSystem.id,
            "beliefSystemName": beliefSystem.name
        ], logger: AppLogger.learning)
        
        // Save current learning path session
        UserDefaults.standard.set(beliefSystem.id, forKey: SessionState.currentBeliefSystemKey)
        
        learningPathCoordinator = LearningPathCoordinator(
            navigationController: navigationController,
            beliefSystem: beliefSystem,
            contentLoader: contentLoader
        )
        
        learningPathCoordinator?.start()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLogger.ui.info("Scene did enter background")
        // Session state is already saved when starting learning paths
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLogger.ui.info("Scene will enter foreground")
        // Resume functionality is handled in scene connection
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        AppLogger.ui.info("Scene did become active")
        // Trigger sync when app becomes active
        let syncActivity = AppLogger.beginActivity("SyncManager.attemptSync", logger: AppLogger.sync)
        SyncManager.shared.attemptSync()
        AppLogger.endActivity("SyncManager.attemptSync", id: syncActivity, logger: AppLogger.sync)
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Background
        appearance.backgroundColor = UIColor.Papyrus.cardBackground
        
        // Title attributes
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.primaryText,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.primaryText,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Button attributes
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.gold
        ]
        appearance.buttonAppearance = buttonAppearance
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.Papyrus.gold
    }
    
    private func configureTabBarAppearance(_ tabBar: UITabBar) {
        // Configure tab bar with Papyrus theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Background color
        appearance.backgroundColor = UIColor.Papyrus.cardBackground
        
        // Shadow
        appearance.shadowColor = UIColor.Papyrus.aged
        appearance.shadowImage = UIImage()
        
        // Item appearance
        let itemAppearance = UITabBarItemAppearance()
        
        // Normal state
        itemAppearance.normal.iconColor = UIColor.Papyrus.tertiaryText
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.tertiaryText,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state
        itemAppearance.selected.iconColor = UIColor.Papyrus.gold
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.gold,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        
        // Tint color for selected items
        tabBar.tintColor = UIColor.Papyrus.gold
        
        // Add subtle border
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = UIColor.Papyrus.aged.cgColor
    }
}
