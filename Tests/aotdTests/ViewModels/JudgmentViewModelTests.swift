import XCTest
import AppOfTheDeadCore
@testable import aotd

@MainActor final class JudgmentViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var now = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() {
        super.setUp()
        suiteName = "JudgmentViewModelTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeViewModel(entry: JudgmentViewModel.Entry = .firstRun, owns: Bool = false) -> (JudgmentViewModel, PremiumWeekPass) {
        let clock = now
        let pass = PremiumWeekPass(store: .local(defaults: defaults), now: { clock }, notifications: NotificationCenter())
        let viewModel = JudgmentViewModel(
            entry: entry,
            store: JudgmentStore(defaults: defaults, mirrorsToCloud: false),
            premiumWeek: pass,
            ownsAllAccess: { owns }
        )
        return (viewModel, pass)
    }

    private func answerEveryScene(_ viewModel: JudgmentViewModel, with pick: Int = 0) {
        viewModel.begin()
        for _ in viewModel.scenes {
            viewModel.choose(answerAt: pick)
        }
    }

    func testStartsAtTheIntroAndWalksTheScenesInOrder() {
        let (viewModel, _) = makeViewModel()
        XCTAssertEqual(viewModel.stage, .intro)
        viewModel.begin()
        XCTAssertEqual(viewModel.stage, .scene(0))
        viewModel.choose(answerAt: 2)
        XCTAssertEqual(viewModel.stage, .scene(1))
        XCTAssertEqual(viewModel.picks, [2])
    }

    func testTheLastAnswerLeadsToTheWeighing() {
        let (viewModel, _) = makeViewModel()
        answerEveryScene(viewModel)
        XCTAssertEqual(viewModel.stage, .weighing)
        XCTAssertEqual(viewModel.picks.count, viewModel.sceneCount)
    }

    func testGoingBackForgetsTheLastAnswer() {
        let (viewModel, _) = makeViewModel()
        viewModel.begin()
        viewModel.choose(answerAt: 1)
        viewModel.choose(answerAt: 3)
        viewModel.goBack()
        XCTAssertEqual(viewModel.stage, .scene(1))
        XCTAssertEqual(viewModel.picks, [1])
        viewModel.goBack()
        viewModel.goBack()
        XCTAssertEqual(viewModel.stage, .intro)
    }

    func testOutOfRangeAnswersAreIgnored() {
        let (viewModel, _) = makeViewModel()
        viewModel.begin()
        viewModel.choose(answerAt: 9)
        XCTAssertEqual(viewModel.stage, .scene(0))
        XCTAssertTrue(viewModel.picks.isEmpty)
    }

    func testFinishingSavesTheSoulAndRulesOnIt() {
        let (viewModel, _) = makeViewModel()
        answerEveryScene(viewModel, with: 1)
        let soul = viewModel.soul
        viewModel.finishWeighing()
        XCTAssertEqual(viewModel.stage, .verdict(JudgmentEngine.verdict(for: soul)))
        XCTAssertEqual(JudgmentStore(defaults: defaults, mirrorsToCloud: false).load(), soul)
    }

    func testTheFirstVerdictOpensThePremiumWeekOnce() {
        let (first, pass) = makeViewModel()
        answerEveryScene(first)
        first.finishWeighing()
        XCTAssertTrue(first.startedPremiumWeek)
        XCTAssertTrue(pass.isActive)
        XCTAssertEqual(first.premiumWeekEnd, now.addingTimeInterval(PremiumWeek.length))

        let (second, _) = makeViewModel(entry: .retake)
        answerEveryScene(second)
        second.finishWeighing()
        XCTAssertFalse(second.startedPremiumWeek)
    }

    func testABuyerNeverGetsAPremiumWeek() {
        let (viewModel, pass) = makeViewModel(owns: true)
        answerEveryScene(viewModel)
        viewModel.finishWeighing()
        XCTAssertFalse(viewModel.startedPremiumWeek)
        XCTAssertEqual(pass.phase, .notStarted)
    }

    func testReviewOpensOnTheSavedVerdict() {
        let verdict = JudgmentEngine.verdict(for: SoulRecord(scores: [.courage: 5], manner: .battle))
        let (viewModel, _) = makeViewModel(entry: .review(verdict))
        XCTAssertEqual(viewModel.stage, .verdict(verdict))
        viewModel.begin()
        XCTAssertEqual(viewModel.stage, .verdict(verdict))
    }

    func testShareMessageNamesTheArchetype() {
        let verdict = JudgmentEngine.verdict(for: SoulRecord(scores: [.truth: 5], manner: .oldAge))
        let (viewModel, _) = makeViewModel()
        XCTAssertTrue(viewModel.shareMessage(for: verdict).contains(JudgmentCopy.archetypeName(.featherLight)))
    }
}
