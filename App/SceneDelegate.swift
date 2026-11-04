import UIKit
import MidgarCore
import AppOfTheDeadCore

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var learningPathCoordinator: LearningPathCoordinator?
    private let databaseManager = DatabaseManager.shared
    private weak var rootContainer: AdaptiveNavigationContainer?
    private weak var homeViewController: HomeViewController?
    private weak var oracleViewController: OracleViewController?
    
    private struct SessionState {
        static let currentBeliefSystemKey = "currentBeliefSystemId"
    }

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        MidgarLog.info("Scene will connect to session", category: .ui)
        let sceneSetupActivity = Diagnostics.beginActivity("SceneSetup")
        
        self.window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .dark
        window?.tintColor = UIColor.Papyrus.gold
        
        
        let iconsActivity = Diagnostics.beginActivity("IconProvider.createCustomIcons")
        IconProvider.createCustomIcons()
        Diagnostics.endActivity("IconProvider.createCustomIcons", since: iconsActivity)
        
        
        let contentLoaderActivity = Diagnostics.beginActivity("ContentLoader.init")
        let contentLoader = ContentLoader()
        Diagnostics.endActivity("ContentLoader.init", since: contentLoaderActivity)
        
        
        databaseManager.setContentLoader(contentLoader)
        
        
        generateBooksInBackgroundUnlessDemo(contentLoader: contentLoader)
        
        
        let homeActivity = Diagnostics.beginActivity("HomeViewController.setup")
        let homeViewModel = HomeViewModel(
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let homeViewController = HomeViewController(viewModel: homeViewModel)
        let homeNavigationController = UINavigationController(rootViewController: homeViewController)
        Diagnostics.endActivity("HomeViewController.setup", since: homeActivity)
        
        
        let profileActivity = Diagnostics.beginActivity("ProfileViewController.setup")
        let profileViewModel = ProfileViewModel(databaseManager: databaseManager)
        let profileViewController = ProfileViewController(viewModel: profileViewModel)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)
        Diagnostics.endActivity("ProfileViewController.setup", since: profileActivity)
        
        
        let settingsViewController = SettingsViewController()
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        
        
        let oracleViewController = OracleViewController()
        let oracleNavigationController = UINavigationController(rootViewController: oracleViewController)
        
        
        let libraryActivity = Diagnostics.beginActivity("BookLibraryViewController.setup")
        let libraryViewModel = BookLibraryViewModel(
            userId: databaseManager.fetchUser()?.id ?? "",
            databaseManager: databaseManager,
            contentLoader: contentLoader
        )
        let libraryViewController = BookLibraryViewController(viewModel: libraryViewModel)
        let libraryNavigationController = UINavigationController(rootViewController: libraryViewController)
        Diagnostics.endActivity("BookLibraryViewController.setup", since: libraryActivity)
        
        
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
        self.oracleViewController = oracleViewController

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
        
        Diagnostics.endActivity("SceneSetup", since: sceneSetupActivity, metadata: [
            "viewControllerCount": 5
        ])
        MidgarLog.info("Scene setup complete", category: .ui)
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

    /// The first run is the Judgment. Skipping it starts the free Judaism path's first lesson, as 1.x did; finishing it
    /// goes where the verdict points.
    private func presentWelcome(over root: AdaptiveNavigationContainer, homeViewModel: HomeViewModel) {
        let judgment = JudgmentViewController(viewModel: JudgmentViewModel(entry: .firstRun)) { [weak self, weak root, weak homeViewModel] outcome in
            FirstRunWelcome().markCompleted()
            Diagnostics.logUserAction("welcomeFinished", parameters: ["outcome": "\(outcome)"])
            root?.dismiss(animated: true) {
                GameCenterManager.shared.resumeDeferredAuthentication()
                if outcome == .skipped {
                    self?.startFreePath(homeViewModel: homeViewModel)
                } else {
                    self?.route(outcome)
                }
            }
        }
        root.present(judgment, animated: false)
        MidgarLog.info("Presented the first-run Judgment", category: .ui)
    }

    private func startFreePath(homeViewModel: HomeViewModel?) {
        guard let judaism = DatabaseManager.shared.loadBeliefSystems().first(where: { $0.id == "judaism" }) else {
            MidgarLog.error("Welcome could not find the Judaism path; landing on Home", category: .ui)
            return
        }
        homeViewModel?.onPathSelected?(judaism)
    }

    /// Sends the person where they chose to go from the Judgment.
    func route(_ outcome: JudgmentOutcome) {
        switch outcome {
        case .skipped, .done:
            return
        case .path(let pathId):
            rootContainer?.selectViewController(at: 0)
            homeViewController?.openPath(withId: pathId)
        case .oracle(let deityId):
            rootContainer?.selectViewController(at: 2)
            let draft = JudgmentStore().verdict.map {
                String(localized: "The Judgment named me \(JudgmentCopy.archetypeName($0.archetype)). What does that say about my soul?")
            }
            oracleViewController?.openConversation(withDeityId: deityId, draft: draft)
        }
    }

    /// Presents the Judgment from anywhere: on a saved verdict to look at it, or fresh to take it again.
    func presentJudgment(reviewing: Bool) {
        guard let root = rootContainer else { return }
        let entry: JudgmentViewModel.Entry
        if reviewing, let verdict = JudgmentStore().verdict {
            entry = .review(verdict)
        } else {
            entry = .retake
        }
        let judgment = JudgmentViewController(viewModel: JudgmentViewModel(entry: entry)) { [weak self, weak root] outcome in
            root?.dismiss(animated: true) {
                self?.route(outcome)
            }
        }
        let presenter = root.presentedViewController ?? root
        presenter.present(judgment, animated: true)
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
        Diagnostics.logUserAction("startLearningPath", parameters: [
            "beliefSystemId": beliefSystem.id,
            "beliefSystemName": beliefSystem.name
        ], category: .learning)
        
        
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
            MidgarLog.notice("Ignored unrecognized URL \(url.absoluteString)", category: .ui)
            return
        }
        Diagnostics.logUserAction("openDeepLink", parameters: ["url": url.absoluteString])
        switch link {
        case .path(let beliefSystemId):
            rootContainer?.dismiss(animated: false)
            rootContainer?.selectViewController(at: 0)
            homeViewController?.openPath(withId: beliefSystemId)
        case .judgment:
            rootContainer?.dismiss(animated: false)
            presentJudgment(reviewing: false)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        MidgarLog.info("Scene did enter background", category: .ui)
        
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        MidgarLog.info("Scene will enter foreground", category: .ui)
        GameCenterManager.shared.synchronize()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        MidgarLog.info("Scene did become active", category: .ui)
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
