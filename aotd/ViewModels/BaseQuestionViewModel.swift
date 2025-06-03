import UIKit

protocol QuestionViewModelDelegate: AnyObject {
    func questionViewModel(_ viewModel: BaseQuestionViewModel, didAnswerCorrectly: Bool)
}

class BaseQuestionViewModel {
    
    weak var delegate: QuestionViewModelDelegate?
    
    let question: Question
    let beliefSystem: BeliefSystem
    let currentQuestionIndex: Int
    let totalQuestions: Int
    
    var questionText: String {
        question.question
    }
    
    var progress: Float {
        Float(currentQuestionIndex + 1) / Float(totalQuestions)
    }
    
    var beliefSystemColor: UIColor? {
        UIColor(hex: beliefSystem.color)
    }
    
    var xpReward: Int {
        // Base XP calculation - can be overridden
        10
    }
    
    init(question: Question, beliefSystem: BeliefSystem, currentQuestionIndex: Int, totalQuestions: Int) {
        self.question = question
        self.beliefSystem = beliefSystem
        self.currentQuestionIndex = currentQuestionIndex
        self.totalQuestions = totalQuestions
    }
    
    func checkAnswer(_ answer: String) -> (isCorrect: Bool, explanation: String) {
        let isCorrect: Bool
        switch question.correctAnswer.value {
        case .string(let correctAnswer):
            isCorrect = answer == correctAnswer
        case .array(let correctAnswers):
            isCorrect = correctAnswers.contains(answer)
        }
        return (isCorrect, question.explanation)
    }
}

