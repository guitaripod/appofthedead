import Foundation

public struct BeliefSystem: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let color: String
    public let totalXP: Int
    public let lessons: [Lesson]
    public let masteryTest: MasteryTest

    public init(id: String, name: String, description: String, icon: String, color: String, totalXP: Int, lessons: [Lesson], masteryTest: MasteryTest) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.totalXP = totalXP
        self.lessons = lessons
        self.masteryTest = masteryTest
    }
}

public struct Lesson: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let order: Int
    public let content: String
    public let keyTerms: [String]
    public let xpReward: Int
    public let questions: [Question]

    public init(id: String, title: String, order: Int, content: String, keyTerms: [String], xpReward: Int, questions: [Question]) {
        self.id = id
        self.title = title
        self.order = order
        self.content = content
        self.keyTerms = keyTerms
        self.xpReward = xpReward
        self.questions = questions
    }
}

public struct Question: Codable, Identifiable, Sendable {
    public let id: String
    public let type: QuestionType
    public let question: String
    public let options: [String]?
    public let pairs: [MatchingPair]?
    public let correctAnswer: CorrectAnswer
    public let explanation: String

    public init(id: String, type: QuestionType, question: String, options: [String]?, pairs: [MatchingPair]?, correctAnswer: CorrectAnswer, explanation: String) {
        self.id = id
        self.type = type
        self.question = question
        self.options = options
        self.pairs = pairs
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }

    public enum QuestionType: String, Codable, Sendable {
        case multipleChoice = "multipleChoice"
        case trueFalse = "trueFalse"
        case matching = "matching"
    }

    public struct MatchingPair: Codable, Sendable {
        public let left: String
        public let right: String

        public init(left: String, right: String) {
            self.left = left
            self.right = right
        }
    }
}

public struct CorrectAnswer: Codable, Sendable {
    public let value: AnswerValue

    public init(value: AnswerValue) {
        self.value = value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self.value = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self.value = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(CorrectAnswer.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode CorrectAnswer"))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case .string(let str):
            try container.encode(str)
        case .array(let arr):
            try container.encode(arr)
        }
    }

    public enum AnswerValue: Codable, Sendable {
        case string(String)
        case array([String])

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let arrayValue = try? container.decode([String].self) {
                self = .array(arrayValue)
            } else {
                throw DecodingError.typeMismatch(AnswerValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode CorrectAnswer"))
            }
        }

        public func encode(to encoder: any Encoder) throws {
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

public struct MasteryTest: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let requiredScore: Int
    public let xpReward: Int
    public let questions: [Question]

    public init(id: String, title: String, requiredScore: Int, xpReward: Int, questions: [Question]) {
        self.id = id
        self.title = title
        self.requiredScore = requiredScore
        self.xpReward = xpReward
        self.questions = questions
    }
}

public struct Answer: Codable, Sendable {
    public let questionId: String
    public let userAnswer: String
    public let isCorrect: Bool
    public let timeSpent: TimeInterval
    public let attemptedAt: Date

    public init(questionId: String, userAnswer: String, isCorrect: Bool, timeSpent: TimeInterval = 0) {
        self.questionId = questionId
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.attemptedAt = Date()
    }
}
