import UIKit

protocol QuestionFlowCoordinatorDelegate: AnyObject {
    func questionFlowCoordinatorDidComplete(_ coordinator: QuestionFlowCoordinator, results: [QuestionResult])
    func questionFlowCoordinatorDidRequestExit(_ coordinator: QuestionFlowCoordinator)
}

struct QuestionResult {
    let question: Question
    let wasCorrect: Bool
}

final class QuestionFlowCoordinator: NSObject {
    
    weak var delegate: QuestionFlowCoordinatorDelegate?
    
    private let navigationController: UINavigationController
    private let questions: [Question]
    private let beliefSystem: BeliefSystem
    private var currentQuestionIndex = 0
    private var results: [QuestionResult] = []
    
    init(navigationController: UINavigationController, questions: [Question], beliefSystem: BeliefSystem) {
        self.navigationController = navigationController
        self.questions = questions
        self.beliefSystem = beliefSystem
        super.init()
    }
    
    func start() {
        showNextQuestion()
    }
    
    private func showNextQuestion() {
        guard currentQuestionIndex < questions.count else {
            
            awardLessonCompletionXP()
            delegate?.questionFlowCoordinatorDidComplete(self, results: results)
            return
        }
        
        let question = questions[currentQuestionIndex]
        let viewController = createViewController(for: question)
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func createViewController(for question: Question) -> UIViewController {
        let viewModel: BaseQuestionViewModel
        let viewController: BaseQuestionViewController
        
        switch question.type {
        case .multipleChoice:
            viewModel = MultipleChoiceViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = MultipleChoiceViewController(viewModel: viewModel)
            
        case .trueFalse:
            viewModel = BaseQuestionViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = TrueFalseViewController(viewModel: viewModel)
            
        case .matching:
            
            viewModel = MultipleChoiceViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = MultipleChoiceViewController(viewModel: viewModel)
        }
        
        viewModel.delegate = self
        
        return viewController
    }
}

extension QuestionFlowCoordinator: QuestionViewModelDelegate {
    func questionViewModel(_ viewModel: BaseQuestionViewModel, didAnswerCorrectly: Bool) {
        let result = QuestionResult(question: viewModel.question, wasCorrect: didAnswerCorrectly)
        results.append(result)
        
        
        if didAnswerCorrectly {
            awardXPForCorrectAnswer(viewModel: viewModel)
        } else {
            
            saveMistake(for: viewModel)
        }
        
        currentQuestionIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNextQuestion()
        }
    }
    
    func questionViewModelDidRequestExit(_ viewModel: BaseQuestionViewModel) {
        delegate?.questionFlowCoordinatorDidRequestExit(self)
    }
    
    private func awardXPForCorrectAnswer(viewModel: BaseQuestionViewModel) {
        guard let user = DatabaseManager.shared.fetchUser() else { return }
        
        let baseXP = viewModel.xpReward
        let multiplier = calculateStreakMultiplier(streakDays: user.streakDays)
        let totalXP = Int(Double(baseXP) * multiplier)
        
        GamificationService.shared.awardXP(
            to: user.id,
            amount: totalXP,
            reason: "Correct answer",
            beliefSystemId: viewModel.beliefSystem.id
        )
    }
    
    private func calculateStreakMultiplier(streakDays: Int) -> Double {
        switch streakDays {
        case 0...2: return 1.0      
        case 3...6: return 1.1      
        case 7...13: return 1.25    
        case 14...29: return 1.5    
        default: return 2.0         
        }
    }
    
    private func awardLessonCompletionXP() {
        guard let user = DatabaseManager.shared.fetchUser() else { return }
        
        
        let lessonBaseXP = 15
        let streakMultiplier = calculateStreakMultiplier(streakDays: user.streakDays)
        let totalXP = Int(Double(lessonBaseXP) * streakMultiplier)
        
        GamificationService.shared.awardXP(
            to: user.id,
            amount: totalXP,
            reason: "Lesson completion",
            beliefSystemId: beliefSystem.id
        )
    }
    
    private func saveMistake(for viewModel: BaseQuestionViewModel) {
        guard let user = DatabaseManager.shared.fetchUser() else { return }
        
        let question = viewModel.question
        let correctAnswer: String
        
        switch question.correctAnswer.value {
        case .string(let answer):
            correctAnswer = answer
        case .array(let answers):
            correctAnswer = answers.first ?? ""
        }
        
        do {
            try DatabaseManager.shared.saveMistake(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: nil, 
                questionId: question.id,
                incorrectAnswer: "", 
                correctAnswer: correctAnswer
            )
            
            AppLogger.learning.info("Saved mistake for review", metadata: [
                "questionId": question.id,
                "beliefSystemId": beliefSystem.id
            ])
        } catch {
            AppLogger.logError(error, context: "Saving mistake", logger: AppLogger.learning)
        }
    }
}