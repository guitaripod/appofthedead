import Foundation
import MidgarCore
import os




/// Mirrors the learner's level, XP and finished paths to iCloud key-value storage.
///
/// `@unchecked Sendable` because `NSUbiquitousKeyValueStore` is safe to use from any thread, the only mutable state
/// that outlives `init` is the last sync date, which sits behind a lock, and `isObservingChanges` is written once in
/// `init` and read in `deinit`.
nonisolated final class iCloudSyncManager: @unchecked Sendable {
    
    static let shared = iCloudSyncManager()

    
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    
    private let syncKey = "com.appofthedead.continuity"
    
    private let maxSyncInterval: TimeInterval = 300

    
    private let lastSync = OSAllocatedUnfairLock<Date?>(initialState: nil)
    
    private var isObservingChanges = false

    

    
    nonisolated struct ContinuityData: Codable {
        
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

        MidgarLog.info("iCloud sync manager initialized", category: .general)
    }

    

    
    
    
    
    func syncProgress(user: User, completedPaths: Set<String>) {
        if let lastSync = lastSync.withLock({ $0 }),
           Date().timeIntervalSince(lastSync) < maxSyncInterval {
            return
        }

        let cloudData = storedContinuityData()
        let mergedPaths = completedPaths.union(cloudData?.completedPaths ?? [])

        if let cloudData,
           user.totalXP <= cloudData.xp,
           user.currentLevel <= cloudData.level,
           mergedPaths == cloudData.completedPaths {
            MidgarLog.debug("Skipping iCloud sync: cloud snapshot is ahead of local progress", category: .general)
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

            lastSync.withLock { $0 = Date() }
            MidgarLog.info("Progress synced to iCloud", metadata: [
                "level": continuityData.level,
                "xp": continuityData.xp,
                "completedPathsCount": continuityData.completedPaths.count
            ], category: .general)
        } catch {
            Diagnostics.logError(error, context: "Failed to sync progress to iCloud", category: .general)
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
            MidgarLog.debug("No synced progress found in iCloud", category: .general)
            return nil
        }

        do {
            let continuityData = try JSONDecoder().decode(ContinuityData.self, from: data)

            if continuityData.isExpired {
                MidgarLog.info("Synced progress expired, clearing", category: .general)
                clearSyncedProgress()
                return nil
            }

            MidgarLog.info("Retrieved synced progress from iCloud", metadata: [
                "level": continuityData.level,
                "xp": continuityData.xp,
                "completedPathsCount": continuityData.completedPaths.count,
                "syncAge": Date().timeIntervalSince(continuityData.syncTimestamp)
            ], category: .general)

            return continuityData
        } catch {
            Diagnostics.logError(error, context: "Failed to decode synced progress from iCloud", category: .general)
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
            MidgarLog.info("Removed reset path from iCloud snapshot", metadata: ["beliefSystemId": beliefSystemId], category: .general)
        } catch {
            Diagnostics.logError(error, context: "Failed to remove path from iCloud snapshot", category: .general)
        }
    }



    func clearSyncedProgress() {
        keyValueStore.removeObject(forKey: syncKey)
        keyValueStore.synchronize()
        MidgarLog.info("Cleared synced progress from iCloud", category: .general)
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

        MidgarLog.info("iCloud sync data changed externally", category: .general)

        NotificationCenter.default.post(
            name: .iCloudSyncDataChanged,
            object: self
        )
    }
}




nonisolated extension Notification.Name {
    static let iCloudSyncDataChanged = Notification.Name("iCloudSyncDataChanged")
}