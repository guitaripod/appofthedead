import XCTest
@testable import aotd

final class ContentLoaderTests: XCTestCase {
    var contentLoader: ContentLoader!
    
    override func setUpWithError() throws {
        contentLoader = ContentLoader()
    }
    
    override func tearDownWithError() throws {
        contentLoader = nil
    }
    
    // MARK: - File Structure Tests
    
    func testBeliefSystemFilesExist() throws {
        // Test that we have the expected number of belief system files
        let expectedBeliefSystems = [
            "judaism", "christianity", "islam", "hinduism", "buddhism",
            "sikhism", "egyptian-afterlife", "greek-underworld", "norse",
            "aztec-mictlan", "zoroastrianism", "shinto", "taoism",
            "mandaeism", "wicca", "bahai", "tenrikyo", "aboriginal-dreamtime",
            "native-american-visions", "anthroposophy", "theosophy", "swedenborgian-visions"
        ]
        
        let beliefSystems = contentLoader.loadBeliefSystems()
        let loadedIds = beliefSystems.map { $0.id }
        
        XCTAssertEqual(beliefSystems.count, 22, "Should load exactly 22 belief systems")
        
        // Check that all expected belief systems are present
        for expectedId in expectedBeliefSystems {
            XCTAssertTrue(loadedIds.contains(expectedId), "Missing belief system: \(expectedId)")
        }
    }
    
    func testAchievementsFileExists() throws {
        let achievements = contentLoader.loadAchievements()
        XCTAssertGreaterThan(achievements.count, 0, "Should load at least one achievement")
    }
    
    func testLoadBeliefSystems() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        XCTAssertGreaterThan(beliefSystems.count, 0, "Should load at least one belief system")
        
        // Check if Judaism is present
        let judaism = beliefSystems.first { $0.id == "judaism" }
        XCTAssertNotNil(judaism, "Judaism should be present in belief systems")
        XCTAssertEqual(judaism?.name, "Judaism")
        XCTAssertGreaterThan(judaism?.lessons.count ?? 0, 0, "Judaism should have lessons")
        XCTAssertNotNil(judaism?.masteryTest, "Judaism should have a mastery test")
    }
    
    func testLoadAchievements() throws {
        let achievements = contentLoader.loadAchievements()
        
        XCTAssertGreaterThan(achievements.count, 0, "Should load at least one achievement")
        
        // Check if first_step achievement is present
        let firstStep = achievements.first { $0.id == "first_step" }
        XCTAssertNotNil(firstStep, "First Step achievement should be present")
        XCTAssertEqual(firstStep?.name, "First Step")
        XCTAssertEqual(firstStep?.criteria.type, .completeLesson)
    }
    
    func testBeliefSystemStructure() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        guard let judaism = beliefSystems.first(where: { $0.id == "judaism" }) else {
            XCTFail("Judaism not found")
            return
        }
        
        // Test belief system properties
        XCTAssertEqual(judaism.name, "Judaism")
        XCTAssertFalse(judaism.description.isEmpty)
        XCTAssertFalse(judaism.icon.isEmpty)
        XCTAssertFalse(judaism.color.isEmpty)
        XCTAssertGreaterThan(judaism.totalXP, 0)
        
        // Test lessons
        XCTAssertGreaterThan(judaism.lessons.count, 0)
        let firstLesson = judaism.lessons.first!
        XCTAssertFalse(firstLesson.id.isEmpty)
        XCTAssertFalse(firstLesson.title.isEmpty)
        XCTAssertFalse(firstLesson.content.isEmpty)
        XCTAssertGreaterThan(firstLesson.order, 0)
        XCTAssertGreaterThan(firstLesson.xpReward, 0)
        XCTAssertGreaterThan(firstLesson.questions.count, 0)
        
        // Test questions
        let firstQuestion = firstLesson.questions.first!
        XCTAssertFalse(firstQuestion.id.isEmpty)
        XCTAssertFalse(firstQuestion.question.isEmpty)
        XCTAssertFalse(firstQuestion.explanation.isEmpty)
        
        // Test mastery test
        XCTAssertFalse(judaism.masteryTest.id.isEmpty)
        XCTAssertFalse(judaism.masteryTest.title.isEmpty)
        XCTAssertGreaterThan(judaism.masteryTest.requiredScore, 0)
        XCTAssertGreaterThan(judaism.masteryTest.xpReward, 0)
        XCTAssertGreaterThan(judaism.masteryTest.questions.count, 0)
    }
    
    func testAchievementStructure() throws {
        let achievements = contentLoader.loadAchievements()
        
        guard let firstStep = achievements.first(where: { $0.id == "first_step" }) else {
            XCTFail("First Step achievement not found")
            return
        }
        
        XCTAssertEqual(firstStep.name, "First Step")
        XCTAssertFalse(firstStep.description.isEmpty)
        XCTAssertFalse(firstStep.icon.isEmpty)
        XCTAssertEqual(firstStep.criteria.type, .completeLesson)
        
        if case .int(let value) = firstStep.criteria.value {
            XCTAssertEqual(value, 1)
        } else {
            XCTFail("Expected int criteria value for first_step achievement")
        }
    }
    
    func testDifferentAchievementCriteriaTypes() throws {
        let achievements = contentLoader.loadAchievements()
        
        // Test string criteria (completePath)
        if let scholarAchievement = achievements.first(where: { $0.id == "scholar_of_sheol" }) {
            XCTAssertEqual(scholarAchievement.criteria.type, .completePath)
            if case .string(let value) = scholarAchievement.criteria.value {
                XCTAssertEqual(value, "judaism")
            } else {
                XCTFail("Expected string criteria value for scholar_of_sheol achievement")
            }
        }
        
        // Test int criteria (totalXP)
        if let wisdomAchievement = achievements.first(where: { $0.id == "wisdom_seeker" }) {
            XCTAssertEqual(wisdomAchievement.criteria.type, .totalXP)
            if case .int(let value) = wisdomAchievement.criteria.value {
                XCTAssertEqual(value, 1000)
            } else {
                XCTFail("Expected int criteria value for wisdom_seeker achievement")
            }
        }
        
        // Test bool criteria (completeAllPaths)
        if let masterAchievement = achievements.first(where: { $0.id == "afterlife_master" }) {
            XCTAssertEqual(masterAchievement.criteria.type, .completeAllPaths)
            if case .bool(let value) = masterAchievement.criteria.value {
                XCTAssertTrue(value)
            } else {
                XCTFail("Expected bool criteria value for afterlife_master achievement")
            }
        }
    }
    
    func testQuestionTypes() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        var foundMultipleChoice = false
        var foundTrueFalse = false
        var foundMatching = false
        
        for beliefSystem in beliefSystems {
            for lesson in beliefSystem.lessons {
                for question in lesson.questions {
                    switch question.type {
                    case .multipleChoice:
                        foundMultipleChoice = true
                        XCTAssertNotNil(question.options, "Multiple choice questions should have options")
                        XCTAssertGreaterThan(question.options?.count ?? 0, 1)
                    case .trueFalse:
                        foundTrueFalse = true
                    case .matching:
                        foundMatching = true
                        XCTAssertNotNil(question.pairs, "Matching questions should have pairs")
                        XCTAssertGreaterThan(question.pairs?.count ?? 0, 0)
                    }
                }
            }
            
            // Also check mastery test questions
            for question in beliefSystem.masteryTest.questions {
                if question.type == .matching {
                    foundMatching = true
                }
            }
        }
        
        XCTAssertTrue(foundMultipleChoice, "Should find at least one multiple choice question")
        XCTAssertTrue(foundTrueFalse, "Should find at least one true/false question")
        XCTAssertTrue(foundMatching, "Should find at least one matching question")
    }
    
    func testCaching() throws {
        // First load
        let beliefSystems1 = contentLoader.loadBeliefSystems()
        let achievements1 = contentLoader.loadAchievements()
        
        // Second load (should use cache)
        let beliefSystems2 = contentLoader.loadBeliefSystems()
        let achievements2 = contentLoader.loadAchievements()
        
        XCTAssertEqual(beliefSystems1.count, beliefSystems2.count)
        XCTAssertEqual(achievements1.count, achievements2.count)
        
        // Test reload functionality
        contentLoader.reloadContent()
        let beliefSystems3 = contentLoader.loadBeliefSystems()
        XCTAssertEqual(beliefSystems1.count, beliefSystems3.count)
    }
    
    // MARK: - Split Files Tests
    
    func testEachBeliefSystemFileIsValid() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        for beliefSystem in beliefSystems {
            // Verify essential properties
            XCTAssertFalse(beliefSystem.id.isEmpty, "Belief system \(beliefSystem.id) has empty ID")
            XCTAssertFalse(beliefSystem.name.isEmpty, "Belief system \(beliefSystem.id) has empty name")
            XCTAssertFalse(beliefSystem.description.isEmpty, "Belief system \(beliefSystem.id) has empty description")
            XCTAssertFalse(beliefSystem.icon.isEmpty, "Belief system \(beliefSystem.id) has empty icon")
            XCTAssertFalse(beliefSystem.color.isEmpty, "Belief system \(beliefSystem.id) has empty color")
            XCTAssertGreaterThan(beliefSystem.totalXP, 0, "Belief system \(beliefSystem.id) has zero or negative XP")
            XCTAssertGreaterThan(beliefSystem.lessons.count, 0, "Belief system \(beliefSystem.id) has no lessons")
            XCTAssertNotNil(beliefSystem.masteryTest, "Belief system \(beliefSystem.id) has no mastery test")
        }
    }
    
    func testBeliefSystemsAreSortedConsistently() throws {
        // Load multiple times to ensure consistent ordering
        let firstLoad = contentLoader.loadBeliefSystems().map { $0.id }
        
        contentLoader.reloadContent()
        let secondLoad = contentLoader.loadBeliefSystems().map { $0.id }
        
        XCTAssertEqual(firstLoad, secondLoad, "Belief systems should load in consistent order")
    }
    
    func testSplitFilesContentIntegrity() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        // Ensure we're loading the same content as before
        let judaism = beliefSystems.first { $0.id == "judaism" }
        XCTAssertNotNil(judaism)
        XCTAssertEqual(judaism?.name, "Judaism")
        XCTAssertEqual(judaism?.totalXP, 160)
        
        // Check a few other belief systems
        let christianity = beliefSystems.first { $0.id == "christianity" }
        XCTAssertNotNil(christianity)
        XCTAssertEqual(christianity?.name, "Christianity")
        
        let buddhism = beliefSystems.first { $0.id == "buddhism" }
        XCTAssertNotNil(buddhism)
        XCTAssertEqual(buddhism?.name, "Buddhism")
    }
    
    func testLessonOrder() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        for beliefSystem in beliefSystems {
            let lessons = beliefSystem.lessons
            for i in 0..<lessons.count {
                XCTAssertEqual(lessons[i].order, i + 1, "Lesson order should be sequential starting from 1")
            }
        }
    }
    
    func testKeyTermsAndXP() throws {
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        for beliefSystem in beliefSystems {
            // Test that totalXP is positive
            XCTAssertGreaterThan(beliefSystem.totalXP, 0, "Belief system should have positive total XP")
            
            for lesson in beliefSystem.lessons {
                XCTAssertGreaterThan(lesson.xpReward, 0, "Each lesson should have XP reward")
                XCTAssertGreaterThan(lesson.keyTerms.count, 0, "Each lesson should have key terms")
            }
            
            // Test mastery test XP
            XCTAssertGreaterThan(beliefSystem.masteryTest.xpReward, 0, "Mastery test should have XP reward")
        }
    }
}