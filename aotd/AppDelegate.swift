import UIKit
import MidgarCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AotdMidgar.configureLogging()
        Diagnostics.logAppLaunch()

        preWarmAppStoreReceiptURL()

        NotificationManager.shared.clearBadge()

        let storeActivity = Diagnostics.beginActivity("StoreManager.configure")
        StoreManager.shared.configure()
        Diagnostics.endActivity("StoreManager.configure", since: storeActivity)
        AotdMidgar.shared.start()
        ReviewPrompt.beginSession()
        
        
        let contentActivity = Diagnostics.beginActivity("ContentLoader.initialize")
        let contentLoader = ContentLoader()
        DatabaseManager.shared.setContentLoader(contentLoader)
        Diagnostics.endActivity("ContentLoader.initialize", since: contentActivity)

        let syncActivity = Diagnostics.beginActivity("iCloudSync.initialize")
        iCloudSyncManager.shared.startMonitoringCloudChanges()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudSyncDataChanged),
            name: .iCloudSyncDataChanged,
            object: nil
        )
        applyCloudProgressToCurrentUser()
        Diagnostics.endActivity("iCloudSync.initialize", since: syncActivity)

        MidgarLog.info("App initialization complete", category: .general)
        
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Diagnostics.logMemoryWarning()
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

    /// iCloud posts this notification from a queue of its own, so the handler is nonisolated and hops to the main
    /// actor before it touches the database.
    @objc private nonisolated func cloudSyncDataChanged() {
        Task { @MainActor in
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
