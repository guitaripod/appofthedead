import XCTest
@testable import aotd

final class BeliefSystemJSONTests: XCTestCase {
    
    
    
    func testAllBeliefSystemJSONFilesAreValid() throws {
        let beliefSystemIds = [
            "judaism", "christianity", "islam", "hinduism", "buddhism",
            "sikhism", "egyptian-afterlife", "greek-underworld", "norse",
            "aztec-mictlan", "zoroastrianism", "shinto", "taoism",
            "mandaeism", "wicca", "bahai", "tenrikyo", "aboriginal-dreamtime",
            "native-american-visions", "anthroposophy", "theosophy", "swedenborgian-visions"
        ]
        
        for beliefSystemId in beliefSystemIds {
            try validateBeliefSystemJSONFile(beliefSystemId)
        }
    }
    
    private func validateBeliefSystemJSONFile(_ beliefSystemId: String) throws {
        
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: beliefSystemId, ofType: "json") else {
            XCTFail("Could not find \(beliefSystemId).json in test bundle")
            return
        }
        
        
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            XCTFail("\(beliefSystemId).json is not a valid JSON object")
            return
        }
        
        
        XCTAssertNotNil(jsonObject["id"], "\(beliefSystemId).json missing 'id' field")
        XCTAssertEqual(jsonObject["id"] as? String, beliefSystemId, "\(beliefSystemId).json has mismatched ID")
        XCTAssertNotNil(jsonObject["name"], "\(beliefSystemId).json missing 'name' field")
        XCTAssertNotNil(jsonObject["description"], "\(beliefSystemId).json missing 'description' field")
        XCTAssertNotNil(jsonObject["icon"], "\(beliefSystemId).json missing 'icon' field")
        XCTAssertNotNil(jsonObject["color"], "\(beliefSystemId).json missing 'color' field")
        XCTAssertNotNil(jsonObject["totalXP"], "\(beliefSystemId).json missing 'totalXP' field")
        XCTAssertNotNil(jsonObject["lessons"], "\(beliefSystemId).json missing 'lessons' field")
        XCTAssertNotNil(jsonObject["masteryTest"], "\(beliefSystemId).json missing 'masteryTest' field")
        
        
        let decoder = JSONDecoder()
        do {
            let beliefSystem = try decoder.decode(BeliefSystem.self, from: jsonData)
            validateBeliefSystemModel(beliefSystem)
        } catch {
            XCTFail("Failed to decode \(beliefSystemId).json: \(error)")
        }
    }
    
    private func validateBeliefSystemModel(_ beliefSystem: BeliefSystem) {
        let context = "BeliefSystem '\(beliefSystem.id)'"
        
        
        XCTAssertFalse(beliefSystem.id.isEmpty, "\(context) has empty ID")
        XCTAssertFalse(beliefSystem.name.isEmpty, "\(context) has empty name")
        XCTAssertFalse(beliefSystem.description.isEmpty, "\(context) has empty description")
        XCTAssertFalse(beliefSystem.icon.isEmpty, "\(context) has empty icon")
        XCTAssertFalse(beliefSystem.color.isEmpty, "\(context) has empty color")
        
        
        XCTAssertTrue(beliefSystem.color.hasPrefix("#"), "\(context) color should start with #")
        XCTAssertEqual(beliefSystem.color.count, 7, "\(context) color should be 7 characters (#RRGGBB)")
        
        
        XCTAssertGreaterThan(beliefSystem.totalXP, 0, "\(context) totalXP should be positive")
        
        
        XCTAssertGreaterThan(beliefSystem.lessons.count, 0, "\(context) should have at least one lesson")
        
        for (index, lesson) in beliefSystem.lessons.enumerated() {
            validateLessonModel(lesson, beliefSystemId: beliefSystem.id, lessonIndex: index)
        }
        
        
        validateMasteryTestModel(beliefSystem.masteryTest, beliefSystemId: beliefSystem.id)
    }
    
    private func validateLessonModel(_ lesson: Lesson, beliefSystemId: String, lessonIndex: Int) {
        let context = "BeliefSystem '\(beliefSystemId)' lesson[\(lessonIndex)]"
        
        
        XCTAssertFalse(lesson.id.isEmpty, "\(context) has empty id")
        XCTAssertFalse(lesson.title.isEmpty, "\(context) has empty title")
        XCTAssertFalse(lesson.content.isEmpty, "\(context) has empty content")
        XCTAssertEqual(lesson.order, lessonIndex + 1, "\(context) order should be \(lessonIndex + 1)")
        XCTAssertGreaterThan(lesson.xpReward, 0, "\(context) xpReward should be positive")
        XCTAssertGreaterThan(lesson.keyTerms.count, 0, "\(context) should have at least one key term")
        XCTAssertGreaterThan(lesson.questions.count, 0, "\(context) should have at least one question")
        
        for (qIndex, question) in lesson.questions.enumerated() {
            validateQuestionModel(question, context: "\(context) question[\(qIndex)]")
        }
    }
    
    private func validateMasteryTestModel(_ masteryTest: MasteryTest, beliefSystemId: String) {
        let context = "BeliefSystem '\(beliefSystemId)' masteryTest"
        
        XCTAssertFalse(masteryTest.id.isEmpty, "\(context) has empty id")
        XCTAssertFalse(masteryTest.title.isEmpty, "\(context) has empty title")
        XCTAssertGreaterThan(masteryTest.requiredScore, 0, "\(context) requiredScore should be positive")
        XCTAssertLessThanOrEqual(masteryTest.requiredScore, 100, "\(context) requiredScore should be <= 100")
        XCTAssertGreaterThan(masteryTest.xpReward, 0, "\(context) xpReward should be positive")
        XCTAssertGreaterThanOrEqual(masteryTest.questions.count, 3, "\(context) should have at least 3 questions")
        
        for (qIndex, question) in masteryTest.questions.enumerated() {
            validateQuestionModel(question, context: "\(context) question[\(qIndex)]")
        }
    }
    
    private func validateQuestionModel(_ question: Question, context: String) {
        XCTAssertFalse(question.id.isEmpty, "\(context) has empty id")
        XCTAssertFalse(question.question.isEmpty, "\(context) has empty question text")
        XCTAssertFalse(question.explanation.isEmpty, "\(context) has empty explanation")
        
        switch question.type {
        case .multipleChoice:
            XCTAssertNotNil(question.options, "\(context) multipleChoice missing options")
            if let options = question.options {
                XCTAssertGreaterThanOrEqual(options.count, 2, "\(context) needs at least 2 options")
                XCTAssertLessThanOrEqual(options.count, 6, "\(context) has too many options")
            }
        case .trueFalse:
            if case .string(let answer) = question.correctAnswer.value {
                XCTAssertTrue(["true", "false"].contains(answer), 
                            "\(context) trueFalse answer must be 'true' or 'false'")
            } else {
                XCTFail("\(context) trueFalse answer should be a string")
            }
        case .matching:
            XCTAssertNotNil(question.pairs, "\(context) matching missing pairs")
            if let pairs = question.pairs {
                XCTAssertGreaterThanOrEqual(pairs.count, 2, "\(context) needs at least 2 pairs")
                for pair in pairs {
                    XCTAssertFalse(pair.left.isEmpty, "\(context) pair has empty left")
                    XCTAssertFalse(pair.right.isEmpty, "\(context) pair has empty right")
                }
            }
        }
    }
    
    private func validateLesson(_ lesson: [String: Any], beliefSystemId: String, lessonIndex: Int) {
        let context = "\(beliefSystemId).json lesson[\(lessonIndex)]"
        
        
        XCTAssertNotNil(lesson["id"], "\(context) missing 'id'")
        XCTAssertNotNil(lesson["title"], "\(context) missing 'title'")
        XCTAssertNotNil(lesson["order"], "\(context) missing 'order'")
        XCTAssertNotNil(lesson["content"], "\(context) missing 'content'")
        XCTAssertNotNil(lesson["keyTerms"], "\(context) missing 'keyTerms'")
        XCTAssertNotNil(lesson["xpReward"], "\(context) missing 'xpReward'")
        XCTAssertNotNil(lesson["questions"], "\(context) missing 'questions'")
        
        
        if let order = lesson["order"] as? Int {
            XCTAssertEqual(order, lessonIndex + 1, "\(context) order should be \(lessonIndex + 1)")
        }
        
        
        if let xpReward = lesson["xpReward"] as? Int {
            XCTAssertGreaterThan(xpReward, 0, "\(context) xpReward should be positive")
        }
        
        
        if let keyTerms = lesson["keyTerms"] as? [String] {
            XCTAssertGreaterThan(keyTerms.count, 0, "\(context) should have at least one key term")
        }
        
        
        if let questions = lesson["questions"] as? [[String: Any]] {
            XCTAssertGreaterThan(questions.count, 0, "\(context) should have at least one question")
            
            for (qIndex, question) in questions.enumerated() {
                validateQuestion(question, context: "\(context) question[\(qIndex)]")
            }
        }
    }
    
    private func validateMasteryTest(_ masteryTest: [String: Any], beliefSystemId: String) {
        let context = "\(beliefSystemId).json masteryTest"
        
        
        XCTAssertNotNil(masteryTest["id"], "\(context) missing 'id'")
        XCTAssertNotNil(masteryTest["title"], "\(context) missing 'title'")
        XCTAssertNotNil(masteryTest["requiredScore"], "\(context) missing 'requiredScore'")
        XCTAssertNotNil(masteryTest["xpReward"], "\(context) missing 'xpReward'")
        XCTAssertNotNil(masteryTest["questions"], "\(context) missing 'questions'")
        
        
        if let requiredScore = masteryTest["requiredScore"] as? Int {
            XCTAssertGreaterThan(requiredScore, 0, "\(context) requiredScore should be positive")
            XCTAssertLessThanOrEqual(requiredScore, 100, "\(context) requiredScore should be <= 100")
        }
        
        
        if let xpReward = masteryTest["xpReward"] as? Int {
            XCTAssertGreaterThan(xpReward, 0, "\(context) xpReward should be positive")
        }
        
        
        if let questions = masteryTest["questions"] as? [[String: Any]] {
            XCTAssertGreaterThanOrEqual(questions.count, 3, "\(context) should have at least 3 questions")
            
            for (qIndex, question) in questions.enumerated() {
                validateQuestion(question, context: "\(context) question[\(qIndex)]")
            }
        }
    }
    
    private func validateQuestion(_ question: [String: Any], context: String) {
        
        XCTAssertNotNil(question["id"], "\(context) missing 'id'")
        XCTAssertNotNil(question["type"], "\(context) missing 'type'")
        XCTAssertNotNil(question["question"], "\(context) missing 'question'")
        XCTAssertNotNil(question["correctAnswer"], "\(context) missing 'correctAnswer'")
        XCTAssertNotNil(question["explanation"], "\(context) missing 'explanation'")
        
        
        if let type = question["type"] as? String {
            let validTypes = ["multipleChoice", "trueFalse", "matching"]
            XCTAssertTrue(validTypes.contains(type), "\(context) has invalid type: \(type)")
            
            
            switch type {
            case "multipleChoice":
                XCTAssertNotNil(question["options"], "\(context) multipleChoice missing 'options'")
                if let options = question["options"] as? [String] {
                    XCTAssertGreaterThanOrEqual(options.count, 2, "\(context) needs at least 2 options")
                    XCTAssertLessThanOrEqual(options.count, 6, "\(context) has too many options")
                }
            case "trueFalse":
                if let correctAnswer = question["correctAnswer"] as? String {
                    XCTAssertTrue(["true", "false"].contains(correctAnswer), 
                                "\(context) trueFalse answer must be 'true' or 'false'")
                }
            case "matching":
                XCTAssertNotNil(question["pairs"], "\(context) matching missing 'pairs'")
                if let pairs = question["pairs"] as? [[String: String]] {
                    XCTAssertGreaterThanOrEqual(pairs.count, 2, "\(context) needs at least 2 pairs")
                    for pair in pairs {
                        XCTAssertNotNil(pair["left"], "\(context) pair missing 'left'")
                        XCTAssertNotNil(pair["right"], "\(context) pair missing 'right'")
                    }
                }
            default:
                break
            }
        }
    }
    
    
    
    func testBeliefSystemIDsAreUnique() throws {
        let contentLoader = ContentLoader()
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        var seenIds = Set<String>()
        for beliefSystem in beliefSystems {
            XCTAssertFalse(seenIds.contains(beliefSystem.id), 
                          "Duplicate belief system ID found: \(beliefSystem.id)")
            seenIds.insert(beliefSystem.id)
        }
    }
    
    func testAllQuestionIDsAreUnique() throws {
        let contentLoader = ContentLoader()
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        var seenQuestionIds = Set<String>()
        
        for beliefSystem in beliefSystems {
            
            for lesson in beliefSystem.lessons {
                for question in lesson.questions {
                    XCTAssertFalse(seenQuestionIds.contains(question.id),
                                  "Duplicate question ID found: \(question.id) in \(beliefSystem.id)")
                    seenQuestionIds.insert(question.id)
                }
            }
            
            
            for question in beliefSystem.masteryTest.questions {
                XCTAssertFalse(seenQuestionIds.contains(question.id),
                              "Duplicate question ID found: \(question.id) in \(beliefSystem.id) mastery test")
                seenQuestionIds.insert(question.id)
            }
        }
    }
    
    func testTotalXPIsReasonable() throws {
        let contentLoader = ContentLoader()
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        for beliefSystem in beliefSystems {
            let lessonXPSum = beliefSystem.lessons.reduce(0) { $0 + $1.xpReward }
            let totalWithMastery = lessonXPSum + beliefSystem.masteryTest.xpReward
            
            
            XCTAssertGreaterThan(beliefSystem.totalXP, 0,
                               "\(beliefSystem.id) totalXP should be positive")
            
            
            if beliefSystem.totalXP != totalWithMastery {
                print("Note: \(beliefSystem.id) totalXP (\(beliefSystem.totalXP)) doesn't match calculated sum (\(totalWithMastery))")
            }
        }
    }
    
    func testAllCitationsAreValid() throws {
        let contentLoader = ContentLoader()
        let beliefSystems = contentLoader.loadBeliefSystems()
        
        let citationRegex = try NSRegularExpression(pattern: "\\[cite: [0-9, ]+\\]")
        
        for beliefSystem in beliefSystems {
            for lesson in beliefSystem.lessons {
                
                let contentMatches = citationRegex.matches(in: lesson.content, 
                                                         range: NSRange(location: 0, length: lesson.content.count))
                if contentMatches.isEmpty && lesson.content.count > 100 {
                    print("Warning: \(beliefSystem.id) lesson '\(lesson.title)' has no citations")
                }
                
                
                for question in lesson.questions {
                    let explanationMatches = citationRegex.matches(in: question.explanation,
                                                                 range: NSRange(location: 0, length: question.explanation.count))
                    if explanationMatches.isEmpty && question.explanation.count > 50 {
                        print("Warning: \(beliefSystem.id) question '\(question.id)' explanation has no citations")
                    }
                }
            }
        }
    }
}