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
        
        
        let iconsActivity = AppLogger.beginActivity("IconProvider.createCustomIcons")
        IconProvider.createCustomIcons()
        AppLogger.endActivity("IconProvider.createCustomIcons", id: iconsActivity)
        
        
        let contentLoaderActivity = AppLogger.beginActivity("ContentLoader.init")
        let contentLoader = ContentLoader()
        AppLogger.endActivity("ContentLoader.init", id: contentLoaderActivity)
        
        
        databaseManager.setContentLoader(contentLoader)
        
        
        DispatchQueue.global(qos: .background).async {
            let bookGenerator = BookContentGenerator(
                databaseManager: self.databaseManager,
                contentLoader: contentLoader
            )
            bookGenerator.generateAndSaveAllBooks()
        }
        
        
        let homeActivity = AppLogger.beginActivity("HomeViewController.setup")
        let homeViewModel = HomeViewModel(
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        let homeNavigationController = UINavigationController(rootViewController: homeViewController)
        AppLogger.endActivity("HomeViewController.setup", id: homeActivity)
        
        
        let profileActivity = AppLogger.beginActivity("ProfileViewController.setup")
        let profileViewModel = ProfileViewModel(databaseManager: databaseManager)
        let profileViewController = ProfileViewController(viewModel: profileViewModel)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)
        AppLogger.endActivity("ProfileViewController.setup", id: profileActivity)
        
        
        let settingsViewController = SettingsViewController()
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        
        
        let oracleViewController = OracleViewController()
        let oracleNavigationController = UINavigationController(rootViewController: oracleViewController)
        
        
        let libraryActivity = AppLogger.beginActivity("BookLibraryViewController.setup")
        let libraryViewModel = BookLibraryViewModel(
            userId: databaseManager.fetchUser()?.id ?? "",
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let libraryViewController = BookLibraryViewController(viewModel: libraryViewModel)
        let libraryNavigationController = UINavigationController(rootViewController: libraryViewController)
        AppLogger.endActivity("BookLibraryViewController.setup", id: libraryActivity)
        
        
        // Create adaptive navigation container
        let adaptiveContainer = AdaptiveNavigationContainer(
            homeNav: homeNavigationController,
            profileNav: profileNavigationController,
            oracleNav: oracleNavigationController,
            libraryNav: libraryNavigationController,
            settingsNav: settingsNavigationController
        )
        
        
        configureNavigationBarAppearance()
        
        
        setupNavigationFlow(
            homeViewModel: homeViewModel,
            navigationController: homeNavigationController,
            contentLoader: contentLoader
        )
        
        self.window?.rootViewController = adaptiveContainer
        self.window?.makeKeyAndVisible()
        
        
        UserDefaults.standard.removeObject(forKey: SessionState.currentBeliefSystemKey)
        
        AppLogger.endActivity("SceneSetup", id: sceneSetupActivity, metadata: [
            "viewControllerCount": 5
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
        
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLogger.ui.info("Scene will enter foreground")
        
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        AppLogger.ui.info("Scene did become active")
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        
        appearance.backgroundColor = UIColor.Papyrus.cardBackground
        
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.primaryText,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.primaryText,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.Papyrus.gold
        ]
        appearance.buttonAppearance = buttonAppearance
        
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.Papyrus.gold
    }

}
