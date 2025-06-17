import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var learningPathCoordinator: LearningPathCoordinator?
    private let databaseManager = DatabaseManager.shared
    
    private struct SessionState {
        static let currentBeliefSystemKey = "currentBeliefSystemId"
    }

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        self.window = UIWindow(windowScene: windowScene)
        
        // Initialize content loader
        let contentLoader = ContentLoader()
        
        // Set the content loader in database manager to avoid duplicates
        databaseManager.setContentLoader(contentLoader)
        
        // Initialize Home screen
        let homeViewModel = HomeViewModel(
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        let homeNavigationController = UINavigationController(rootViewController: homeViewController)
        
        // Initialize Profile screen
        let profileViewModel = ProfileViewModel(databaseManager: databaseManager)
        let profileViewController = ProfileViewController(viewModel: profileViewModel)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)
        
        // Initialize Settings screen
        let settingsViewController = SettingsViewController()
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        
        // Initialize Oracle screen
        let oracleViewController = OracleViewController()
        let oracleNavigationController = UINavigationController(rootViewController: oracleViewController)
        
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
        
        settingsNavigationController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape.fill"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        
        // Set view controllers
        tabBarController.viewControllers = [homeNavigationController, profileNavigationController, oracleNavigationController, settingsNavigationController]
        
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
        // Session state is already saved when starting learning paths
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Resume functionality is handled in scene connection
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Trigger sync when app becomes active
        SyncManager.shared.attemptSync()
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
