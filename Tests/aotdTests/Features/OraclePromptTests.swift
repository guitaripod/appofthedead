import XCTest
import AppOfTheDeadCore
@testable import aotd

@MainActor final class OraclePromptTests: XCTestCase {

    func testGroundingFindsTheSentencesThatShareTheQuestionsWords() {
        let systems = ContentLoader().loadBeliefSystems()
        let grounding = OraclePrompt.grounding(deityId: "mictlantecuhtli", question: "Why does a dog guide the dead in Mictlan?", systems: systems)
        XCTAssertFalse(grounding.isEmpty)
        XCTAssertTrue(grounding.contains { $0.lowercased().contains("dog") }, "\(grounding)")
        XCTAssertLessThanOrEqual(grounding.count, 5)
    }

    func testGroundingFallsBackToTheOpeningWhenNothingMatches() {
        let systems = ContentLoader().loadBeliefSystems()
        let grounding = OraclePrompt.grounding(deityId: "anubis", question: "xyzzy plugh", systems: systems)
        XCTAssertEqual(grounding.count, 3)
    }

    func testDeitiesWithoutAPathGetNoGrounding() {
        let systems = ContentLoader().loadBeliefSystems()
        XCTAssertTrue(OraclePrompt.grounding(deityId: "baron_samedi", question: "Who guards the crossroads?", systems: systems).isEmpty)
    }

    func testEveryMappedPathExists() {
        let ids = Set(ContentLoader().loadBeliefSystems().map(\.id))
        for (deity, paths) in OraclePrompt.pathsByDeity {
            for path in paths {
                XCTAssertTrue(ids.contains(path), "\(deity) maps to unknown path \(path)")
            }
        }
    }

    func testInstructionsCarryTheRulesAndOnlyMentionSuicideWhenAsked() {
        let plain = OraclePrompt.instructions(persona: "You are Odin.", deityName: "Odin", grounding: ["Valhalla is Odin's hall."])
        XCTAssertTrue(plain.contains("Never quote scripture"))
        XCTAssertTrue(plain.contains("- Valhalla is Odin's hall."))
        XCTAssertFalse(plain.lowercased().contains("suicide"))
        let asked = OraclePrompt.instructions(persona: "You are Odin.", deityName: "Odin", grounding: [], mentionsSelfHarm: true)
        XCTAssertTrue(asked.lowercased().contains("suicide"))
        XCTAssertTrue(OraclePrompt.mentionsSelfHarm("What did the Greeks think of suicide?"))
        XCTAssertFalse(OraclePrompt.mentionsSelfHarm("What is Valhalla?"))
    }

    func testPromptKeepsTheLastTwoTurns() {
        let turns = (1...3).map { OraclePrompt.Turn(question: "Q\($0)", answer: "A\($0)") }
        let prompt = OraclePrompt.prompt(question: "Q4", history: turns)
        XCTAssertFalse(prompt.contains("Q1"))
        XCTAssertTrue(prompt.contains("Seeker: Q2"))
        XCTAssertTrue(prompt.contains("You: A3"))
        XCTAssertTrue(prompt.hasSuffix("The seeker now says: Q4"))
        XCTAssertEqual(OraclePrompt.prompt(question: "Hello", history: []), "Hello")
        let wall = String(repeating: "a", count: 5000)
        XCTAssertLessThanOrEqual(OraclePrompt.prompt(question: wall, history: []).count, OraclePrompt.questionLimit + 1)
    }

    func testCompassionGuardCatchesFirstPersonDistressInSeveralLanguages() {
        for message in [
            "I want to die", "i'm going to kill myself tonight", "Ich will sterben", "quiero morir", "死にたい",
            "I don’t want to live anymore", "I am thinking of harming myself", "I keep hurting myself",
            "I've been cutting myself again", "Ich will mich verletzen", "quiero hacerme daño", "자해를 했어요",
        ] {
            XCTAssertTrue(CompassionGuard.needsCare(message), message)
        }
        for message in ["What happens to people who die in battle?", "Why did the Greeks bury suicides apart?", "Tell me about Hel", "Did Vikings want to die in battle?", "Why do souls end up in Hel?"] {
            XCTAssertFalse(CompassionGuard.needsCare(message), message)
        }
    }

    func testThinkBlocksNeverReachTheReader() {
        var filter = ThinkBlockFilter()
        XCTAssertNil(filter.visibleText(after: "<think>plan"))
        XCTAssertNil(filter.visibleText(after: " more</think>"))
        XCTAssertEqual(filter.visibleText(after: " Hello"), "Hello")
        XCTAssertEqual(filter.visibleText(after: " there"), " there")
        var plain = ThinkBlockFilter()
        XCTAssertEqual(plain.visibleText(after: "Hi"), "Hi")
        var split = ThinkBlockFilter()
        XCTAssertNil(split.visibleText(after: "<thi"))
        XCTAssertNil(split.visibleText(after: "nk>plan</think>"))
        XCTAssertEqual(split.visibleText(after: "Answer"), "Answer")
    }

    @MainActor
    func testQuoteCardIsFeedSizedAndTrimsLongReplies() {
        let deity = OracleViewModel.Deity(id: "anubis", name: "Anubis", tradition: "Egyptian", role: "Guide of Souls", avatar: "figure.stand", color: "#D4A574", systemPrompt: "", suggestedPrompts: nil)
        let long = String(repeating: "The heart is weighed. ", count: 40)
        XCTAssertLessThanOrEqual(OracleQuoteRenderer.trimmed(long).count, 421)
        XCTAssertFalse(OracleQuoteRenderer.trimmed("**Bold** truth.").contains("**"))
        let image = OracleQuoteRenderer.render(reply: long, question: "What happens when I die?", deity: deity)
        XCTAssertEqual(image.size, OracleQuoteRenderer.size)
    }
}
