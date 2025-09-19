import Foundation
import UIKit
import GRDB



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
    let mistakeCount: Int
}



final class HomeViewModel {
    
    
    
    private let databaseManager: DatabaseManager
    let contentLoader: ContentLoader
    private(set) var beliefSystems: [BeliefSystem] = []
    private var user: User?
    private(set) var userProgress: [String: Progress] = [:]
    private(set) var pathPreviews: [String: PathPreview] = [:]
    
    var onDataUpdate: (() -> Void)?
    var onUserDataUpdate: ((User) -> Void)?
    var onPathSelected: ((BeliefSystem) -> Void)?
    
    private(set) var pathItems: [PathItem] = []
    
    var currentUser: User? {
        return user
    }
    
    
    
    init(databaseManager: DatabaseManager, contentLoader: ContentLoader) {
        self.databaseManager = databaseManager
        self.contentLoader = contentLoader
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    func loadData() {
        loadUser()
        loadBeliefSystems()
        loadUserProgress()
        loadPathPreviews()
        updatePathItems()
    }
    
    func selectPath(_ item: PathItem) {
        guard let beliefSystem = beliefSystems.first(where: { $0.id == item.id }) else { return }
        onPathSelected?(beliefSystem)
    }
    
    func resetProgress(for beliefSystemId: String) {
        guard let userId = user?.id else { return }
        
        AppLogger.logUserAction("resetProgress", parameters: ["beliefSystemId": beliefSystemId])
        
        do {
            
            try databaseManager.deleteProgress(userId: userId, beliefSystemId: beliefSystemId)
            
            
            userProgress.removeValue(forKey: beliefSystemId)
            
            
            loadUserProgress()
            updatePathItems()
            
            AppLogger.learning.info("Progress reset", metadata: [
                "userId": userId,
                "beliefSystemId": beliefSystemId
            ])
        } catch {
            AppLogger.logError(error, context: "Resetting progress", logger: AppLogger.learning, additionalInfo: [
                "userId": userId,
                "beliefSystemId": beliefSystemId
            ])
        }
    }
    
    
    
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
        
        loadData()
    }
    
    @objc private func handleEntitlementsUpdated() {
        
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
        
        let beliefSystemProgress = allProgress.filter { $0.lessonId == nil }
        userProgress = Dictionary(
            uniqueKeysWithValues: beliefSystemProgress.map { ($0.beliefSystemId, $0) }
        )
    }
    
    private func loadPathPreviews() {
        guard let url = Bundle.main.url(forResource: "path_previews", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let previews = try? JSONDecoder().decode([String: PathPreview].self, from: data) else {
            AppLogger.content.error("Failed to load path previews")
            return
        }
        pathPreviews = previews
    }
    
    private func updatePathItems() {
        pathItems = beliefSystems.map { beliefSystem in
            let progress = userProgress[beliefSystem.id]
            let currentXP = progress?.earnedXP ?? 0
            let isUnlocked = checkIfUnlocked(beliefSystem)
            let progressPercentage = Float(currentXP) / Float(beliefSystem.totalXP)
            let status = progress?.status ?? .notStarted
            
            
            var mistakeCount = 0
            if let userId = user?.id {
                mistakeCount = (try? databaseManager.getMistakeCount(userId: userId, beliefSystemId: beliefSystem.id)) ?? 0
            }
            
            return PathItem(
                id: beliefSystem.id,
                name: beliefSystem.name,
                icon: beliefSystem.icon,
                color: UIColor(hex: beliefSystem.color) ?? .systemGray,
                totalXP: beliefSystem.totalXP,
                currentXP: currentXP,
                isUnlocked: isUnlocked,
                progress: progressPercentage,
                status: status,
                mistakeCount: mistakeCount
            )
        }
        
        
        pathItems.sort { item1, item2 in
            
            if item1.isUnlocked == item2.isUnlocked {
                
                let index1 = beliefSystems.firstIndex { $0.id == item1.id } ?? Int.max
                let index2 = beliefSystems.firstIndex { $0.id == item2.id } ?? Int.max
                return index1 < index2
            }
            
            return item1.isUnlocked && !item2.isUnlocked
        }
        
        onDataUpdate?()
    }
    
    private func checkIfUnlocked(_ beliefSystem: BeliefSystem) -> Bool {
        
        if StoreManager.shared.hasPathAccess(beliefSystem.id) {
            return true
        }
        
        
        guard let user = user else { return false }
        return user.hasPathAccess(beliefSystemId: beliefSystem.id)
    }
    
    func pathPreview(for beliefSystemId: String) -> PathPreview? {
        return pathPreviews[beliefSystemId]
    }
}

