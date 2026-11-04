import UIKit
import MidgarCore
import AppOfTheDeadCore

final class LearningPathCoordinator {
    
    private let navigationController: UINavigationController
    private let beliefSystem: BeliefSystem
    private let contentLoader: ContentLoader
    private var currentLessonIndex = 0
    private var questionFlowCoordinator: QuestionFlowCoordinator?
    private let databaseManager = DatabaseManager.shared
    private var isReplayMode = false
    private var isMasterTest = false
    private var isPreviewMode = false
    private let reminderOffer = ReminderOffer()

    
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
        isMasterTest = false
        showPathMap()
    }

    private weak var pathMap: PathMapViewController?

    /// The path's hub: every lesson on a winding map, the next one lit. Lessons start from here and return here.
    private func showPathMap() {
        let viewModel = PathMapViewModel(beliefSystem: beliefSystem, databaseManager: databaseManager)
        let map = PathMapViewController(viewModel: viewModel)
        map.onLessonSelected = { [weak self] index in self?.beginLesson(at: index) }
        map.onMasteryTest = { [weak self] in
            guard let self else { return }
            self.startMasterTest(for: self.beliefSystem)
        }
        map.onClose = { [weak self] in self?.exitLearningPath() }
        pathMap = map
        navigationController.pushViewController(map, animated: true)
    }

    /// Opens the lesson at `index`: a done lesson replays without earning path XP twice, the next one starts.
    private func beginLesson(at index: Int) {
        guard beliefSystem.lessons.indices.contains(index) else { return }
        isMasterTest = false
        isPreviewMode = false
        currentLessonIndex = index
        isReplayMode = index < findResumePoint()
        showNextLesson()
    }

    /// Back to the map after a lesson, or home when the path was entered without one.
    private func returnToMap() {
        guard let pathMap else {
            returnToHome()
            return
        }
        navigationController.popToViewController(pathMap, animated: true)
    }

    func startLearningPath(for beliefSystem: BeliefSystem, replay: Bool = false) {
        isMasterTest = false
        isReplayMode = replay
        if replay {
            currentLessonIndex = 0
        } else {
            currentLessonIndex = findResumePoint()
        }
        showNextLesson()
    }
    
    /// Free taste of a locked path: lesson 1 plays in full, then the path-specific
    /// paywall appears at the value moment instead of the lesson list.
    func startPreview() {
        isMasterTest = false
        isPreviewMode = true
        currentLessonIndex = 0
        showNextLesson()
    }

    func startMasterTest(for beliefSystem: BeliefSystem) {
        isMasterTest = true
        
        let masteryTest = beliefSystem.masteryTest
        
        
        questionFlowCoordinator = QuestionFlowCoordinator(
            navigationController: navigationController,
            questions: masteryTest.questions,
            beliefSystem: beliefSystem
        )
        
        questionFlowCoordinator?.delegate = self
        questionFlowCoordinator?.start()
    }
    
    func startReviewMissedQuestions(for beliefSystem: BeliefSystem) {
        
        
        startLearningPath(for: beliefSystem, replay: true)
    }
    
    private func findResumePoint() -> Int {
        guard let user = databaseManager.fetchUser() else { return 0 }
        
        do {
            let userProgress = try databaseManager.getUserProgress(userId: user.id)
            let beliefSystemProgress = userProgress.filter { $0.beliefSystemId == beliefSystem.id }
            
            
            let lessonsWithProgress = beliefSystemProgress.filter { $0.lessonId != nil }
            
            
            if lessonsWithProgress.isEmpty {
                return 0
            }
            
            
            var furthestIndex = 0
            for (index, lesson) in beliefSystem.lessons.enumerated() {
                let lessonProgress = lessonsWithProgress.first { $0.lessonId == lesson.id }
                if let progress = lessonProgress {
                    if progress.status == .completed {
                        
                        furthestIndex = index + 1
                    } else if progress.status == .inProgress {
                        
                        furthestIndex = index
                        break
                    }
                }
            }
            
            
            return min(furthestIndex, beliefSystem.lessons.count)
            
        } catch {
            Diagnostics.logError(error, context: "Finding resume point", category: .learning)
            return 0
        }
    }
    
    private func showNextLesson() {
        guard currentLessonIndex < beliefSystem.lessons.count else {
            completeLearningPath()
            return
        }
        
        let lesson = beliefSystem.lessons[currentLessonIndex]
        
        
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
    
    /// After a lesson: back to the map that opened it, or straight on to the next lesson when no map did.
    private func continueAfterLesson() {
        if pathMap != nil {
            returnToMap()
        } else {
            currentLessonIndex += 1
            showNextLesson()
        }
    }

    /// Marks the whole path completed once its last lesson is done, unless it is already completed or mastered.
    private func markPathCompletedIfEveryLessonIsDone() {
        guard !isReplayMode, findResumePoint() >= beliefSystem.lessons.count,
              let user = databaseManager.fetchUser() else { return }
        let existing = try? databaseManager.getProgress(userId: user.id, beliefSystemId: beliefSystem.id)
        guard existing?.status != .completed, existing?.status != .mastered else { return }
        do {
            try databaseManager.createOrUpdateProgress(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: nil,
                status: .completed,
                score: nil
            )
            GamificationService.shared.checkAchievements(for: user.id)
            NotificationCenter.default.post(name: Notification.Name("UserDataDidUpdate"), object: nil)
        } catch {
            Diagnostics.logError(error, context: "Marking belief system as completed", category: .learning)
        }
    }

    private func completeLearningPath() {

        if let user = databaseManager.fetchUser() {
            do {
                try databaseManager.createOrUpdateProgress(
                    userId: user.id,
                    beliefSystemId: beliefSystem.id,
                    lessonId: nil,
                    status: .completed,
                    score: nil
                )

                GamificationService.shared.checkAchievements(for: user.id)
                NotificationCenter.default.post(name: Notification.Name("UserDataDidUpdate"), object: nil)
            } catch {
                Diagnostics.logError(error, context: "Marking belief system as completed", category: .learning)
            }
        }
        
        
        UserDefaults.standard.removeObject(forKey: "currentBeliefSystemId")
        returnToHome()
    }

    private func returnToHome() {
        navigationController.popToRootViewController(animated: true)
        GameCenterManager.shared.resumeDeferredAuthentication()
    }
}

extension LearningPathCoordinator: LessonViewModelDelegate {
    func lessonViewModelDidRequestQuiz(_ viewModel: LessonViewModel, questions: [Question]) {
        showQuizForCurrentLesson()
    }
    
    func lessonViewModelDidRequestExit(_ viewModel: LessonViewModel) {
        leaveLesson()
    }

    /// Closing a lesson or its quiz goes back to the map it came from, or home.
    private func leaveLesson() {
        if pathMap != nil {
            returnToMap()
        } else {
            exitLearningPath()
        }
    }
    
    private func exitLearningPath() {
        
        UserDefaults.standard.removeObject(forKey: "currentBeliefSystemId")
        returnToHome()
    }
}

extension LearningPathCoordinator: QuestionFlowCoordinatorDelegate {
    func questionFlowCoordinatorDidComplete(_ coordinator: QuestionFlowCoordinator, results: [QuestionResult]) {
        questionFlowCoordinator = nil
        
        if isMasterTest {
            handleMasterTestCompletion(results: results)
        } else if isPreviewMode {

            saveLessonCompletion(results: results)
            finishPreview()
        } else {

            let completionSummary = reminderOfferSummaryIfEligible(results: results)
            saveLessonCompletion(results: results)
            markPathCompletedIfEveryLessonIsDone()

            offerAfterLessonIfDue()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                if let completionSummary {
                    self.showLessonComplete(completionSummary)
                } else {
                    self.continueAfterLesson()
                }
            }
        }
    }

    /// The first completed lesson earns a calm completion screen carrying the reminder opt-in.
    /// It sits in the navigation stack, so a paywall presented at the same moment simply covers
    /// it and the card is waiting once the paywall is dismissed.
    private func reminderOfferSummaryIfEligible(results: [QuestionResult]) -> LessonCompleteViewController.Summary? {
        guard !isReplayMode,
              currentLessonIndex < beliefSystem.lessons.count,
              reminderOffer.shouldPresent(
                priorSuccesses: ReviewPrompt.recordedSuccessCount,
                reminderEnabled: DailyReminder.shared.isEnabled
              ) else { return nil }

        let lesson = beliefSystem.lessons[currentLessonIndex]
        return LessonCompleteViewController.Summary(
            lessonTitle: lesson.title,
            correctAnswers: results.filter { $0.wasCorrect }.count,
            totalQuestions: results.count,
            xpReward: lesson.xpReward
        )
    }

    private func showLessonComplete(_ summary: LessonCompleteViewController.Summary) {
        reminderOffer.markShown()
        MidgarLog.info("Showing lesson complete with reminder offer", category: .learning)
        let viewController = LessonCompleteViewController(
            summary: summary,
            onContinue: { [weak self] in self?.continueAfterLesson() },
            onClose: { [weak self] in self?.exitLearningPath() }
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    private func finishPreview() {
        UserDefaults.standard.removeObject(forKey: "currentBeliefSystemId")
        returnToHome()

        guard !StoreAccess.shared.hasEverythingOpen else { return }

        LessonOffer.policy.noteOffered()
        let paywall = PaywallViewController(reason: .lockedPath(beliefSystemId: beliefSystem.id))
        navigationController.present(paywall, animated: true)
    }
    
    func questionFlowCoordinatorDidRequestExit(_ coordinator: QuestionFlowCoordinator) {
        questionFlowCoordinator = nil
        leaveLesson()
    }

    /// Offers the paywall when ``LessonOffer`` says a finished lesson is the moment: the value moment converts
    /// best on Day 0, and the paywall stays dismissible, with the next lesson already waiting underneath it. Lessons
    /// during the Premium Week are not counted: the policy remembers ownership for good, and the week owns nothing.
    private func offerAfterLessonIfDue() {
        guard !StoreAccess.shared.isPremiumWeekActive else { return }
        guard LessonOffer.policy.noteValue(isOwned: StoreAccess.shared.hasAllAccess) else { return }
        LessonOffer.policy.noteOffered()
        let paywall = PaywallViewController(reason: .lessonFinished(nextPath: curiousPathToOffer()))
        navigationController.present(paywall, animated: true)
    }

    /// The path the person picked on the welcome screen, when it is still locked and is not the one they are on.
    private func curiousPathToOffer() -> (id: String, name: String)? {
        guard let id = CuriousPath.id, id != beliefSystem.id, !StoreAccess.shared.hasPathAccess(id),
              let system = DatabaseManager.shared.loadBeliefSystems().first(where: { $0.id == id })
        else { return nil }
        return (system.id, system.name)
    }
    
    /// Marks the lesson in progress, unless it is a replay of a lesson already done: that one stays completed.
    private func saveLessonStarted(lesson: Lesson) {
        FreePaths.shared.recordLessonStarted(in: beliefSystem.id)
        guard !isReplayMode, let user = databaseManager.fetchUser() else { return }
        
        do {
            try databaseManager.createOrUpdateProgress(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: lesson.id,
                status: .inProgress,
                score: nil
            )
        } catch {
            Diagnostics.logError(error, context: "Saving lesson started", category: .learning)
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

            GamificationService.shared.awardXP(
                to: user.id,
                amount: lesson.xpReward,
                reason: "Lesson completed",
                beliefSystemId: isReplayMode ? nil : beliefSystem.id
            )
            if !isReplayMode && !isPreviewMode {
                let navigation = navigationController
                Task { @MainActor in
                    ReviewPrompt.recordSuccess(in: navigation.view.window?.windowScene)
                }
            }
        } catch {
            Diagnostics.logError(error, context: "Saving lesson completion", category: .learning)
        }
    }
    
    private func handleMasterTestCompletion(results: [QuestionResult]) {
        guard let user = databaseManager.fetchUser() else { return }
        
        let masteryTest = beliefSystem.masteryTest
        
        let correctAnswers = results.filter { $0.wasCorrect }.count
        let totalQuestions = results.count
        let score = totalQuestions > 0 ? Int((Double(correctAnswers) / Double(totalQuestions)) * 100) : 0
        
        
        let requiredScore = masteryTest.requiredScore
        let passed = score >= requiredScore
        
        do {
            if passed {
                let existingProgress = try databaseManager.getProgress(userId: user.id, beliefSystemId: beliefSystem.id)
                let isFirstMastery = existingProgress?.status != .mastered
                let bestScore = isFirstMastery ? score : max(score, existingProgress?.score ?? 0)

                try databaseManager.createOrUpdateProgress(
                    userId: user.id,
                    beliefSystemId: beliefSystem.id,
                    lessonId: nil,
                    status: .mastered,
                    score: bestScore
                )

                if isFirstMastery {
                    GamificationService.shared.awardXP(
                        to: user.id,
                        amount: masteryTest.xpReward,
                        reason: "Mastery test passed",
                        beliefSystemId: beliefSystem.id
                    )
                } else {
                    GamificationService.shared.checkAchievements(for: user.id)
                }

                showMasterTestSuccessAlert(score: score)
            } else {
                
                showMasterTestFailureAlert(score: score, requiredScore: requiredScore)
            }
        } catch {
            Diagnostics.logError(error, context: "Saving master test completion", category: .learning)
        }
    }
    
    /// After the mastery test: back to the map that opened it, or home.
    private func leaveMasteryTest() {
        if pathMap != nil {
            returnToMap()
        } else {
            exitLearningPath()
        }
    }

    private func showMasterTestSuccessAlert(score: Int) {
        let alert = UIAlertController(
            title: String(localized: "Congratulations!"),
            message: String(localized: "You've mastered \(beliefSystem.name) with a score of \(score)%!"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: String(localized: "Continue"), style: .default) { [weak self] _ in
            self?.leaveMasteryTest()
        })
        
        navigationController.present(alert, animated: true)
    }
    
    private func showMasterTestFailureAlert(score: Int, requiredScore: Int) {
        let alert = UIAlertController(
            title: String(localized: "Almost There!"),
            message: String(localized: "You scored \(score)%, but need \(requiredScore)% to pass the master test."),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: String(localized: "Try Again"), style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.startMasterTest(for: self.beliefSystem)
        })
        
        alert.addAction(UIAlertAction(title: String(localized: "Review Path"), style: .default) { [weak self] _ in
            self?.leaveMasteryTest()
        })
        
        navigationController.present(alert, animated: true)
    }
}