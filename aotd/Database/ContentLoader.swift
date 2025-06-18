import Foundation

class ContentLoader {
    private var cachedData: ContentData?
    private var cachedDeities: [String: Deity]?
    
    struct ContentData: Codable {
        let beliefSystems: [BeliefSystem]
        let achievements: [Achievement]
    }
    
    struct DeityData: Codable {
        let deities: [String: Deity]
    }
    
    func loadBeliefSystems() -> [BeliefSystem] {
        if let cached = cachedData {
            return cached.beliefSystems
        }
        
        guard let data = loadContentData() else {
            return []
        }
        
        cachedData = data
        return data.beliefSystems
    }
    
    func loadAchievements() -> [Achievement] {
        if let cached = cachedData {
            return cached.achievements
        }
        
        guard let data = loadContentData() else {
            return []
        }
        
        cachedData = data
        return data.achievements
    }
    
    private func loadContentData() -> ContentData? {
        // Try main bundle first, then test bundle (for testing)
        var bundle = Bundle.main
        var path = bundle.path(forResource: "aotd", ofType: "json")
        
        if path == nil {
            // If not found in main bundle, try the bundle containing this class
            bundle = Bundle(for: type(of: self))
            path = bundle.path(forResource: "aotd", ofType: "json")
        }
        
        guard let validPath = path,
              let jsonData = NSData(contentsOfFile: validPath) as Data? else {
            print("Error: Could not find aotd.json file in any bundle")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let contentData = try decoder.decode(ContentData.self, from: jsonData)
            return contentData
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
    
    func reloadContent() {
        cachedData = nil
        cachedDeities = nil
    }
    
    func loadDeities() -> [String: Deity] {
        if let cached = cachedDeities {
            return cached
        }
        
        // Try main bundle first, then test bundle (for testing)
        var bundle = Bundle.main
        var path = bundle.path(forResource: "deity_prompts", ofType: "json")
        
        if path == nil {
            // If not found in main bundle, try the bundle containing this class
            bundle = Bundle(for: type(of: self))
            path = bundle.path(forResource: "deity_prompts", ofType: "json")
        }
        
        guard let validPath = path,
              let jsonData = NSData(contentsOfFile: validPath) as Data? else {
            print("Error: Could not find deity_prompts.json file in any bundle")
            return [:]
        }
        
        do {
            let decoder = JSONDecoder()
            let deityData = try decoder.decode(DeityData.self, from: jsonData)
            cachedDeities = deityData.deities
            return deityData.deities
        } catch {
            print("Error decoding deity JSON: \(error)")
            return [:]
        }
    }
    
    func getDeityForBeliefSystem(_ beliefSystemId: String) -> Deity? {
        let deities = loadDeities()
        
        // Use The Eternal for all belief systems - the universal cosmic consciousness
        return deities["the_eternal"] ?? deities["anubis"] // Fallback to Anubis if The Eternal is not found
    }
}