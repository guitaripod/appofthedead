import Foundation

/// Lightweight iCloud sync manager for essential user progress continuity
/// Handles syncing of user level, XP, and completed belief systems using NSUbiquitousKeyValueStore
/// Designed for hardware upgrade scenarios with minimal data footprint and automatic operation
class iCloudSyncManager {
    /// Shared singleton instance
    static let shared = iCloudSyncManager()

    /// iCloud Key-Value Store instance
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    /// Key used for storing continuity data in iCloud
    private let syncKey = "com.appofthedead.continuity"
    /// Minimum time between sync operations (5 minutes)
    private let maxSyncInterval: TimeInterval = 300

    /// Timestamp of last successful sync
    private var lastSyncDate: Date?
    /// Whether the manager is observing iCloud changes
    private var isObservingChanges = false

    // MARK: - Sync Data Structure

    /// Essential user progress data for iCloud sync
    struct ContinuityData: Codable {
        /// User's current level
        let level: Int
        /// Total XP earned by user
        let xp: Int
        /// Set of completed belief system IDs
        let completedPaths: Set<String>
        /// Timestamp of last sync
        let syncTimestamp: Date

        /// Check if synced data has expired (30 days)
        var isExpired: Bool {
            Date().timeIntervalSince(syncTimestamp) > (30 * 24 * 60 * 60)
        }
    }

    // MARK: - Initialization

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

    // MARK: - Public Interface

    /// Sync current user progress to iCloud
    /// Automatically throttles syncs to prevent excessive iCloud usage
    /// - Parameter user: Current user data containing level and XP
    /// - Parameter completedPaths: Set of completed belief system IDs
    func syncProgress(user: User, completedPaths: Set<String>) {
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < maxSyncInterval {
            return
        }

        let continuityData = ContinuityData(
            level: user.currentLevel,
            xp: user.totalXP,
            completedPaths: completedPaths,
            syncTimestamp: Date()
        )

        do {
            let data = try JSONEncoder().encode(continuityData)
            keyValueStore.set(data, forKey: syncKey)
            keyValueStore.synchronize()

            lastSyncDate = Date()
            AppLogger.general.info("Progress synced to iCloud", metadata: [
                "level": user.currentLevel,
                "xp": user.totalXP,
                "completedPathsCount": completedPaths.count
            ])
        } catch {
            AppLogger.logError(error, context: "Failed to sync progress to iCloud", logger: AppLogger.general)
        }
    }

    /// Retrieve synced progress from iCloud
    /// Automatically clears expired data (older than 30 days)
    /// - Returns: ContinuityData if available and not expired, nil otherwise
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

    /// Clear all synced progress data from iCloud
    /// Used when data is corrupted or expired
    func clearSyncedProgress() {
        keyValueStore.removeObject(forKey: syncKey)
        keyValueStore.synchronize()
        AppLogger.general.info("Cleared synced progress from iCloud")
    }

    /// Check if iCloud is available for syncing
    /// Returns false if user is not signed into iCloud or iCloud is disabled
    var isCloudSyncAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - Private Methods

    /// Handle external changes to iCloud data
    /// Called when another device modifies the synced data
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

// MARK: - Notifications

/// Notification posted when iCloud sync data changes externally
extension Notification.Name {
    static let iCloudSyncDataChanged = Notification.Name("iCloudSyncDataChanged")
}