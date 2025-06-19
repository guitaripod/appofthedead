import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize RevenueCat
        StoreManager.shared.configure()
        
        // Initialize content loader with database manager
        let contentLoader = ContentLoader()
        DatabaseManager.shared.setContentLoader(contentLoader)
        
        return true
    }
}
