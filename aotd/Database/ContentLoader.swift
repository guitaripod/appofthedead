import Foundation
import MidgarCore
import os

/// Loads the bundled belief systems, achievements and deities and keeps them in memory.
///
/// The loader is shared between the main thread and the background book generation, so the three caches sit behind
/// one lock, which is what makes it `Sendable`.
nonisolated final class ContentLoader: Sendable {
    private struct Cache {
        var beliefSystems: [BeliefSystem]?
        var achievements: [Achievement]?
        var deities: [String: Deity]?
    }

    private let cache = OSAllocatedUnfairLock(initialState: Cache())

    nonisolated struct DeityData: Codable {
        let deities: [String: Deity]
    }
    
    func loadBeliefSystems() -> [BeliefSystem] {
        if let cached = cache.withLock({ $0.beliefSystems }) {
            return cached
        }
        
        var beliefSystems: [BeliefSystem] = []
        
        
        let beliefSystemIds = [
            "judaism", "christianity", "islam", "hinduism", "buddhism",
            "sikhism", "egyptian-afterlife", "greek-underworld", "norse",
            "aztec-mictlan", "zoroastrianism", "shinto", "taoism",
            "mandaeism", "wicca", "bahai", "tenrikyo", "aboriginal-dreamtime",
            "native-american-visions", "anthroposophy", "theosophy", "swedenborgian-visions"
        ]
        
        
        let bundle = Bundle(for: type(of: self))
        
        for beliefSystemId in beliefSystemIds {
            if let path = bundle.path(forResource: beliefSystemId, ofType: "json"),
               let jsonData = NSData(contentsOfFile: path) as Data? {
                do {
                    let decoder = JSONDecoder()
                    let beliefSystem = try decoder.decode(BeliefSystem.self, from: jsonData)
                    beliefSystems.append(beliefSystem)
                } catch {
                    Diagnostics.logError(error, context: "ContentLoader.loadBeliefSystems",
                                     category: .content,
                                     additionalInfo: ["beliefSystemId": beliefSystemId])
                }
            }
        }
        
        
        beliefSystems.sort { $0.id < $1.id }
        
        let loaded = beliefSystems
        cache.withLock { $0.beliefSystems = loaded }
        return beliefSystems
    }
    
    func loadAchievements() -> [Achievement] {
        if let cached = cache.withLock({ $0.achievements }) {
            return cached
        }
        
        let bundle = Bundle(for: type(of: self))
        
        guard let path = bundle.path(forResource: "achievements", ofType: "json"),
              let jsonData = NSData(contentsOfFile: path) as Data? else {
            MidgarLog.error("Could not find achievements.json file in bundle", category: .content)
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let achievements = try decoder.decode([Achievement].self, from: jsonData)
            cache.withLock { $0.achievements = achievements }
            return achievements
        } catch {
            Diagnostics.logError(error, context: "ContentLoader.loadAchievements", category: .content)
            return []
        }
    }
    
    func reloadContent() {
        cache.withLock { $0 = Cache() }
    }
    
    func loadDeities() -> [String: Deity] {
        if let cached = cache.withLock({ $0.deities }) {
            return cached
        }
        
        
        var bundle = Bundle.main
        var path = bundle.path(forResource: "deity_prompts", ofType: "json")
        
        if path == nil {
            
            bundle = Bundle(for: type(of: self))
            path = bundle.path(forResource: "deity_prompts", ofType: "json")
        }
        
        guard let validPath = path,
              let jsonData = NSData(contentsOfFile: validPath) as Data? else {
            MidgarLog.error("Could not find deity_prompts.json file in any bundle", category: .content)
            return [:]
        }
        
        do {
            let decoder = JSONDecoder()
            let deityData = try decoder.decode(DeityData.self, from: jsonData)
            cache.withLock { $0.deities = deityData.deities }
            return deityData.deities
        } catch {
            Diagnostics.logError(error, context: "ContentLoader.loadDeities", category: .content)
            return [:]
        }
    }
    
    func getDeityForBeliefSystem(_ beliefSystemId: String) -> Deity? {
        let deities = loadDeities()
        
        
        return deities["the_eternal"] ?? deities["anubis"] 
    }
}