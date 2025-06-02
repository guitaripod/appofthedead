import XCTest
@testable import aotd

final class BeliefSystemTests: XCTestCase {
    
    func testQuestionTypeEnum() throws {
        XCTAssertEqual(Question.QuestionType.multipleChoice.rawValue, "multipleChoice")
        XCTAssertEqual(Question.QuestionType.trueFalse.rawValue, "trueFalse")
        XCTAssertEqual(Question.QuestionType.matching.rawValue, "matching")
    }
    
    func testCorrectAnswerStringDecoding() throws {
        let jsonString = """
        {
            "id": "test-q1",
            "type": "multipleChoice",
            "question": "What is the answer?",
            "options": ["A", "B", "C", "D"],
            "correctAnswer": "B",
            "explanation": "B is correct."
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let question = try JSONDecoder().decode(Question.self, from: data)
        
        XCTAssertEqual(question.id, "test-q1")
        XCTAssertEqual(question.type, .multipleChoice)
        XCTAssertEqual(question.options?.count, 4)
        
        if case .string(let answer) = question.correctAnswer.value {
            XCTAssertEqual(answer, "B")
        } else {
            XCTFail("Expected string answer")
        }
    }
    
    func testCorrectAnswerArrayDecoding() throws {
        let jsonString = """
        {
            "id": "test-q2",
            "type": "matching",
            "question": "Match the pairs:",
            "pairs": [
                {"left": "A", "right": "1"},
                {"left": "B", "right": "2"}
            ],
            "correctAnswer": ["A", "1", "B", "2"],
            "explanation": "These are the correct matches."
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let question = try JSONDecoder().decode(Question.self, from: data)
        
        XCTAssertEqual(question.id, "test-q2")
        XCTAssertEqual(question.type, .matching)
        XCTAssertEqual(question.pairs?.count, 2)
        
        if case .array(let answers) = question.correctAnswer.value {
            XCTAssertEqual(answers, ["A", "1", "B", "2"])
        } else {
            XCTFail("Expected array answer")
        }
    }
    
    func testMatchingPairDecoding() throws {
        let jsonString = """
        {
            "left": "Term",
            "right": "Definition"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let pair = try JSONDecoder().decode(Question.MatchingPair.self, from: data)
        
        XCTAssertEqual(pair.left, "Term")
        XCTAssertEqual(pair.right, "Definition")
    }
    
    func testLessonDecoding() throws {
        let jsonString = """
        {
            "id": "lesson1",
            "title": "Introduction",
            "order": 1,
            "content": "This is the content.",
            "keyTerms": ["term1", "term2"],
            "xpReward": 15,
            "questions": [
                {
                    "id": "q1",
                    "type": "trueFalse",
                    "question": "Is this true?",
                    "correctAnswer": "true",
                    "explanation": "Yes, it is."
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let lesson = try JSONDecoder().decode(Lesson.self, from: data)
        
        XCTAssertEqual(lesson.id, "lesson1")
        XCTAssertEqual(lesson.title, "Introduction")
        XCTAssertEqual(lesson.order, 1)
        XCTAssertEqual(lesson.keyTerms.count, 2)
        XCTAssertEqual(lesson.xpReward, 15)
        XCTAssertEqual(lesson.questions.count, 1)
    }
    
    func testMasteryTestDecoding() throws {
        let jsonString = """
        {
            "id": "mastery1",
            "title": "Mastery Test",
            "requiredScore": 80,
            "xpReward": 100,
            "questions": [
                {
                    "id": "mt-q1",
                    "type": "multipleChoice",
                    "question": "What is correct?",
                    "options": ["A", "B", "C"],
                    "correctAnswer": "A",
                    "explanation": "A is correct."
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let masteryTest = try JSONDecoder().decode(MasteryTest.self, from: data)
        
        XCTAssertEqual(masteryTest.id, "mastery1")
        XCTAssertEqual(masteryTest.title, "Mastery Test")
        XCTAssertEqual(masteryTest.requiredScore, 80)
        XCTAssertEqual(masteryTest.xpReward, 100)
        XCTAssertEqual(masteryTest.questions.count, 1)
    }
    
    func testBeliefSystemDecoding() throws {
        let jsonString = """
        {
            "id": "judaism",
            "name": "Judaism",
            "description": "Description of Judaism",
            "icon": "star_of_david",
            "color": "#003F7F",
            "totalXP": 160,
            "lessons": [
                {
                    "id": "lesson1",
                    "title": "Introduction",
                    "order": 1,
                    "content": "Content",
                    "keyTerms": ["term1"],
                    "xpReward": 15,
                    "questions": []
                }
            ],
            "masteryTest": {
                "id": "mastery1",
                "title": "Mastery Test",
                "requiredScore": 80,
                "xpReward": 100,
                "questions": []
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let beliefSystem = try JSONDecoder().decode(BeliefSystem.self, from: data)
        
        XCTAssertEqual(beliefSystem.id, "judaism")
        XCTAssertEqual(beliefSystem.name, "Judaism")
        XCTAssertEqual(beliefSystem.color, "#003F7F")
        XCTAssertEqual(beliefSystem.totalXP, 160)
        XCTAssertEqual(beliefSystem.lessons.count, 1)
        XCTAssertEqual(beliefSystem.masteryTest.requiredScore, 80)
    }
    
    func testAnswerCreation() throws {
        let answer = Answer(questionId: "q1", userAnswer: "A", isCorrect: true, timeSpent: 5.0)
        
        XCTAssertEqual(answer.questionId, "q1")
        XCTAssertEqual(answer.userAnswer, "A")
        XCTAssertTrue(answer.isCorrect)
        XCTAssertEqual(answer.timeSpent, 5.0)
        XCTAssertNotNil(answer.attemptedAt)
    }
    
    func testAnswerDefaultTimeSpent() throws {
        let answer = Answer(questionId: "q1", userAnswer: "A", isCorrect: false)
        
        XCTAssertEqual(answer.timeSpent, 0.0)
    }
}