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
        let navigationController = UINavigationController(rootViewController: homeViewController)
        
        // Set up navigation flow
        setupNavigationFlow(
            homeViewModel: homeViewModel,
            navigationController: navigationController,
            contentLoader: contentLoader
        )
        
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        // Check if we should resume a learning path
        resumeLearningPathIfNeeded(
            navigationController: navigationController,
            contentLoader: contentLoader
        )
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
    
    private func resumeLearningPathIfNeeded(
        navigationController: UINavigationController,
        contentLoader: ContentLoader
    ) {
        // Check if there's an active learning path session
        guard let beliefSystemId = UserDefaults.standard.string(forKey: SessionState.currentBeliefSystemKey),
              let user = databaseManager.fetchUser() else { 
            return 
        }
        
        
        do {
            // Check if user has inProgress lessons for this belief system
            let userProgress = try databaseManager.getUserProgress(userId: user.id)
            let beliefSystemProgress = userProgress.filter { 
                $0.beliefSystemId == beliefSystemId && $0.lessonId != nil 
            }
            
            // Only resume if there are actually lessons in progress
            let hasInProgressLessons = beliefSystemProgress.contains { 
                $0.status == .inProgress || $0.status == .completed 
            }
            
            guard hasInProgressLessons,
                  let beliefSystem = databaseManager.getBeliefSystem(by: beliefSystemId) else {
                // Clear the session if no valid progress found
                UserDefaults.standard.removeObject(forKey: SessionState.currentBeliefSystemKey)
                return
            }
            
            // Resume the learning path
            DispatchQueue.main.async { [weak self] in
                self?.startLearningPath(
                    beliefSystem: beliefSystem,
                    navigationController: navigationController,
                    contentLoader: contentLoader
                )
            }
            
        } catch {
            UserDefaults.standard.removeObject(forKey: SessionState.currentBeliefSystemKey)
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Session state is already saved when starting learning paths
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Resume functionality is handled in scene connection
    }
}
