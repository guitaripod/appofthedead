import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        AppLogger.logAppLaunch()

        preWarmAppStoreReceiptURL()

        NotificationManager.shared.clearBadge()

        let storeActivity = AppLogger.beginActivity("StoreManager.configure")
        StoreManager.shared.configure()
        AppLogger.endActivity("StoreManager.configure", id: storeActivity)
        
        
        let contentActivity = AppLogger.beginActivity("ContentLoader.initialize")
        let contentLoader = ContentLoader()
        DatabaseManager.shared.setContentLoader(contentLoader)
        AppLogger.endActivity("ContentLoader.initialize", id: contentActivity)

        let syncActivity = AppLogger.beginActivity("iCloudSync.initialize")
        iCloudSyncManager.shared.startMonitoringCloudChanges()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudSyncDataChanged),
            name: .iCloudSyncDataChanged,
            object: nil
        )
        applyCloudProgressToCurrentUser()
        AppLogger.endActivity("iCloudSync.initialize", id: syncActivity)

        AppLogger.general.info("App initialization complete")
        
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        AppLogger.logMemoryWarning()
    }

    /// Wakes the background model-download session when iOS relaunches the app after
    /// finishing transfers while it was suspended/terminated. Store the handler and
    /// recreate the same-identifier session; the downloader calls it back from
    /// `urlSessionDidFinishEvents`.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == BackgroundModelDownloader.sessionIdentifier else {
            completionHandler()
            return
        }
        BackgroundModelDownloader.shared.setBackgroundCompletion(completionHandler)
        BackgroundModelDownloader.shared.ensureSessionAlive()
    }

    @objc private func cloudSyncDataChanged() {
        DispatchQueue.main.async {
            self.applyCloudProgressToCurrentUser()
        }
    }

    private func applyCloudProgressToCurrentUser() {
        guard let user = DatabaseManager.shared.fetchUser() else { return }
        DatabaseManager.shared.applySyncedProgressIfNeeded(userId: user.id)
    }

    /// RevenueCat reads `Bundle.main.appStoreReceiptURL` on its background queue during
    /// configuration, which crashes at launch on iOS 26.5 devices when the first access
    /// happens off the main thread (RevenueCat/purchases-ios#6886). Touching it on the
    /// main thread first makes the later background access safe. Remove only after the
    /// upstream fix ships.
    private func preWarmAppStoreReceiptURL() {
        _ = Bundle.main.appStoreReceiptURL
    }
}
