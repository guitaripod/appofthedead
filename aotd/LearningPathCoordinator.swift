import UIKit

final class LearningPathCoordinator {
    
    private let navigationController: UINavigationController
    private let beliefSystem: BeliefSystem
    private let contentLoader: ContentLoader
    private var currentLessonIndex = 0
    private var questionFlowCoordinator: QuestionFlowCoordinator?
    private let databaseManager = DatabaseManager.shared
    private var isReplayMode = false
    private var isMasterTest = false
    
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
    
    func startLearningPath(for beliefSystem: BeliefSystem, replay: Bool = false) {
        isReplayMode = replay
        if replay {
            currentLessonIndex = 0
        } else {
            currentLessonIndex = findResumePoint()
        }
        showNextLesson()
    }
    
    func startMasterTest(for beliefSystem: BeliefSystem) {
        isMasterTest = true
        
        let masteryTest = beliefSystem.masteryTest
        
        // Show the master test directly
        questionFlowCoordinator = QuestionFlowCoordinator(
            navigationController: navigationController,
            questions: masteryTest.questions,
            beliefSystem: beliefSystem
        )
        
        questionFlowCoordinator?.delegate = self
        questionFlowCoordinator?.start()
    }
    
    func startReviewMissedQuestions(for beliefSystem: BeliefSystem) {
        // TODO: Implement once we have missed questions tracking
        // For now, just replay the full path
        startLearningPath(for: beliefSystem, replay: true)
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
        // Mark belief system as completed
        if let user = databaseManager.fetchUser() {
            do {
                try databaseManager.createOrUpdateProgress(
                    userId: user.id,
                    beliefSystemId: beliefSystem.id,
                    lessonId: nil,
                    status: .completed,
                    score: nil
                )
            } catch {
                print("Error marking belief system as completed: \(error)")
            }
        }
        
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
        
        if isMasterTest {
            handleMasterTestCompletion(results: results)
        } else {
            // Save lesson completion progress
            saveLessonCompletion(results: results)
            
            currentLessonIndex += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showNextLesson()
            }
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
    
    private func handleMasterTestCompletion(results: [QuestionResult]) {
        guard let user = databaseManager.fetchUser() else { return }
        
        let masteryTest = beliefSystem.masteryTest
        
        let correctAnswers = results.filter { $0.wasCorrect }.count
        let totalQuestions = results.count
        let score = totalQuestions > 0 ? Int((Double(correctAnswers) / Double(totalQuestions)) * 100) : 0
        
        // Check if user passed the master test
        let requiredScore = masteryTest.requiredScore
        let passed = score >= requiredScore
        
        do {
            if passed {
                // Mark belief system as mastered
                try databaseManager.createOrUpdateProgress(
                    userId: user.id,
                    beliefSystemId: beliefSystem.id,
                    lessonId: nil,
                    status: .mastered,
                    score: score
                )
                
                // Award master test XP
                try databaseManager.addXPToProgress(
                    userId: user.id,
                    beliefSystemId: beliefSystem.id,
                    xp: masteryTest.xpReward
                )
                
                // Show success message
                showMasterTestSuccessAlert(score: score)
            } else {
                // Show failure message with option to retry
                showMasterTestFailureAlert(score: score, requiredScore: requiredScore)
            }
        } catch {
            print("Error saving master test completion: \(error)")
        }
    }
    
    private func showMasterTestSuccessAlert(score: Int) {
        let alert = UIAlertController(
            title: "Congratulations! 🎉",
            message: "You've mastered \(beliefSystem.name) with a score of \(score)%!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.exitLearningPath()
        })
        
        navigationController.present(alert, animated: true)
    }
    
    private func showMasterTestFailureAlert(score: Int, requiredScore: Int) {
        let alert = UIAlertController(
            title: "Almost There!",
            message: "You scored \(score)%, but need \(requiredScore)% to pass the master test.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.startMasterTest(for: self.beliefSystem)
        })
        
        alert.addAction(UIAlertAction(title: "Review Path", style: .default) { [weak self] _ in
            self?.exitLearningPath()
        })
        
        navigationController.present(alert, animated: true)
    }
}