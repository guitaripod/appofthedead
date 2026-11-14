import UIKit
import MidgarCore
import AppOfTheDeadCore

protocol QuestionFlowCoordinatorDelegate: AnyObject {
    func questionFlowCoordinatorDidComplete(_ coordinator: QuestionFlowCoordinator, results: [QuestionResult])
    func questionFlowCoordinatorDidRequestExit(_ coordinator: QuestionFlowCoordinator)
}

/// Builds the screen for one question of a quiz.
enum QuestionScreenFactory {
    static func screen(for question: Question, beliefSystem: BeliefSystem, index: Int, total: Int) -> BaseQuestionViewController {
        switch question.type {
        case .multipleChoice:
            let viewModel = MultipleChoiceViewModel(question: question, beliefSystem: beliefSystem, currentQuestionIndex: index, totalQuestions: total)
            return MultipleChoiceViewController(viewModel: viewModel)
        case .trueFalse:
            let viewModel = BaseQuestionViewModel(question: question, beliefSystem: beliefSystem, currentQuestionIndex: index, totalQuestions: total)
            return TrueFalseViewController(viewModel: viewModel)
        case .matching:
            let viewModel = MatchingQuestionViewModel(question: question, beliefSystem: beliefSystem, currentQuestionIndex: index, totalQuestions: total)
            return MatchingQuestionViewController(viewModel: viewModel)
        }
    }
}

/// Runs a lesson quiz or a mastery test on one quiz session screen: shows each question, awards XP for a right answer
/// as soon as it is checked, keeps every wrong one for review with the answer that was given, and hands the results
/// to its delegate after the last Continue.
final class QuestionFlowCoordinator: NSObject {

    weak var delegate: QuestionFlowCoordinatorDelegate?

    private let navigationController: UINavigationController
    private let questions: [Question]
    private let beliefSystem: BeliefSystem
    private var currentQuestionIndex: Int
    private(set) var results: [QuestionResult] = []
    private(set) var session: QuizSessionViewController?

    init(navigationController: UINavigationController, questions: [Question], beliefSystem: BeliefSystem, startingAt startIndex: Int = 0) {
        self.navigationController = navigationController
        self.questions = questions
        self.beliefSystem = beliefSystem
        self.currentQuestionIndex = startIndex
        super.init()
    }

    /// The XP the right answers of this session earned so far.
    var xpEarned: Int {
        results.reduce(0) { $0 + $1.xpEarned }
    }

    /// Pushes the quiz session, or puts it in place of `finishedScreen` (a finished test's results) when given.
    func start(replacing finishedScreen: UIViewController? = nil) {
        guard currentQuestionIndex < questions.count else {
            delegate?.questionFlowCoordinatorDidComplete(self, results: results)
            return
        }
        let session = QuizSessionViewController(accent: PapyrusDesignSystem.Colors.tradition(beliefSystem.color))
        session.delegate = self
        self.session = session
        session.show(screen(at: currentQuestionIndex), answeredCount: currentQuestionIndex, total: questions.count, animated: false)
        var stack = navigationController.viewControllers
        if let finishedScreen, let position = stack.firstIndex(of: finishedScreen) {
            stack[position] = session
            navigationController.setViewControllers(stack, animated: true)
        } else {
            navigationController.pushViewController(session, animated: true)
        }
    }

    private func screen(at index: Int) -> BaseQuestionViewController {
        QuestionScreenFactory.screen(for: questions[index], beliefSystem: beliefSystem, index: index, total: questions.count)
    }

    /// Awards the streak-raised XP for a right answer and reports what was really awarded.
    private func awardXPForCorrectAnswer(base: Int) -> Int {
        guard let user = DatabaseManager.shared.fetchUser() else { return 0 }
        let amount = QuizXP.perCorrectAnswer(base: base, streakDays: user.streakDays)
        GamificationService.shared.awardXP(to: user.id, amount: amount, reason: "Correct answer")
        return amount
    }

    private func saveMistake(for question: Question, outcome: QuestionOutcome) {
        guard let user = DatabaseManager.shared.fetchUser() else { return }
        do {
            try DatabaseManager.shared.saveMistake(
                userId: user.id,
                beliefSystemId: beliefSystem.id,
                lessonId: nil,
                questionId: question.id,
                incorrectAnswer: outcome.givenAnswer,
                correctAnswer: outcome.correctAnswer
            )
            MidgarLog.info("Saved mistake for review", metadata: [
                "questionId": question.id,
                "beliefSystemId": beliefSystem.id
            ], category: .learning)
        } catch {
            Diagnostics.logError(error, context: "Saving mistake", category: .learning)
        }
    }
}

extension QuestionFlowCoordinator: QuizSessionViewControllerDelegate {
    func quizSession(_ session: QuizSessionViewController, didAnswer outcome: QuestionOutcome, for viewModel: BaseQuestionViewModel) {
        let xp = outcome.isCorrect ? awardXPForCorrectAnswer(base: viewModel.xpReward) : 0
        if !outcome.isCorrect {
            saveMistake(for: viewModel.question, outcome: outcome)
        }
        results.append(QuestionResult(question: viewModel.question, outcome: outcome, xpEarned: xp))
        session.showFeedback(for: outcome, xpEarned: xp, isLast: currentQuestionIndex + 1 >= questions.count)
    }

    func quizSessionDidContinue(_ session: QuizSessionViewController) {
        guard currentQuestionIndex < questions.count else { return }
        currentQuestionIndex += 1
        guard currentQuestionIndex < questions.count else {
            delegate?.questionFlowCoordinatorDidComplete(self, results: results)
            return
        }
        session.show(screen(at: currentQuestionIndex), answeredCount: currentQuestionIndex, total: questions.count, animated: true)
    }

    func quizSessionDidRequestClose(_ session: QuizSessionViewController) {
        delegate?.questionFlowCoordinatorDidRequestExit(self)
    }
}

#if DEBUG
extension QuestionFlowCoordinator {
    /// Screenshot rig: answers the question on screen and checks it.
    func demoAnswerCurrentQuestion(correctly: Bool) {
        session?.demoAnswer(correctly: correctly)
    }
}
#endif
