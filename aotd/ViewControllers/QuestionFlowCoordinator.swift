import UIKit

protocol QuestionFlowCoordinatorDelegate: AnyObject {
    func questionFlowCoordinatorDidComplete(_ coordinator: QuestionFlowCoordinator, results: [QuestionResult])
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
            delegate?.questionFlowCoordinatorDidComplete(self, results: results)
            return
        }
        
        let question = questions[currentQuestionIndex]
        let viewController = createViewController(for: question)
        
        if currentQuestionIndex == 0 {
            navigationController.setViewControllers([viewController], animated: true)
        } else {
            navigationController.pushViewController(viewController, animated: true)
        }
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
            // For now, use multiple choice as placeholder for matching
            viewModel = MultipleChoiceViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = MultipleChoiceViewController(viewModel: viewModel)
        }
        
        viewModel.delegate = self
        viewController.navigationItem.hidesBackButton = true
        
        return viewController
    }
}

extension QuestionFlowCoordinator: QuestionViewModelDelegate {
    func questionViewModel(_ viewModel: BaseQuestionViewModel, didAnswerCorrectly: Bool) {
        let result = QuestionResult(question: viewModel.question, wasCorrect: didAnswerCorrectly)
        results.append(result)
        
        currentQuestionIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNextQuestion()
        }
    }
}