import XCTest
@testable import aotd

final class AchievementsJSONTests: XCTestCase {
    
    func testAchievementsJSONFileExists() throws {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "achievements", ofType: "json")
        XCTAssertNotNil(path, "achievements.json should exist in test bundle")
    }
    
    func testAchievementsJSONStructure() throws {
        
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "achievements", ofType: "json") else {
            XCTFail("Could not find achievements.json in test bundle")
            return
        }
        
        
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        
        guard let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            XCTFail("achievements.json is not a valid JSON array")
            return
        }
        
        XCTAssertGreaterThan(jsonArray.count, 0, "achievements.json should contain at least one achievement")
        XCTAssertEqual(jsonArray.count, 10, "achievements.json should contain exactly 10 achievements")
        
        
        for (index, achievement) in jsonArray.enumerated() {
            validateAchievementJSON(achievement, index: index)
        }
        
        
        let decoder = JSONDecoder()
        do {
            let achievements = try decoder.decode([Achievement].self, from: jsonData)
            XCTAssertEqual(achievements.count, jsonArray.count, "Decoded achievements count should match JSON")
            
            
            for achievement in achievements {
                XCTAssertFalse(achievement.id.isEmpty, "Achievement ID should not be empty")
                XCTAssertFalse(achievement.name.isEmpty, "Achievement name should not be empty")
                XCTAssertFalse(achievement.description.isEmpty, "Achievement description should not be empty")
                XCTAssertFalse(achievement.icon.isEmpty, "Achievement icon should not be empty")
            }
        } catch {
            XCTFail("Failed to decode achievements.json: \(error)")
        }
    }
    
    private func validateAchievementJSON(_ achievement: [String: Any], index: Int) {
        let context = "achievements.json[\(index)]"
        
        
        XCTAssertNotNil(achievement["id"], "\(context) missing 'id'")
        XCTAssertNotNil(achievement["name"], "\(context) missing 'name'")
        XCTAssertNotNil(achievement["description"], "\(context) missing 'description'")
        XCTAssertNotNil(achievement["icon"], "\(context) missing 'icon'")
        XCTAssertNotNil(achievement["criteria"], "\(context) missing 'criteria'")
        
        
        if let criteria = achievement["criteria"] as? [String: Any] {
            XCTAssertNotNil(criteria["type"], "\(context) criteria missing 'type'")
            XCTAssertNotNil(criteria["value"], "\(context) criteria missing 'value'")
            
            
            if let type = criteria["type"] as? String {
                let validTypes = [
                    "completePath", "completeMultiplePaths", "completeAllPaths",
                    "perfectMasteryTest", "totalXP", "correctQuestions", "completeLesson"
                ]
                XCTAssertTrue(validTypes.contains(type), "\(context) has invalid criteria type: \(type)")
                
                
                switch type {
                case "completePath":
                    XCTAssertTrue(criteria["value"] is String, "\(context) completePath value should be String")
                case "completeMultiplePaths", "totalXP", "correctQuestions", "completeLesson", "perfectMasteryTest":
                    XCTAssertTrue(criteria["value"] is Int, "\(context) \(type) value should be Int")
                case "completeAllPaths":
                    XCTAssertTrue(criteria["value"] is Bool, "\(context) completeAllPaths value should be Bool")
                default:
                    break
                }
            }
        }
    }
    
    func testAchievementIDsAreUnique() throws {
        let contentLoader = ContentLoader()
        let achievements = contentLoader.loadAchievements()
        
        var seenIds = Set<String>()
        for achievement in achievements {
            XCTAssertFalse(seenIds.contains(achievement.id), 
                          "Duplicate achievement ID found: \(achievement.id)")
            seenIds.insert(achievement.id)
        }
    }
    
    func testAchievementPathReferencesExist() throws {
        let contentLoader = ContentLoader()
        let achievements = contentLoader.loadAchievements()
        let beliefSystems = contentLoader.loadBeliefSystems()
        let beliefSystemIds = Set(beliefSystems.map { $0.id })
        
        for achievement in achievements {
            if achievement.criteria.type == .completePath,
               case .string(let pathId) = achievement.criteria.value {
                XCTAssertTrue(beliefSystemIds.contains(pathId),
                            "Achievement '\(achievement.id)' references non-existent path: \(pathId)")
            }
        }
    }
    
    func testAchievementValuesAreReasonable() throws {
        let contentLoader = ContentLoader()
        let achievements = contentLoader.loadAchievements()
        
        for achievement in achievements {
            switch achievement.criteria.type {
            case .totalXP:
                if case .int(let xp) = achievement.criteria.value {
                    XCTAssertGreaterThan(xp, 0, "Achievement '\(achievement.id)' XP should be positive")
                    XCTAssertLessThanOrEqual(xp, 10000, "Achievement '\(achievement.id)' XP seems too high")
                }
            case .correctQuestions:
                if case .int(let count) = achievement.criteria.value {
                    XCTAssertGreaterThan(count, 0, "Achievement '\(achievement.id)' question count should be positive")
                    XCTAssertLessThanOrEqual(count, 1000, "Achievement '\(achievement.id)' question count seems too high")
                }
            case .completeMultiplePaths:
                if case .int(let count) = achievement.criteria.value {
                    XCTAssertGreaterThan(count, 1, "Achievement '\(achievement.id)' path count should be > 1")
                    XCTAssertLessThanOrEqual(count, 22, "Achievement '\(achievement.id)' path count exceeds total paths")
                }
            default:
                break
            }
        }
    }
}