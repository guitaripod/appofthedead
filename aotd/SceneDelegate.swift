import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var learningPathCoordinator: LearningPathCoordinator?
    private let databaseManager = DatabaseManager.shared
    private weak var rootContainer: AdaptiveNavigationContainer?
    private weak var homeViewController: HomeViewController?
    
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
        
        
        generateBooksInBackgroundUnlessDemo(contentLoader: contentLoader)
        
        
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
        rootContainer = adaptiveContainer
        self.homeViewController = homeViewController

        _ = AchievementNotificationManager.shared

        if shouldPresentWelcome() {
            GameCenterManager.shared.deferAuthentication()
            presentWelcome(over: adaptiveContainer, homeViewModel: homeViewModel)
        } else if !isRunningDemoRoute {
            GameCenterManager.shared.authenticate()
        }

        presentDemoRouteIfRequested(
            over: adaptiveContainer,
            homeNavigation: homeNavigationController,
            oracleNavigation: oracleNavigationController,
            homeViewModel: homeViewModel,
            contentLoader: contentLoader
        )

        UserDefaults.standard.removeObject(forKey: SessionState.currentBeliefSystemKey)

        if let url = connectionOptions.urlContexts.first?.url {
            DispatchQueue.main.async { [weak self] in
                self?.open(url)
            }
        }
        
        AppLogger.endActivity("SceneSetup", id: sceneSetupActivity, metadata: [
            "viewControllerCount": 5
        ])
        AppLogger.ui.info("Scene setup complete")
    }
    
    private func shouldPresentWelcome() -> Bool {
        guard !isRunningDemoRoute else { return false }
        return FirstRunWelcome().shouldPresent(hasExistingProgress: hasExistingProgress())
    }

    private var isRunningDemoRoute: Bool {
        #if DEBUG
        DemoWorld.isActive
        #else
        false
        #endif
    }

    /// Books are generated once, off the main thread. The screenshot rig builds them up front
    /// instead, so the library is complete on the first frame.
    private func generateBooksInBackgroundUnlessDemo(contentLoader: ContentLoader) {
        #if DEBUG
        if DemoWorld.isActive {
            DemoWorld.prepare(database: databaseManager, contentLoader: contentLoader)
            return
        }
        #endif
        DispatchQueue.global(qos: .background).async {
            let bookGenerator = BookContentGenerator(
                databaseManager: self.databaseManager,
                contentLoader: contentLoader
            )
            bookGenerator.generateAndSaveAllBooks()
        }
    }

    private func hasExistingProgress() -> Bool {
        guard let user = databaseManager.fetchUser() else { return false }
        return user.totalXP > 0 || !databaseManager.fetchProgress(for: user.id).isEmpty
    }

    /// Presents the welcome after the first frame is on screen, then hands the user to the free
    /// Judaism path's first lesson. If that path can't be found the user simply lands on Home.
    private func presentWelcome(over root: AdaptiveNavigationContainer, homeViewModel: HomeViewModel) {
        let welcome = WelcomeViewController { [weak root, weak homeViewModel] in
            FirstRunWelcome().markCompleted()
            AppLogger.logUserAction("welcomeStarted")
            root?.dismiss(animated: true) {
                guard let judaism = DatabaseManager.shared.loadBeliefSystems().first(where: { $0.id == "judaism" }) else {
                    AppLogger.ui.error("Welcome could not find the Judaism path; landing on Home")
                    GameCenterManager.shared.resumeDeferredAuthentication()
                    return
                }
                homeViewModel?.onPathSelected?(judaism)
            }
        }
        root.present(welcome, animated: false)
        AppLogger.ui.info("Presented first-run welcome")
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
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        open(url)
    }

    /// Clears whatever is on screen and routes to the linked destination, so an in-app event card
    /// lands on its path no matter where the app was left.
    private func open(_ url: URL) {
        guard let link = DeepLink(url: url) else {
            AppLogger.ui.warning("Ignored unrecognized URL \(url.absoluteString, privacy: .public)")
            return
        }
        AppLogger.logUserAction("openDeepLink", parameters: ["url": url.absoluteString])
        switch link {
        case .path(let beliefSystemId):
            rootContainer?.dismiss(animated: false)
            rootContainer?.selectViewController(at: 0)
            homeViewController?.openPath(withId: beliefSystemId)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLogger.ui.info("Scene did enter background")
        
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLogger.ui.info("Scene will enter foreground")
        GameCenterManager.shared.synchronize()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        AppLogger.ui.info("Scene did become active")
    }
    
    private func presentDemoRouteIfRequested(
        over root: AdaptiveNavigationContainer,
        homeNavigation: UINavigationController,
        oracleNavigation: UINavigationController,
        homeViewModel: HomeViewModel,
        contentLoader: ContentLoader
    ) {
        #if DEBUG
        DemoWorld.present(DemoContext(
            root: root,
            homeNavigation: homeNavigation,
            oracleNavigation: oracleNavigation,
            homeViewModel: homeViewModel,
            contentLoader: contentLoader
        ))
        #endif
    }

    /// On iOS 26+ navigation bars keep the system Liquid Glass material; only the
    /// tint is branded. Forcing an opaque background would suppress the glass.
    private func configureNavigationBarAppearance() {
        if #available(iOS 26.0, *) {
            UINavigationBar.appearance().tintColor = UIColor.Papyrus.gold
            return
        }
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
