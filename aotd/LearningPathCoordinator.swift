import UIKit

final class LearningPathCoordinator {
    
    private let navigationController: UINavigationController
    private let beliefSystem: BeliefSystem
    private let contentLoader: ContentLoader
    private var currentLessonIndex = 0
    private var questionFlowCoordinator: QuestionFlowCoordinator?
    private let databaseManager = DatabaseManager.shared
    
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
        currentLessonIndex = findResumePoint()
        showNextLesson()
    }
    
    private func findResumePoint() -> Int {
        guard let user = databaseManager.fetchUser() else { return 0 }
        
        do {
            let userProgress = try databaseManager.getUserProgress(userId: user.id)
            let beliefSystemProgress = userProgress.filter { $0.beliefSystemId == beliefSystem.id }
            
            // Find lessons with any progress for this belief system
            let lessonsWithProgress = beliefSystemProgress.filter { $0.lessonId != nil }
            
            // If no lessons have been started, start from beginning
            if lessonsWithProgress.isEmpty {
                return 0
            }
            
            // Find the furthest lesson that has been started
            var furthestIndex = 0
            for (index, lesson) in beliefSystem.lessons.enumerated() {
                let lessonProgress = lessonsWithProgress.first { $0.lessonId == lesson.id }
                if let progress = lessonProgress {
                    if progress.status == .completed {
                        // This lesson is completed, continue to next
                        furthestIndex = index + 1
                    } else if progress.status == .inProgress {
                        // This lesson is in progress, resume here
                        furthestIndex = index
                        break
                    }
                }
            }
            
            // Make sure we don't go beyond the available lessons
            return min(furthestIndex, beliefSystem.lessons.count)
            
        } catch {
            print("Error finding resume point: \(error)")
            return 0
        }
    }
    
    private func showNextLesson() {
        guard currentLessonIndex < beliefSystem.lessons.count else {
            completeLearningPath()
            return
        }
        
        let lesson = beliefSystem.lessons[currentLessonIndex]
        
        // Save that user started this lesson
        saveLessonStarted(lesson: lesson)
        
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
        // Clear session when path is completed
        UserDefaults.standard.removeObject(forKey: "currentBeliefSystemId")
        navigationController.popToRootViewController(animated: true)
    }
}

extension LearningPathCoordinator: LessonViewModelDelegate {
    func lessonViewModelDidRequestQuiz(_ viewModel: LessonViewModel, questions: [Question]) {
        showQuizForCurrentLesson()
    }
    
    func lessonViewModelDidRequestExit(_ viewModel: LessonViewModel) {
        exitLearningPath()
    }
    
    private func exitLearningPath() {
        // Clear the session state when exiting
        UserDefaults.standard.removeObject(forKey: "currentBeliefSystemId")
        navigationController.popToRootViewController(animated: true)
    }
}

extension LearningPathCoordinator: QuestionFlowCoordinatorDelegate {
    func questionFlowCoordinatorDidComplete(_ coordinator: QuestionFlowCoordinator, results: [QuestionResult]) {
        questionFlowCoordinator = nil
        
        // Save lesson completion progress
        saveLessonCompletion(results: results)
        
        currentLessonIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNextLesson()
        }
    }
    
    func questionFlowCoordinatorDidRequestExit(_ coordinator: QuestionFlowCoordinator) {
        questionFlowCoordinator = nil
        exitLearningPath()
    }
    
    private func saveLessonStarted(lesson: Lesson) {
        guard let user = databaseManager.fetchUser() else { return }
        
        do {
            try databaseManager.createOrUpdateProgress(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: lesson.id,
                status: .inProgress,
                score: nil
            )
        } catch {
            print("Error saving lesson started: \(error)")
        }
    }
    
    private func saveLessonCompletion(results: [QuestionResult]) {
        guard let user = databaseManager.fetchUser(),
              currentLessonIndex < beliefSystem.lessons.count else { return }
        
        let lesson = beliefSystem.lessons[currentLessonIndex]
        let correctAnswers = results.filter { $0.wasCorrect }.count
        let totalQuestions = results.count
        let score = totalQuestions > 0 ? Int((Double(correctAnswers) / Double(totalQuestions)) * 100) : 0
        
        do {
            try databaseManager.createOrUpdateProgress(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: lesson.id,
                status: .completed,
                score: score
            )
        } catch {
            print("Error saving lesson completion: \(error)")
        }
    }
}