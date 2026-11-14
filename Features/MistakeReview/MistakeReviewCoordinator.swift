import UIKit
import MidgarCore
import AppOfTheDeadCore

/// Mistake review on the quiz session screen: the missed questions of a path in a shuffled order, each right answer
/// moving its mistake toward mastered, 5 XP for each one at the end, then the results with every answer to read.
/// `onFinish` runs after the results' Continue, or after an exit the person confirms; the host decides where to go.
final class MistakeReviewCoordinator {

    static let xpPerCorrectAnswer = 5

    var onFinish: ((_ completed: Bool) -> Void)?

    private let navigationController: UINavigationController
    private let beliefSystem: BeliefSystem
    private let session: MistakeSession
    private let questions: [Question]
    private let mistakeByQuestionId: [String: Mistake]
    private var index = 0
    private var results: [QuestionResult] = []
    private weak var quizSession: QuizSessionViewController?

    init(navigationController: UINavigationController, beliefSystem: BeliefSystem, mistakes: [Mistake], session: MistakeSession) {
        self.navigationController = navigationController
        self.beliefSystem = beliefSystem
        self.session = session
        let allQuestions = beliefSystem.lessons.flatMap(\.questions) + beliefSystem.masteryTest.questions
        var mistakeByQuestionId: [String: Mistake] = [:]
        var questions: [Question] = []
        for mistake in mistakes where mistakeByQuestionId[mistake.questionId] == nil {
            guard let question = allQuestions.first(where: { $0.id == mistake.questionId }) else { continue }
            mistakeByQuestionId[question.id] = mistake
            questions.append(question)
        }
        self.mistakeByQuestionId = mistakeByQuestionId
        self.questions = questions.shuffled()
        MidgarLog.info("Loaded questions for mistake review", metadata: [
            "mistakeCount": mistakes.count,
            "questionCount": questions.count
        ], category: .learning)
    }

    var hasQuestions: Bool {
        !questions.isEmpty
    }

    /// Opens the review as the navigation controller's root when it has none yet, or pushes it.
    func start() {
        guard hasQuestions else {
            onFinish?(false)
            return
        }
        let quizSession = QuizSessionViewController(accent: PapyrusDesignSystem.Colors.tradition(beliefSystem.color))
        quizSession.delegate = self
        self.quizSession = quizSession
        quizSession.show(screen(at: 0), answeredCount: 0, total: questions.count, animated: false)
        if navigationController.viewControllers.isEmpty {
            navigationController.setViewControllers([quizSession], animated: false)
        } else {
            navigationController.pushViewController(quizSession, animated: true)
        }
    }

    private func screen(at index: Int) -> BaseQuestionViewController {
        QuestionScreenFactory.screen(for: questions[index], beliefSystem: beliefSystem, index: index, total: questions.count)
    }

    private func record(_ outcome: QuestionOutcome, for question: Question) {
        guard let mistake = mistakeByQuestionId[question.id] else { return }
        do {
            try DatabaseManager.shared.updateMistakeReview(mistakeId: mistake.id, wasCorrect: outcome.isCorrect)
        } catch {
            Diagnostics.logError(error, context: "Updating mistake review", category: .learning)
        }
    }

    /// Awards the review's XP, closes its session record and shows the results in place of the quiz.
    private func complete() {
        let correctCount = results.filter(\.wasCorrect).count
        let xp = correctCount * Self.xpPerCorrectAnswer
        if xp > 0, let user = DatabaseManager.shared.fetchUser() {
            GamificationService.shared.awardXP(to: user.id, amount: xp, reason: "Mistake review", beliefSystemId: beliefSystem.id)
        }
        do {
            try DatabaseManager.shared.completeMistakeSession(sessionId: session.id, correctCount: correctCount, xpEarned: xp)
        } catch {
            Diagnostics.logError(error, context: "Completing mistake session", category: .learning)
        }
        let summary = QuizResultsViewModel(kind: .review, beliefSystem: beliefSystem, results: results, bonusXP: xp)
        let continueAction = QuizResultsViewController.Action(title: String(localized: "Continue"), symbol: nil, style: .primary) { [weak self] in
            self?.onFinish?(true)
        }
        let resultsScreen = QuizResultsViewController(viewModel: summary, actions: [continueAction])
        resultsScreen.onClose = { [weak self] in self?.onFinish?(true) }
        var stack = navigationController.viewControllers
        if let quizSession, let position = stack.firstIndex(of: quizSession) {
            stack.removeSubrange(position...)
        }
        stack.append(resultsScreen)
        navigationController.setViewControllers(stack, animated: true)
    }

    private func confirmExit(from viewController: UIViewController) {
        PapyrusAlert(title: String(localized: "Exit Review?"), message: String(localized: "Your progress will not be saved if you exit now."))
            .addAction(PapyrusAlert.Action(title: String(localized: "Continue Review"), style: .cancel))
            .addAction(PapyrusAlert.Action(title: String(localized: "Exit"), style: .destructive) { [weak self] in
                self?.onFinish?(false)
            })
            .present(from: viewController)
    }
}

extension MistakeReviewCoordinator: QuizSessionViewControllerDelegate {
    func quizSession(_ session: QuizSessionViewController, didAnswer outcome: QuestionOutcome, for viewModel: BaseQuestionViewModel) {
        record(outcome, for: viewModel.question)
        results.append(QuestionResult(question: viewModel.question, outcome: outcome, xpEarned: 0))
        session.showFeedback(
            for: outcome,
            xpEarned: outcome.isCorrect ? Self.xpPerCorrectAnswer : 0,
            isLast: index + 1 >= questions.count
        )
    }

    func quizSessionDidContinue(_ session: QuizSessionViewController) {
        guard index < questions.count else { return }
        index += 1
        guard index < questions.count else {
            complete()
            return
        }
        session.show(screen(at: index), answeredCount: index, total: questions.count, animated: true)
    }

    func quizSessionDidRequestClose(_ session: QuizSessionViewController) {
        confirmExit(from: session)
    }
}

#if DEBUG
extension MistakeReviewCoordinator {
    /// Screenshot rig: answers the question on screen and checks it.
    func demoAnswerCurrentQuestion(correctly: Bool) {
        quizSession?.demoAnswer(correctly: correctly)
    }
}
#endif
