import Foundation
import UIKit
import GRDB

// MARK: - PathItem

struct PathItem: Hashable {
    let id: String
    let name: String
    let icon: String
    let color: UIColor
    let totalXP: Int
    let currentXP: Int
    let isUnlocked: Bool
    let progress: Float
    let status: Progress.ProgressStatus
}

// MARK: - HomeViewModel

final class HomeViewModel {
    
    // MARK: - Properties
    
    private let databaseManager: DatabaseManager
    let contentLoader: ContentLoader
    private(set) var beliefSystems: [BeliefSystem] = []
    private var user: User?
    private(set) var userProgress: [String: Progress] = [:]
    
    var onDataUpdate: (() -> Void)?
    var onUserDataUpdate: ((User) -> Void)?
    var onPathSelected: ((BeliefSystem) -> Void)?
    
    private(set) var pathItems: [PathItem] = []
    
    var currentUser: User? {
        return user
    }
    
    // MARK: - Initialization
    
    init(databaseManager: DatabaseManager, contentLoader: ContentLoader) {
        self.databaseManager = databaseManager
        self.contentLoader = contentLoader
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        loadUser()
        loadBeliefSystems()
        loadUserProgress()
        updatePathItems()
    }
    
    func selectPath(_ item: PathItem) {
        guard let beliefSystem = beliefSystems.first(where: { $0.id == item.id }) else { return }
        onPathSelected?(beliefSystem)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePurchaseCompleted),
            name: StoreManager.purchaseCompletedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEntitlementsUpdated),
            name: StoreManager.entitlementsUpdatedNotification,
            object: nil
        )
    }
    
    @objc private func handlePurchaseCompleted() {
        // Reload data to reflect new purchases
        loadData()
    }
    
    @objc private func handleEntitlementsUpdated() {
        // Reload data to reflect updated entitlements
        loadData()
    }
    
    private func loadUser() {
        user = databaseManager.fetchUser()
        if let user = user {
            onUserDataUpdate?(user)
        }
    }
    
    private func loadBeliefSystems() {
        beliefSystems = contentLoader.loadBeliefSystems()
    }
    
    private func loadUserProgress() {
        guard let userId = user?.id else { return }
        
        let allProgress = databaseManager.fetchProgress(for: userId)
        // Filter to only belief system level progress (where lessonId is nil)
        let beliefSystemProgress = allProgress.filter { $0.lessonId == nil }
        userProgress = Dictionary(
            uniqueKeysWithValues: beliefSystemProgress.map { ($0.beliefSystemId, $0) }
        )
    }
    
    private func updatePathItems() {
        pathItems = beliefSystems.map { beliefSystem in
            let progress = userProgress[beliefSystem.id]
            let currentXP = progress?.earnedXP ?? 0
            let isUnlocked = checkIfUnlocked(beliefSystem)
            let progressPercentage = Float(currentXP) / Float(beliefSystem.totalXP)
            let status = progress?.status ?? .notStarted
            
            return PathItem(
                id: beliefSystem.id,
                name: beliefSystem.name,
                icon: beliefSystem.icon,
                color: UIColor(hex: beliefSystem.color) ?? .systemGray,
                totalXP: beliefSystem.totalXP,
                currentXP: currentXP,
                isUnlocked: isUnlocked,
                progress: progressPercentage,
                status: status
            )
        }
        
        // Sort paths: unlocked first, then by original order
        pathItems.sort { item1, item2 in
            // If both have same unlock status, maintain original order
            if item1.isUnlocked == item2.isUnlocked {
                // Find original indices
                let index1 = beliefSystems.firstIndex { $0.id == item1.id } ?? Int.max
                let index2 = beliefSystems.firstIndex { $0.id == item2.id } ?? Int.max
                return index1 < index2
            }
            // Otherwise, unlocked paths come first
            return item1.isUnlocked && !item2.isUnlocked
        }
        
        onDataUpdate?()
    }
    
    private func checkIfUnlocked(_ beliefSystem: BeliefSystem) -> Bool {
        // Check RevenueCat for access first, then fall back to local database
        if StoreManager.shared.hasPathAccess(beliefSystem.id) {
            return true
        }
        
        // Fall back to local database check
        guard let user = user else { return false }
        return user.hasPathAccess(beliefSystemId: beliefSystem.id)
    }
}

