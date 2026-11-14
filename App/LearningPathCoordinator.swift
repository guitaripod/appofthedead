import UIKit
import MidgarCore
import AppOfTheDeadCore

final class LearningPathCoordinator {
    
    private let navigationController: UINavigationController
    private let beliefSystem: BeliefSystem
    private let contentLoader: ContentLoader
    private var currentLessonIndex = 0
    private var questionFlowCoordinator: QuestionFlowCoordinator?
    private var mistakeReview: MistakeReviewCoordinator?
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
        startMasterTest(for: beliefSystem, replacing: nil)
    }

    /// Starts the mastery test; a retry from the results replaces them so the stack never holds a finished test.
    private func startMasterTest(for beliefSystem: BeliefSystem, replacing screen: UIViewController?) {
        isMasterTest = true
        let flow = QuestionFlowCoordinator(
            navigationController: navigationController,
            questions: beliefSystem.masteryTest.questions,
            beliefSystem: beliefSystem
        )
        flow.delegate = self
        questionFlowCoordinator = flow
        flow.start(replacing: screen)
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
    
    private func showNextLesson(replacingFinishedScreens: Bool = false) {
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

        if replacingFinishedScreens, let root = navigationController.viewControllers.first {
            navigationController.setViewControllers([root, lessonViewController], animated: true)
        } else {
            navigationController.pushViewController(lessonViewController, animated: true)
        }
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
    
    /// After a lesson: back to the map that opened it, or straight on to the next lesson when no map did, in place of
    /// the finished lesson's screens so back never returns to a result that would move on again.
    private func continueAfterLesson() {
        if pathMap != nil {
            returnToMap()
        } else {
            currentLessonIndex += 1
            showNextLesson(replacingFinishedScreens: true)
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
        let session = coordinator.session
        questionFlowCoordinator = nil
        if isMasterTest {
            finishMasteryTest(results: results, session: session)
        } else if isPreviewMode {
            let lessonXP = saveLessonCompletion(results: results)
            let finish: () -> Void = { [weak self] in self?.finishPreview() }
            showLessonResults(results, lessonXP: lessonXP, reminder: nil, session: session, onClose: finish, onContinue: finish)
        } else {
            let offersReminder = isReminderOfferDue()
            let lessonXP = saveLessonCompletion(results: results)
            markPathCompletedIfEveryLessonIsDone()
            let screen = showLessonResults(
                results,
                lessonXP: lessonXP,
                reminder: offersReminder ? DailyReminder.shared : nil,
                session: session,
                onClose: { [weak self] in self?.leaveLesson() },
                onContinue: { [weak self] in self?.continueAfterLesson() }
            )
            if offersReminder {
                reminderOffer.markShown()
                MidgarLog.info("Showing lesson results with reminder offer", category: .learning)
            }
            screen.onFirstAppear = { [weak self] in self?.offerAfterLessonIfDue() }
        }
    }

    /// The first completed lesson's results carry the daily reminder opt-in. A paywall presented over the results
    /// simply covers them, and the card is waiting once it is dismissed.
    private func isReminderOfferDue() -> Bool {
        !isReplayMode
            && currentLessonIndex < beliefSystem.lessons.count
            && reminderOffer.shouldPresent(
                priorSuccesses: ReviewPrompt.recordedSuccessCount,
                reminderEnabled: DailyReminder.shared.isEnabled
            )
    }

    /// Shows a finished lesson's results in place of its quiz and lesson; `onContinue` is where Continue goes and
    /// `onClose` where the close button goes.
    @discardableResult
    private func showLessonResults(
        _ results: [QuestionResult],
        lessonXP: Int,
        reminder: DailyReminder?,
        session: UIViewController?,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) -> QuizResultsViewController {
        let title = beliefSystem.lessons.indices.contains(currentLessonIndex) ? beliefSystem.lessons[currentLessonIndex].title : beliefSystem.name
        let summary = QuizResultsViewModel(kind: .lesson(title: title), beliefSystem: beliefSystem, results: results, bonusXP: lessonXP)
        var actions = [QuizResultsViewController.Action(title: String(localized: "Continue"), symbol: nil, style: .primary, handler: onContinue)]
        if let practice = practiceAction(for: results, then: onContinue) {
            actions.append(practice)
        }
        let screen = QuizResultsViewController(viewModel: summary, actions: actions, reminder: reminder)
        screen.onClose = onClose
        replaceQuiz(session, with: screen)
        return screen
    }

    /// Practice Mistakes, when the session missed questions that are waiting in review: it reviews just those now.
    private func practiceAction(for results: [QuestionResult], then finish: @escaping () -> Void) -> QuizResultsViewController.Action? {
        let mistakes = pendingMistakes(missedIn: results)
        guard !mistakes.isEmpty else { return nil }
        let title = String(localized: "Practice Mistakes (\(mistakes.count))")
        return QuizResultsViewController.Action(title: title, symbol: "arrow.counterclockwise", style: .secondary) { [weak self] in
            self?.practice(mistakes, then: finish)
        }
    }

    private func pendingMistakes(missedIn results: [QuestionResult]) -> [Mistake] {
        let missed = Set(results.filter { !$0.wasCorrect }.map(\.question.id))
        guard !missed.isEmpty, let user = databaseManager.fetchUser(),
              let mistakes = try? databaseManager.getMistakes(userId: user.id, beliefSystemId: beliefSystem.id) else { return [] }
        return mistakes.filter { missed.contains($0.questionId) }
    }

    private func practice(_ mistakes: [Mistake], then finish: @escaping () -> Void) {
        guard let user = databaseManager.fetchUser() else { return }
        do {
            let session = try databaseManager.startMistakeSession(userId: user.id, beliefSystemId: beliefSystem.id)
            let review = MistakeReviewCoordinator(navigationController: navigationController, beliefSystem: beliefSystem, mistakes: mistakes, session: session)
            guard review.hasQuestions else { return }
            review.onFinish = { [weak self] completed in
                self?.mistakeReview = nil
                if completed {
                    finish()
                } else {
                    self?.navigationController.popViewController(animated: true)
                }
            }
            mistakeReview = review
            review.start()
        } catch {
            Diagnostics.logError(error, context: "Starting mistake practice", category: .learning)
        }
    }

    /// Puts `screen` where the finished quiz was, dropping the lesson it came from, so back never returns to either.
    private func replaceQuiz(_ session: UIViewController?, with screen: UIViewController) {
        var stack = navigationController.viewControllers
        if let session, let position = stack.firstIndex(of: session) {
            stack.removeSubrange(position...)
            if position > 0, stack[position - 1] is LessonViewController {
                stack.remove(at: position - 1)
            }
        }
        stack.append(screen)
        navigationController.setViewControllers(stack, animated: true)
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
    
    /// Marks the lesson completed with its score and awards its XP; returns the XP awarded.
    @discardableResult
    private func saveLessonCompletion(results: [QuestionResult]) -> Int {
        guard let user = databaseManager.fetchUser(),
              currentLessonIndex < beliefSystem.lessons.count else { return 0 }
        
        let lesson = beliefSystem.lessons[currentLessonIndex]
        let correctAnswers = results.filter { $0.wasCorrect }.count
        let totalQuestions = results.count
        let score = totalQuestions > 0 ? QuizResultsViewModel.percent(correct: correctAnswers, of: totalQuestions) : 0

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
            return lesson.xpReward
        } catch {
            Diagnostics.logError(error, context: "Saving lesson completion", category: .learning)
            return 0
        }
    }
    
    /// Scores the mastery test, saves a pass with its best score and the first mastery's XP, and shows the results.
    private func finishMasteryTest(results: [QuestionResult], session: UIViewController?) {
        let masteryTest = beliefSystem.masteryTest
        let correctAnswers = results.filter { $0.wasCorrect }.count
        let score = QuizResultsViewModel.percent(correct: correctAnswers, of: results.count)
        let passed = score >= masteryTest.requiredScore
        let masteryXP = passed ? saveMastery(score: score) : 0
        let summary = QuizResultsViewModel(kind: .mastery(requiredScore: masteryTest.requiredScore), beliefSystem: beliefSystem, results: results, bonusXP: masteryXP)
        let leave: () -> Void = { [weak self] in self?.leaveMasteryTest() }
        var actions: [QuizResultsViewController.Action] = []
        if passed {
            actions.append(.init(title: String(localized: "Continue"), symbol: nil, style: .primary, handler: leave))
            if let practice = practiceAction(for: results, then: leave) {
                actions.append(practice)
            }
        }
        let screen = QuizResultsViewController(viewModel: summary, actions: [], reminder: nil)
        if !passed {
            actions.append(.init(title: String(localized: "Try Again"), symbol: "arrow.clockwise", style: .primary) { [weak self, weak screen] in
                guard let self else { return }
                self.startMasterTest(for: self.beliefSystem, replacing: screen)
            })
            actions.append(.init(title: String(localized: "Back to Path"), symbol: nil, style: .secondary, handler: leave))
        }
        screen.setActions(actions)
        screen.onClose = leave
        replaceQuiz(session, with: screen)
    }

    /// Records a passed mastery test, keeping the best score, and returns the XP the first mastery awards.
    private func saveMastery(score: Int) -> Int {
        guard let user = databaseManager.fetchUser() else { return 0 }
        let masteryTest = beliefSystem.masteryTest
        do {
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
                return masteryTest.xpReward
            }
            GamificationService.shared.checkAchievements(for: user.id)
        } catch {
            Diagnostics.logError(error, context: "Saving master test completion", category: .learning)
        }
        return 0
    }

    /// After the mastery test: back to the map that opened it, or home.
    private func leaveMasteryTest() {
        if pathMap != nil {
            returnToMap()
        } else {
            exitLearningPath()
        }
    }
}
