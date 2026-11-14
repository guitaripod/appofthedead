#if DEBUG
import UIKit
import AppOfTheDeadCore

struct DemoContext {
    let root: AdaptiveNavigationContainer
    let homeNavigation: UINavigationController
    let oracleNavigation: UINavigationController
    let homeViewModel: HomeViewModel
    let contentLoader: ContentLoader
}

/// Screenshot and QA rig, compiled into DEBUG builds only. `AOTD_DEMO=<route>` seeds a full
/// offline learner profile and opens the named screen; `AOTD_DEMO_PATH`, `AOTD_DEMO_LESSON`,
/// `AOTD_DEMO_DEITY` and `AOTD_DEMO_BOOK` pick which record a route shows.
enum DemoWorld {
    private nonisolated static let environment = ProcessInfo.processInfo.environment
    private static var questionFlow: QuestionFlowCoordinator?
    private static var pathCoordinator: LearningPathCoordinator?

    nonisolated static var route: String? { environment["AOTD_DEMO"] }
    nonisolated static var isActive: Bool { route != nil }

    private static var pathId: String { environment["AOTD_DEMO_PATH"] ?? "norse" }
    private static var lessonIndex: Int { Int(environment["AOTD_DEMO_LESSON"] ?? "") ?? 0 }
    private static var bookPathId: String { environment["AOTD_DEMO_BOOK"] ?? "norse" }

    static func prepare(database: DatabaseManager, contentLoader: ContentLoader) {
        guard isActive else { return }
        let beliefSystems = contentLoader.loadBeliefSystems()
        DemoSeed.reseed(database: database, beliefSystems: beliefSystems)
        BookContentGenerator(databaseManager: database, contentLoader: contentLoader).generateAndSaveAllBooks()
        DemoSeed.seedBookProgress(database: database)
    }

    static func present(_ context: DemoContext) {
        guard let route else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            open(route, in: context)
        }
    }

    private static func open(_ route: String, in context: DemoContext) {
        let root = context.root
        let tabs: [String: Int] = ["profile": 1, "oracle": 2, "library": 3, "settings": 4]
        if let reason = paywallReason(for: route) {
            root.present(PaywallViewController(reason: reason, journey: paywallJourney), animated: false)
        } else if let index = tabs[route] {
            root.selectViewController(at: index)
        } else {
            openScreen(route, in: context)
        }
    }

    private static func paywallReason(for route: String) -> PaywallReason? {
        let reasons: [String: PaywallReason] = [
            "paywall": .generalUpgrade,
            "paywall-path": .lockedPath(beliefSystemId: "norse"),
            "paywall-oracle": .oracleLimit(deityId: "anubis", deityName: "Anubis"),
            "paywall-lesson": .lessonFinished(nextPath: (id: "norse", name: "Norse")),
            "paywall-week": .premiumWeekEnded
        ]
        return reasons[route]
    }

    /// Who a demo paywall speaks to. `AOTD_DEMO_JOURNEY=first` is the first day (the demo verdict and one finished
    /// lesson), `unknown` is someone the app knows nothing about, and anything else is the seeded learner with the
    /// demo verdict.
    private static var paywallJourney: PaywallJourney {
        switch environment["AOTD_DEMO_JOURNEY"] {
        case "unknown":
            return .unknown
        case "first":
            return PaywallJourney(lessonsFinished: 1).ruled(JudgmentEngine.verdict(for: demoSoul))
        default:
            return PaywallJourney.live().ruled(JudgmentEngine.verdict(for: demoSoul))
        }
    }

    private static func openScreen(_ route: String, in context: DemoContext) {
        switch route {
        case "welcome", "judgment":
            presentJudgment(scenesAnswered: nil, in: context)
        case "judgment-scene":
            presentJudgment(scenesAnswered: Int(environment["AOTD_DEMO_SCENE"] ?? "") ?? 0, in: context)
        case "judgment-weighing":
            presentJudgment(scenesAnswered: JudgmentScript.scenes.count, in: context)
        case "judgment-verdict":
            presentJudgment(scenesAnswered: JudgmentScript.scenes.count, finish: true, in: context)
        case "soul-card":
            presentSoulCard(in: context)
        case "lesson-complete":
            pushResults(.firstLesson, in: context)
        case "lesson":
            pushLesson(in: context)
        case "path-map":
            if let system = beliefSystem(pathId, in: context) {
                context.homeViewModel.onPathSelected?(system)
            }
        case "quiz-mc":
            startQuiz(of: .multipleChoice, in: context)
        case "quiz-tf":
            startQuiz(of: .trueFalse, in: context)
        case "quiz-match":
            startQuiz(of: .matching, in: context)
        case "quiz-wrong":
            startQuiz(of: .multipleChoice, answering: false, in: context)
        case "quiz-results":
            pushResults(.lesson, in: context)
        case "mastery-pass":
            pushResults(.masteryPassed, in: context)
        case "mastery-fail":
            pushResults(.masteryFailed, in: context)
        case "path-complete":
            presentPathCompletion(in: context)
        case "mistakes":
            presentMistakeReview(in: context)
        case "reader":
            presentReader(in: context)
        case "oracle-deities":
            presentDeityPicker(in: context)
        default:
            break
        }
    }

    /// The answers the screenshot rig gives, one per scene: a truthful, generous soul who dies in battle, so the verdict
    /// shows Ra's barque, Fólkvangr and the House of the Sun.
    private static let demoAnswers = [1, 1, 1, 0, 0, 0, 0, 2, 2]

    /// The soul the demo answers weigh.
    private static var demoSoul: SoulRecord {
        var soul = SoulRecord()
        for (scene, pick) in zip(JudgmentScript.scenes, demoAnswers) {
            soul.record(scene.answers[pick])
        }
        return soul
    }

    private static func presentJudgment(scenesAnswered: Int?, finish: Bool = false, in context: DemoContext) {
        let viewModel = JudgmentViewModel(entry: .firstRun)
        let screen = JudgmentViewController(viewModel: viewModel) { _ in context.root.dismiss(animated: true) }
        context.root.present(screen, animated: false)
        guard let scenesAnswered else { return }
        viewModel.begin()
        for scene in 0..<min(scenesAnswered, demoAnswers.count) {
            viewModel.choose(answerAt: demoAnswers[scene])
        }
        if finish {
            viewModel.finishWeighing()
        }
    }

    /// The Soul Card the demo answers earn, full screen on black, as a photo viewer shows it after saving.
    private static func presentSoulCard(in context: DemoContext) {
        let soul = demoSoul
        let screen = UIViewController()
        let backdrop = UnderworldBackdropView()
        backdrop.frame = screen.view.bounds
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        screen.view.addSubview(backdrop)
        let image = UIImageView(image: SoulCardRenderer.render(JudgmentEngine.verdict(for: soul)))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        screen.view.addSubview(image)
        let guide = screen.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            image.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12),
            image.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            image.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
        ])
        screen.modalPresentationStyle = .fullScreen
        context.root.present(screen, animated: false)
    }

    private static func beliefSystem(_ id: String, in context: DemoContext) -> BeliefSystem? {
        context.contentLoader.loadBeliefSystems().first { $0.id == id }
    }

    enum ResultsScene {
        case firstLesson
        case lesson
        case masteryPassed
        case masteryFailed
    }

    /// Results built from real questions of the demo path: every third answer wrong, or all but two wrong for a failed
    /// mastery test, each wrong one with a plausible wrong answer.
    private static func pushResults(_ scene: ResultsScene, in context: DemoContext) {
        guard let system = beliefSystem(pathId, in: context) else { return }
        let isMastery = scene == .masteryPassed || scene == .masteryFailed
        let lessonPosition = min(lessonIndex, max(system.lessons.count - 1, 0))
        let questions = isMastery ? system.masteryTest.questions : system.lessons[lessonPosition].questions
        let results = questions.enumerated().map { offset, question in
            let correct: Bool
            switch scene {
            case .masteryFailed: correct = offset < 2
            case .masteryPassed: correct = offset != 1
            case .lesson, .firstLesson: correct = offset % 3 != 1
            }
            return demoResult(for: question, in: system, index: offset, total: questions.count, correctly: correct)
        }
        let kind: QuizResultsViewModel.Kind = isMastery
            ? .mastery(requiredScore: system.masteryTest.requiredScore)
            : .lesson(title: system.lessons[lessonPosition].title)
        let bonus = isMastery ? (scene == .masteryPassed ? system.masteryTest.xpReward : 0) : system.lessons[lessonPosition].xpReward
        let summary = QuizResultsViewModel(kind: kind, beliefSystem: system, results: results, bonusXP: bonus)
        let back: () -> Void = { context.homeNavigation.popToRootViewController(animated: true) }
        var actions: [QuizResultsViewController.Action] = []
        if scene == .masteryFailed {
            actions.append(.init(title: String(localized: "Try Again"), symbol: "arrow.clockwise", style: .primary, handler: back))
            actions.append(.init(title: String(localized: "Back to Path"), symbol: nil, style: .secondary, handler: back))
        } else {
            actions.append(.init(title: String(localized: "Continue"), symbol: nil, style: .primary, handler: back))
            if summary.mistakeCount > 0 {
                actions.append(.init(title: String(localized: "Practice Mistakes (\(summary.mistakeCount))"), symbol: "arrow.counterclockwise", style: .secondary, handler: back))
            }
        }
        let screen = QuizResultsViewController(viewModel: summary, actions: actions, reminder: scene == .firstLesson ? DailyReminder.shared : nil)
        screen.onClose = back
        context.homeNavigation.pushViewController(screen, animated: false)
    }

    private static func demoResult(for question: Question, in system: BeliefSystem, index: Int, total: Int, correctly: Bool) -> QuestionResult {
        let outcome: QuestionOutcome
        switch question.type {
        case .multipleChoice:
            let viewModel = MultipleChoiceViewModel(question: question, beliefSystem: system, currentQuestionIndex: index, totalQuestions: total)
            let right = viewModel.correctAnswerText
            let answer = correctly ? right : (viewModel.options.first { $0 != right } ?? right)
            outcome = viewModel.outcome(for: answer)
        case .trueFalse:
            let viewModel = BaseQuestionViewModel(question: question, beliefSystem: system, currentQuestionIndex: index, totalQuestions: total)
            var right = "true"
            if case .string(let answer) = question.correctAnswer.value { right = answer.lowercased() }
            outcome = viewModel.outcome(for: correctly ? right : (right == "true" ? "false" : "true"))
        case .matching:
            let viewModel = MatchingQuestionViewModel(question: question, beliefSystem: system, currentQuestionIndex: index, totalQuestions: total)
            var rights = viewModel.leftItems.map { viewModel.correctPartner(for: $0) ?? "" }
            if !correctly, rights.count > 1 { rights.swapAt(0, 1) }
            let matches = zip(viewModel.leftItems, rights).map { MatchingQuestionViewModel.Match(left: $0, right: $1) }
            outcome = viewModel.outcome(for: matches)
        }
        return QuestionResult(question: question, outcome: outcome, xpEarned: outcome.isCorrect ? 10 : 0)
    }

    private static func pushLesson(in context: DemoContext) {
        guard let system = beliefSystem(pathId, in: context), system.lessons.indices.contains(lessonIndex) else { return }
        let viewModel = LessonViewModel(
            lesson: system.lessons[lessonIndex],
            beliefSystem: system,
            currentLessonIndex: lessonIndex,
            totalLessons: system.lessons.count
        )
        context.homeNavigation.pushViewController(LessonViewController(viewModel: viewModel), animated: false)
    }

    /// Opens a quiz at its first question of `type`, or at `AOTD_DEMO_QUESTION` when it names one. `answering` (or
    /// `AOTD_DEMO_ANSWER=right|wrong`) checks an answer so the feedback panel is open.
    private static func startQuiz(of type: Question.QuestionType, answering: Bool? = nil, in context: DemoContext) {
        guard let quiz = demoQuizQuestions(of: type, in: context) else { return }
        let flow = QuestionFlowCoordinator(
            navigationController: context.homeNavigation,
            questions: quiz.questions,
            beliefSystem: quiz.system,
            startingAt: quiz.start
        )
        questionFlow = flow
        flow.start()
        let requested = environment["AOTD_DEMO_ANSWER"].map { $0 == "right" } ?? answering
        guard let correctly = requested else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            flow.demoAnswerCurrentQuestion(correctly: correctly)
        }
    }

    private static func demoQuizQuestions(of type: Question.QuestionType, in context: DemoContext) -> (system: BeliefSystem, questions: [Question], start: Int)? {
        if let questionId = environment["AOTD_DEMO_QUESTION"] {
            for system in context.contentLoader.loadBeliefSystems() {
                for lesson in system.lessons {
                    if let start = lesson.questions.firstIndex(where: { $0.id == questionId }) {
                        return (system, lesson.questions, start)
                    }
                }
                if let start = system.masteryTest.questions.firstIndex(where: { $0.id == questionId }) {
                    return (system, system.masteryTest.questions, start)
                }
            }
        }
        let preferredPath = type == .matching ? "aboriginal-dreamtime" : pathId
        guard let system = beliefSystem(preferredPath, in: context),
              let lesson = system.lessons.dropFirst(type == .matching ? 0 : lessonIndex).first(where: { lesson in
                  lesson.questions.contains { $0.type == type }
              }),
              let start = lesson.questions.firstIndex(where: { $0.type == type }) else { return nil }
        return (system, lesson.questions, start)
    }

    private static func presentPathCompletion(in context: DemoContext) {
        guard let system = beliefSystem("judaism", in: context),
              let user = DatabaseManager.shared.fetchUser(),
              let progress = try? DatabaseManager.shared.getProgress(userId: user.id, beliefSystemId: system.id) else { return }
        let coordinator = LearningPathCoordinator(
            navigationController: context.homeNavigation,
            beliefSystem: system,
            contentLoader: context.contentLoader
        )
        pathCoordinator = coordinator
        context.root.present(
            PathCompletionOptionsViewController(beliefSystem: system, progress: progress, coordinator: coordinator),
            animated: false
        )
    }

    private static func presentMistakeReview(in context: DemoContext) {
        let database = DatabaseManager.shared
        guard let system = beliefSystem(pathId, in: context),
              let user = database.fetchUser(),
              let mistakes = try? database.getMistakes(userId: user.id, beliefSystemId: system.id),
              !mistakes.isEmpty,
              let session = try? database.startMistakeSession(userId: user.id, beliefSystemId: system.id),
              let home = context.homeNavigation.viewControllers.first as? HomeViewController else { return }
        home.presentMistakeReview(of: system, mistakes: mistakes, session: session)
    }

    private static func presentReader(in context: DemoContext) {
        let database = DatabaseManager.shared
        guard let user = database.fetchUser(),
              let book = try? database.getBook(by: "book_\(bookPathId)") else { return }
        let reader = BookReaderViewController(viewModel: BookReaderViewModel(book: book, userId: user.id))
        context.root.present(reader, animated: false)
    }

    private static func presentDeityPicker(in context: DemoContext) {
        context.root.selectViewController(at: 2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let oracle = context.oracleNavigation.viewControllers.first
            oracle?.perform(NSSelectorFromString("selectDeity"))
        }
    }
}
#endif
