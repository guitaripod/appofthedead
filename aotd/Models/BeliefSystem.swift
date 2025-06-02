import Foundation

struct BeliefSystem: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let totalXP: Int
    let lessons: [Lesson]
    let masteryTest: MasteryTest
}

struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let order: Int
    let content: String
    let keyTerms: [String]
    let xpReward: Int
    let questions: [Question]
}

struct Question: Codable, Identifiable {
    let id: String
    let type: QuestionType
    let question: String
    let options: [String]?
    let pairs: [MatchingPair]?
    let correctAnswer: CorrectAnswer
    let explanation: String
    
    enum QuestionType: String, Codable {
        case multipleChoice = "multipleChoice"
        case trueFalse = "trueFalse"
        case matching = "matching"
    }
    
    struct MatchingPair: Codable {
        let left: String
        let right: String
    }
}

struct CorrectAnswer: Codable {
    let value: AnswerValue
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self.value = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self.value = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(CorrectAnswer.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode CorrectAnswer"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case .string(let str):
            try container.encode(str)
        case .array(let arr):
            try container.encode(arr)
        }
    }
    
    enum AnswerValue: Codable {
        case string(String)
        case array([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let arrayValue = try? container.decode([String].self) {
                self = .array(arrayValue)
            } else {
                throw DecodingError.typeMismatch(AnswerValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode CorrectAnswer"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            }
        }
    }
}

struct MasteryTest: Codable, Identifiable {
    let id: String
    let title: String
    let requiredScore: Int
    let xpReward: Int
    let questions: [Question]
}

struct Answer: Codable {
    let questionId: String
    let userAnswer: String
    let isCorrect: Bool
    let timeSpent: TimeInterval
    let attemptedAt: Date
    
    init(questionId: String, userAnswer: String, isCorrect: Bool, timeSpent: TimeInterval = 0) {
        self.questionId = questionId
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.attemptedAt = Date()
    }
}