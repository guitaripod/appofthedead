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

        NotificationManager.shared.clearBadge()

        let storeActivity = Diagnostics.beginActivity("StoreManager.start")
        StoreManager.shared.start()
        Diagnostics.endActivity("StoreManager.start", since: storeActivity)
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
}
