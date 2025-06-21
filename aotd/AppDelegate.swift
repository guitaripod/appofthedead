import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Log app launch
        AppLogger.logAppLaunch()
        
        // Initialize RevenueCat
        let storeActivity = AppLogger.beginActivity("StoreManager.configure")
        StoreManager.shared.configure()
        AppLogger.endActivity("StoreManager.configure", id: storeActivity)
        
        // Initialize content loader with database manager
        let contentActivity = AppLogger.beginActivity("ContentLoader.initialize")
        let contentLoader = ContentLoader()
        DatabaseManager.shared.setContentLoader(contentLoader)
        AppLogger.endActivity("ContentLoader.initialize", id: contentActivity)
        
        AppLogger.general.info("App initialization complete")
        
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        AppLogger.logMemoryWarning()
    }
}
