import Foundation

class ContentLoader {
    private var cachedData: ContentData?
    
    struct ContentData: Codable {
        let beliefSystems: [BeliefSystem]
        let achievements: [Achievement]
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
    }
}