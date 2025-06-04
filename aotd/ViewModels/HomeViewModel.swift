import Foundation
import UIKit

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
}

// MARK: - HomeViewModel

final class HomeViewModel {
    
    // MARK: - Properties
    
    private let databaseManager: DatabaseManager
    private let contentLoader: ContentLoader
    private var beliefSystems: [BeliefSystem] = []
    private var user: User?
    private var userProgress: [String: Progress] = [:]
    
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
    
    private func loadUser() {
        user = databaseManager.fetchUser()
        if let user = user {
            print("🏠 HomeViewModel loaded user with \(user.totalXP) total XP")
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
            
            print("🏠 Path \(beliefSystem.name): \(currentXP)/\(beliefSystem.totalXP) XP")
            
            return PathItem(
                id: beliefSystem.id,
                name: beliefSystem.name,
                icon: beliefSystem.icon,
                color: UIColor(hex: beliefSystem.color) ?? .systemGray,
                totalXP: beliefSystem.totalXP,
                currentXP: currentXP,
                isUnlocked: isUnlocked,
                progress: progressPercentage
            )
        }
        
        onDataUpdate?()
    }
    
    private func checkIfUnlocked(_ beliefSystem: BeliefSystem) -> Bool {
        // First three paths are always unlocked
        let firstThreeIds = ["judaism", "christianity", "islam"]
        if firstThreeIds.contains(beliefSystem.id) {
            return true
        }
        
        // Check if user has completed at least one path
        let completedPaths = userProgress.values.filter { progress in
            let beliefSystem = beliefSystems.first { $0.id == progress.beliefSystemId }
            return progress.currentXP >= (beliefSystem?.totalXP ?? Int.max)
        }
        
        return !completedPaths.isEmpty
    }
}

