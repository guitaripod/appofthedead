import XCTest
import AppOfTheDeadCore
@testable import aotd

@MainActor final class SoulCardRendererTests: XCTestCase {

    func testRendersAStorySizedCardForEveryArchetype() throws {
        for archetype in SoulArchetype.allCases {
            var soul = SoulRecord(scores: [archetype.virtue: 9], manner: .battle)
            if archetype == .trickster { soul.scores[.truth] = -3 }
            let verdict = JudgmentEngine.verdict(for: soul)
            XCTAssertEqual(verdict.archetype, archetype)
            let image = SoulCardRenderer.render(verdict)
            XCTAssertEqual(image.size, SoulCardRenderer.size)
            XCTAssertEqual(image.scale, 1)
            if let directory = ProcessInfo.processInfo.environment["MIDGAR_SNAPSHOT_DIR"] {
                let url = URL(fileURLWithPath: directory).appendingPathComponent("soul-card-\(archetype.rawValue).png")
                try XCTUnwrap(image.pngData()).write(to: url)
            }
        }
    }

    func testEverySymbolTheJudgmentUsesExists() {
        var symbols = Realm.allCases.map(JudgmentCopy.realmSymbol)
        symbols += SoulArchetype.allCases.map(JudgmentCopy.archetypeSymbol)
        symbols += JudgmentScript.scenes.map { JudgmentCopy.guardian(for: $0).symbol }
        for symbol in symbols {
            XCTAssertNotNil(UIImage(systemName: symbol), "missing SF Symbol \(symbol)")
        }
    }

    func testEveryAnswerHasItsOwnWords() {
        for scene in JudgmentScript.scenes {
            for answer in scene.answers {
                XCTAssertNotEqual(JudgmentCopy.answer(answer, in: scene), answer.id, "\(scene.id).\(answer.id) has no copy")
            }
        }
    }
}
