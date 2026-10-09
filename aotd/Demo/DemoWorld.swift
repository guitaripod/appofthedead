#if DEBUG
import UIKit

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
    private static let environment = ProcessInfo.processInfo.environment
    private static var questionFlow: QuestionFlowCoordinator?
    private static var pathCoordinator: LearningPathCoordinator?

    static var route: String? { environment["AOTD_DEMO"] }
    static var isActive: Bool { route != nil }

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
            root.present(PaywallViewController(reason: reason), animated: false)
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
            "paywall-oracle": .oracleLimit(deityId: "anubis", deityName: "Anubis")
        ]
        return reasons[route]
    }

    private static func openScreen(_ route: String, in context: DemoContext) {
        switch route {
        case "welcome":
            context.root.present(WelcomeViewController(onStart: { context.root.dismiss(animated: true) }), animated: false)
        case "lesson-complete":
            presentLessonComplete(in: context)
        case "lesson":
            pushLesson(in: context)
        case "quiz-mc":
            startQuiz(of: .multipleChoice, in: context)
        case "quiz-tf":
            startQuiz(of: .trueFalse, in: context)
        case "quiz-match":
            startQuiz(of: .matching, in: context)
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

    private static func beliefSystem(_ id: String, in context: DemoContext) -> BeliefSystem? {
        context.contentLoader.loadBeliefSystems().first { $0.id == id }
    }

    private static func presentLessonComplete(in context: DemoContext) {
        let summary = LessonCompleteViewController.Summary(
            lessonTitle: "Judaism: The Sanctity of This Life",
            correctAnswers: 5,
            totalQuestions: 6,
            xpReward: 86
        )
        let screen = LessonCompleteViewController(summary: summary, onContinue: {}, onClose: {})
        context.root.present(UINavigationController(rootViewController: screen), animated: false)
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

    private static func startQuiz(of type: Question.QuestionType, in context: DemoContext) {
        let preferredPath = type == .matching ? "aboriginal-dreamtime" : pathId
        guard let system = beliefSystem(preferredPath, in: context),
              let lesson = system.lessons.dropFirst(type == .matching ? 0 : lessonIndex).first(where: { lesson in
                  lesson.questions.contains { $0.type == type }
              }),
              let start = lesson.questions.firstIndex(where: { $0.type == type }) else { return }
        let flow = QuestionFlowCoordinator(
            navigationController: context.homeNavigation,
            questions: lesson.questions,
            beliefSystem: system,
            startingAt: start
        )
        questionFlow = flow
        flow.start()
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
              let session = try? database.startMistakeSession(userId: user.id, beliefSystemId: system.id) else { return }
        let review = MistakeReviewViewController(
            beliefSystem: system,
            mistakes: mistakes,
            session: session,
            contentLoader: context.contentLoader
        )
        let navigation = UINavigationController(rootViewController: review)
        navigation.modalPresentationStyle = .fullScreen
        context.root.present(navigation, animated: false)
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
