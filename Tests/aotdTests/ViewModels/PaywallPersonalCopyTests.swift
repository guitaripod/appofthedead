import AppOfTheDeadCore
import XCTest
@testable import aotd

@MainActor final class PaywallPersonalCopyTests: XCTestCase {

    private static let verdict = Verdict(
        archetype: .chosenOfValkyries,
        realms: [.fieldOfReeds, .elysium, .valhalla, .mictlan, .houseOfSong, .humanRealm],
        xoloCarries: true)

    private static let ruled = PaywallJourney(verdict: verdict, guideName: "Odin")

    private static let everyReason: [PaywallReason] = [
        .lockedPath(beliefSystemId: "norse"),
        .oracleLimit(deityId: "odin", deityName: "Odin"),
        .generalUpgrade,
        .lessonFinished(nextPath: (id: "norse", name: "Norse")),
        .lessonFinished(nextPath: nil),
        .premiumWeekEnded
    ]

    func testSomeoneUnknownKeepsEveryGeneralLine() {
        for reason in Self.everyReason {
            XCTAssertNil(PaywallPersonalCopy.subtitle(for: reason, journey: .unknown))
            XCTAssertEqual(PaywallViewModel(reason: reason, journey: .unknown).subtitle, reason.subtitle())
        }
        XCTAssertNil(PaywallPersonalCopy.pathsDetail(.unknown))
        XCTAssertNil(PaywallPersonalCopy.oracleDetail(.unknown))
        XCTAssertNil(PaywallPersonalCopy.achievementsDetail(.unknown))
    }

    func testALockedPathTellsTheRealmTheJudgmentRuledThere() {
        let subtitle = PaywallPersonalCopy.subtitle(for: .lockedPath(beliefSystemId: "norse"), journey: Self.ruled)

        XCTAssertEqual(subtitle, "Your soul's fate in this tradition: Valhalla. This path tells the whole story.")
    }

    func testEveryJudgedTraditionHasItsRealmOnItsLockedPath() {
        for tradition in JudgmentTradition.allCases {
            let subtitle = PaywallPersonalCopy.subtitle(for: .lockedPath(beliefSystemId: tradition.pathId), journey: Self.ruled)
            let realm = Self.verdict.realm(in: tradition).map(JudgmentCopy.realmName)

            XCTAssertNotNil(realm)
            XCTAssertTrue(subtitle?.contains(realm ?? "") == true, tradition.rawValue)
        }
    }

    func testAPathTheJudgmentDoesNotRuleOnKeepsItsGeneralLine() {
        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .lockedPath(beliefSystemId: "christianity"), journey: Self.ruled))
        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .lockedPath(beliefSystemId: "norse"), journey: PaywallJourney(lessonsFinished: 9)))
    }

    func testTheFirstLessonOfferTellsTheRulingForThePathItNames() {
        var journey = Self.ruled
        journey.lessonsFinished = 1

        let subtitle = PaywallPersonalCopy.subtitle(for: .lessonFinished(nextPath: (id: "norse", name: "Norse")), journey: journey)

        XCTAssertEqual(subtitle, "The Judgment's ruling on your soul: Valhalla. Norse and every other path are one step away.")
    }

    func testTheFirstLessonOfferStaysGeneralWithoutAVerdictOrANamedPath() {
        let oneLesson = PaywallJourney(lessonsFinished: 1)
        var ruledOnce = Self.ruled
        ruledOnce.lessonsFinished = 1

        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .lessonFinished(nextPath: (id: "norse", name: "Norse")), journey: oneLesson))
        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .lessonFinished(nextPath: nil), journey: ruledOnce))
        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .lessonFinished(nextPath: (id: "islam", name: "Islam")), journey: ruledOnce))
    }

    func testLaterLessonOffersCountTheLessonsFinished() {
        var journey = Self.ruled
        journey.lessonsFinished = PaywallPersonalCopy.lessonsWorthCounting + 1

        XCTAssertEqual(
            PaywallPersonalCopy.subtitle(for: .lessonFinished(nextPath: (id: "norse", name: "Norse")), journey: journey),
            "4 lessons finished so far.\nNorse and every other path are one step away.")
        XCTAssertEqual(
            PaywallPersonalCopy.subtitle(for: .lessonFinished(nextPath: nil), journey: journey),
            "4 lessons finished so far.\nAll 21 paths are one step away.")
    }

    func testLessonsAreCountedOnlyFromTheThreshold() {
        let below = PaywallJourney(lessonsFinished: PaywallPersonalCopy.lessonsWorthCounting - 1)
        let at = PaywallJourney(lessonsFinished: PaywallPersonalCopy.lessonsWorthCounting)

        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .generalUpgrade, journey: below))
        XCTAssertEqual(
            PaywallPersonalCopy.subtitle(for: .generalUpgrade, journey: at),
            "3 lessons finished so far.\n\(PaywallReason.generalUpgrade.subtitle())")
    }

    func testTheOracleLimitCountsTheQuestionsAsked() {
        let reason = PaywallReason.oracleLimit(deityId: "odin", deityName: "Odin")

        XCTAssertNil(PaywallPersonalCopy.subtitle(for: reason, journey: PaywallJourney(oracleQuestions: 2)))
        XCTAssertEqual(
            PaywallPersonalCopy.subtitle(for: reason, journey: PaywallJourney(oracleQuestions: 7)),
            "You have asked the Oracle 7 questions. Ask all 21 guides without limits.")
    }

    func testTheEndOfThePremiumWeekNamesTheLessonsThatStay() {
        XCTAssertNil(PaywallPersonalCopy.subtitle(for: .premiumWeekEnded, journey: PaywallJourney(lessonsFinished: 1)))
        XCTAssertEqual(
            PaywallPersonalCopy.subtitle(for: .premiumWeekEnded, journey: PaywallJourney(lessonsFinished: 6)),
            "Your 6 finished lessons stay exactly where you left them. Keep every path and every god open.")
    }

    func testTheBenefitsSpeakOfTheVerdictAndItsGuide() {
        XCTAssertEqual(PaywallPersonalCopy.pathsDetail(Self.ruled), "Including the six afterlives that judged your soul")
        XCTAssertEqual(PaywallPersonalCopy.oracleDetail(Self.ruled), "Odin, your guide from the Judgment, and 20 more")
        XCTAssertNil(PaywallPersonalCopy.oracleDetail(PaywallJourney(verdict: Self.verdict)))
        XCTAssertNil(PaywallPersonalCopy.oracleDetail(PaywallJourney(guideName: "Odin")))
    }

    func testAchievementsAreCountedOnceOneIsEarned() {
        XCTAssertNil(PaywallPersonalCopy.achievementsDetail(PaywallJourney(achievements: 0)))
        XCTAssertEqual(
            PaywallPersonalCopy.achievementsDetail(PaywallJourney(achievements: 4)),
            "4 earned so far. Every path holds more.")
    }

    func testThePaywallTellsItsBenefitsAboutThePerson() {
        var journey = Self.ruled
        journey.achievements = 2
        let general = PaywallViewModel(reason: .generalUpgrade, journey: journey).features.map(\.description)
        let oracle = PaywallViewModel(reason: .oracleLimit(deityId: "odin", deityName: "Odin"), journey: journey).features.map(\.description)
        let lesson = PaywallViewModel(reason: .lessonFinished(nextPath: nil), journey: journey).features.map(\.description)

        XCTAssertEqual(general, [
            "Including the six afterlives that judged your soul",
            "Odin, your guide from the Judgment, and 20 more",
            "2 earned so far. Every path holds more."
        ])
        XCTAssertEqual(oracle.prefix(2), [
            "Odin, your guide from the Judgment, and 20 more",
            "Including the six afterlives that judged your soul"
        ])
        XCTAssertEqual(lesson.last, "New paths included as they arrive")
    }

    func testAVerdictBringsTheGuideItSendsThePersonTo() {
        let journey = PaywallJourney().ruled(Self.verdict)

        XCTAssertEqual(journey.verdict, Self.verdict)
        XCTAssertEqual(journey.guideName, OracleDeityDirectory.name(for: SoulArchetype.chosenOfValkyries.guideDeityId))
        XCTAssertNotNil(journey.guideName)
    }

    func testFinishedLessonsCountEachLessonOnceAndNothingElse() {
        let progress = [
            Self.progress(path: "judaism", lesson: "l1", status: .completed),
            Self.progress(path: "judaism", lesson: "l1", status: .mastered),
            Self.progress(path: "judaism", lesson: "l2", status: .inProgress),
            Self.progress(path: "judaism", lesson: "l3", question: "q1", status: .completed),
            Self.progress(path: "judaism", lesson: nil, status: .completed),
            Self.progress(path: "norse", lesson: "l1", status: .completed)
        ]

        XCTAssertEqual(PaywallJourney.finishedLessons(in: progress), 2)
        XCTAssertEqual(PaywallJourney.finishedLessons(in: []), 0)
    }

    private static func progress(path: String, lesson: String?, question: String? = nil, status: aotd.Progress.ProgressStatus) -> aotd.Progress {
        var progress = aotd.Progress(userId: "user", beliefSystemId: path, lessonId: lesson, questionId: question)
        progress.status = status
        return progress
    }
}
