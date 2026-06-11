import Foundation




class iCloudSyncManager {
    
    static let shared = iCloudSyncManager()

    
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    
    private let syncKey = "com.appofthedead.continuity"
    
    private let maxSyncInterval: TimeInterval = 300

    
    private var lastSyncDate: Date?
    
    private var isObservingChanges = false

    

    
    struct ContinuityData: Codable {
        
        let level: Int
        
        let xp: Int
        
        let completedPaths: Set<String>
        
        let syncTimestamp: Date

        
        var isExpired: Bool {
            Date().timeIntervalSince(syncTimestamp) > (30 * 24 * 60 * 60)
        }
    }

    

    private init() {
        setupObservers()
    }

    deinit {
        if isObservingChanges {
            NotificationCenter.default.removeObserver(self)
        }
    }

    private func setupObservers() {
        guard !isObservingChanges else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeyValueStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: keyValueStore
        )

        keyValueStore.synchronize()
        isObservingChanges = true

        AppLogger.general.info("iCloud sync manager initialized")
    }

    

    
    
    
    
    func syncProgress(user: User, completedPaths: Set<String>) {
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < maxSyncInterval {
            return
        }

        let cloudData = storedContinuityData()
        let mergedPaths = completedPaths.union(cloudData?.completedPaths ?? [])

        if let cloudData,
           user.totalXP <= cloudData.xp,
           user.currentLevel <= cloudData.level,
           mergedPaths == cloudData.completedPaths {
            AppLogger.general.debug("Skipping iCloud sync: cloud snapshot is ahead of local progress")
            return
        }

        let continuityData = ContinuityData(
            level: max(user.currentLevel, cloudData?.level ?? 0),
            xp: max(user.totalXP, cloudData?.xp ?? 0),
            completedPaths: mergedPaths,
            syncTimestamp: Date()
        )

        do {
            let data = try JSONEncoder().encode(continuityData)
            keyValueStore.set(data, forKey: syncKey)
            keyValueStore.synchronize()

            lastSyncDate = Date()
            AppLogger.general.info("Progress synced to iCloud", metadata: [
                "level": continuityData.level,
                "xp": continuityData.xp,
                "completedPathsCount": continuityData.completedPaths.count
            ])
        } catch {
            AppLogger.logError(error, context: "Failed to sync progress to iCloud", logger: AppLogger.general)
        }
    }

    private func storedContinuityData() -> ContinuityData? {
        guard let data = keyValueStore.data(forKey: syncKey),
              let cloudData = try? JSONDecoder().decode(ContinuityData.self, from: data),
              !cloudData.isExpired else {
            return nil
        }
        return cloudData
    }

    
    
    
    func retrieveSyncedProgress() -> ContinuityData? {
        guard let data = keyValueStore.data(forKey: syncKey) else {
            AppLogger.general.debug("No synced progress found in iCloud")
            return nil
        }

        do {
            let continuityData = try JSONDecoder().decode(ContinuityData.self, from: data)

            if continuityData.isExpired {
                AppLogger.general.info("Synced progress expired, clearing")
                clearSyncedProgress()
                return nil
            }

            AppLogger.general.info("Retrieved synced progress from iCloud", metadata: [
                "level": continuityData.level,
                "xp": continuityData.xp,
                "completedPathsCount": continuityData.completedPaths.count,
                "syncAge": Date().timeIntervalSince(continuityData.syncTimestamp)
            ])

            return continuityData
        } catch {
            AppLogger.logError(error, context: "Failed to decode synced progress from iCloud", logger: AppLogger.general)
            clearSyncedProgress()
            return nil
        }
    }



    func startMonitoringCloudChanges() {
        keyValueStore.synchronize()
    }

    /// A user's explicit path reset must win over the merge-on-push union, or the
    /// reset path resurrects on every restore; rewrite the snapshot without it.
    func removeCompletedPath(_ beliefSystemId: String) {
        guard let cloudData = storedContinuityData(),
              cloudData.completedPaths.contains(beliefSystemId) else { return }

        let updated = ContinuityData(
            level: cloudData.level,
            xp: cloudData.xp,
            completedPaths: cloudData.completedPaths.subtracting([beliefSystemId]),
            syncTimestamp: Date()
        )

        do {
            let data = try JSONEncoder().encode(updated)
            keyValueStore.set(data, forKey: syncKey)
            keyValueStore.synchronize()
            AppLogger.general.info("Removed reset path from iCloud snapshot", metadata: ["beliefSystemId": beliefSystemId])
        } catch {
            AppLogger.logError(error, context: "Failed to remove path from iCloud snapshot", logger: AppLogger.general)
        }
    }



    func clearSyncedProgress() {
        keyValueStore.removeObject(forKey: syncKey)
        keyValueStore.synchronize()
        AppLogger.general.info("Cleared synced progress from iCloud")
    }

    
    
    var isCloudSyncAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    

    
    
    @objc private func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
              changedKeys.contains(syncKey) else {
            return
        }

        AppLogger.general.info("iCloud sync data changed externally")

        NotificationCenter.default.post(
            name: .iCloudSyncDataChanged,
            object: self
        )
    }
}




extension Notification.Name {
    static let iCloudSyncDataChanged = Notification.Name("iCloudSyncDataChanged")
}