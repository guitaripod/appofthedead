import UIKit

final class LearningPathCoordinator {
    
    private let navigationController: UINavigationController
    private let beliefSystem: BeliefSystem
    private let contentLoader: ContentLoader
    private var currentLessonIndex = 0
    private var questionFlowCoordinator: QuestionFlowCoordinator?
    
    init(
        navigationController: UINavigationController,
        beliefSystem: BeliefSystem,
        contentLoader: ContentLoader
    ) {
        self.navigationController = navigationController
        self.beliefSystem = beliefSystem
        self.contentLoader = contentLoader
    }
    
    func start() {
        showNextLesson()
    }
    
    private func showNextLesson() {
        guard currentLessonIndex < beliefSystem.lessons.count else {
            completeLearningPath()
            return
        }
        
        let lesson = beliefSystem.lessons[currentLessonIndex]
        let lessonViewModel = LessonViewModel(
            lesson: lesson,
            beliefSystem: beliefSystem,
            currentLessonIndex: currentLessonIndex,
            totalLessons: beliefSystem.lessons.count
        )
        
        let lessonViewController = LessonViewController(viewModel: lessonViewModel)
        lessonViewModel.delegate = self
        
        navigationController.pushViewController(lessonViewController, animated: true)
    }
    
    private func showQuizForCurrentLesson() {
        let lesson = beliefSystem.lessons[currentLessonIndex]
        
        questionFlowCoordinator = QuestionFlowCoordinator(
            navigationController: navigationController,
            questions: lesson.questions,
            beliefSystem: beliefSystem
        )
        
        questionFlowCoordinator?.delegate = self
        questionFlowCoordinator?.start()
    }
    
    private func completeLearningPath() {
        navigationController.popToRootViewController(animated: true)
    }
}

extension LearningPathCoordinator: LessonViewModelDelegate {
    func lessonViewModelDidRequestQuiz(_ viewModel: LessonViewModel, questions: [Question]) {
        showQuizForCurrentLesson()
    }
}

extension LearningPathCoordinator: QuestionFlowCoordinatorDelegate {
    func questionFlowCoordinatorDidComplete(_ coordinator: QuestionFlowCoordinator, results: [QuestionResult]) {
        questionFlowCoordinator = nil
        
        currentLessonIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNextLesson()
        }
    }
}