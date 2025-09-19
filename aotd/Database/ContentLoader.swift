import Foundation

class ContentLoader {
    private var cachedBeliefSystems: [BeliefSystem]?
    private var cachedAchievements: [Achievement]?
    private var cachedDeities: [String: Deity]?
    
    struct DeityData: Codable {
        let deities: [String: Deity]
    }
    
    func loadBeliefSystems() -> [BeliefSystem] {
        if let cached = cachedBeliefSystems {
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
                    AppLogger.logError(error, context: "ContentLoader.loadBeliefSystems",
                                     logger: AppLogger.content,
                                     additionalInfo: ["beliefSystemId": beliefSystemId])
                }
            }
        }
        
        
        beliefSystems.sort { $0.id < $1.id }
        
        cachedBeliefSystems = beliefSystems
        return beliefSystems
    }
    
    func loadAchievements() -> [Achievement] {
        if let cached = cachedAchievements {
            return cached
        }
        
        let bundle = Bundle(for: type(of: self))
        
        guard let path = bundle.path(forResource: "achievements", ofType: "json"),
              let jsonData = NSData(contentsOfFile: path) as Data? else {
            AppLogger.content.error("Could not find achievements.json file in bundle")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let achievements = try decoder.decode([Achievement].self, from: jsonData)
            cachedAchievements = achievements
            return achievements
        } catch {
            AppLogger.logError(error, context: "ContentLoader.loadAchievements", logger: AppLogger.content)
            return []
        }
    }
    
    func reloadContent() {
        cachedBeliefSystems = nil
        cachedAchievements = nil
        cachedDeities = nil
    }
    
    func loadDeities() -> [String: Deity] {
        if let cached = cachedDeities {
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
            AppLogger.content.error("Could not find deity_prompts.json file in any bundle")
            return [:]
        }
        
        do {
            let decoder = JSONDecoder()
            let deityData = try decoder.decode(DeityData.self, from: jsonData)
            cachedDeities = deityData.deities
            return deityData.deities
        } catch {
            AppLogger.logError(error, context: "ContentLoader.loadDeities", logger: AppLogger.content)
            return [:]
        }
    }
    
    func getDeityForBeliefSystem(_ beliefSystemId: String) -> Deity? {
        let deities = loadDeities()
        
        
        return deities["the_eternal"] ?? deities["anubis"] 
    }
}