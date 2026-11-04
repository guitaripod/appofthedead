import Foundation
import Testing
@testable import AppOfTheDeadCore

@Suite("Judgment")
struct JudgmentTests {

    /// Every combination of answers, as souls: 4^9 records.
    private static let everySoul: [SoulRecord] = {
        var souls = [SoulRecord()]
        for scene in JudgmentScript.scenes {
            souls = souls.flatMap { soul in
                scene.answers.map { answer in
                    var next = soul
                    next.record(answer)
                    return next
                }
            }
        }
        return souls
    }()

    private static let everyVerdict: [Verdict] = everySoul.map(JudgmentEngine.verdict(for:))

    @Test func scriptHasNineScenesOfFourAnswers() {
        #expect(JudgmentScript.scenes.count == 9)
        #expect(JudgmentScript.scenes.allSatisfy { $0.answers.count == 4 })
        #expect(Set(JudgmentScript.scenes.map(\.id)).count == 9)
        for scene in JudgmentScript.scenes {
            #expect(Set(scene.answers.map(\.id)).count == 4, "duplicate answer id in \(scene.id)")
        }
    }

    @Test func exactlyOneSceneNamesTheMannerOfDeath() {
        let mannerScenes = JudgmentScript.scenes.filter { $0.answers.contains { $0.manner != nil } }
        #expect(mannerScenes.map(\.id) == ["odin"])
        #expect(Set(mannerScenes[0].answers.compactMap(\.manner)) == Set(DeathManner.allCases))
    }

    @Test func everyRealmCanBeReached() {
        let reached = Set(Self.everyVerdict.flatMap(\.realms))
        #expect(reached == Set(Realm.allCases), "unreachable: \(Set(Realm.allCases).subtracting(reached))")
    }

    @Test func everyArchetypeCanBeReached() {
        let reached = Set(Self.everyVerdict.map(\.archetype))
        #expect(reached == Set(SoulArchetype.allCases))
    }

    @Test func noRealmSwallowsItsTradition() {
        for tradition in JudgmentTradition.allCases where tradition != .norse && tradition != .aztec {
            var counts: [Realm: Int] = [:]
            for verdict in Self.everyVerdict {
                if let realm = verdict.realm(in: tradition) { counts[realm, default: 0] += 1 }
            }
            let largest = counts.values.max() ?? 0
            #expect(Double(largest) / Double(Self.everyVerdict.count) < 0.8, "\(tradition): \(counts)")
        }
    }

    @Test func grimFatesStayTheMinority() {
        for tradition in JudgmentTradition.allCases {
            let grim = Self.everyVerdict.filter { $0.realm(in: tradition)?.isGrim == true }.count
            #expect(Double(grim) / Double(Self.everyVerdict.count) < 0.35, "\(tradition) grim share too high")
        }
    }

    @Test func verdictHasOneRealmPerTraditionInOrder() {
        let verdict = JudgmentEngine.verdict(for: SoulRecord())
        #expect(verdict.realms.map(\.tradition) == JudgmentTradition.allCases)
    }

    @Test func mannerOfDeathDecidesNorseAndAztecFates() {
        var warrior = SoulRecord(scores: [.courage: 5], manner: .battle)
        #expect(JudgmentEngine.realm(in: .norse, for: warrior) == .valhalla)
        #expect(JudgmentEngine.realm(in: .aztec, for: warrior) == .houseOfTheSun)
        warrior.scores = [.courage: 1, .compassion: 4]
        #expect(JudgmentEngine.realm(in: .norse, for: warrior) == .folkvangr)
        let sailor = SoulRecord(scores: [:], manner: .water)
        #expect(JudgmentEngine.realm(in: .norse, for: sailor) == .ransHall)
        #expect(JudgmentEngine.realm(in: .aztec, for: sailor) == .tlalocan)
        let elder = SoulRecord(scores: [:], manner: .oldAge)
        #expect(JudgmentEngine.realm(in: .norse, for: elder) == .hel)
        #expect(JudgmentEngine.realm(in: .aztec, for: elder) == .mictlan)
    }

    @Test func oathBreakersGoToTheCorpseShoreWhateverTheirDeath() {
        let liar = SoulRecord(scores: [.truth: -3, .courage: 6], manner: .battle)
        #expect(JudgmentEngine.realm(in: .norse, for: liar) == .nastrond)
    }

    @Test func aHeavyHeartMeetsAmmit() {
        let proud = SoulRecord(scores: [.hubris: 4, .truth: -1], manner: .oldAge)
        #expect(JudgmentEngine.realm(in: .egyptian, for: proud) == .ammit)
        let pure = SoulRecord(scores: [.truth: 5, .compassion: 3], manner: .oldAge)
        #expect(JudgmentEngine.realm(in: .egyptian, for: pure) == .solarBarque)
    }

    @Test func archetypeTiesResolveInVirtueOrder() {
        let tied = SoulRecord(scores: [.courage: 3, .truth: 3], manner: .oldAge)
        #expect(JudgmentEngine.archetype(for: tied) == .featherLight)
        let curious = SoulRecord(scores: [.curiosity: 4, .truth: 1], manner: .seeking)
        #expect(JudgmentEngine.archetype(for: curious) == .initiate)
    }

    @Test func leadingTraditionFavoursTheMostStrikingRealm() {
        let warrior = JudgmentEngine.verdict(for: SoulRecord(scores: [.courage: 5], manner: .battle))
        #expect(warrior.leadingTradition == .norse)
        let plain = JudgmentEngine.verdict(for: SoulRecord(scores: [.truth: 1], manner: .oldAge))
        #expect(plain.leadingTradition == .egyptian)
    }

    @Test func soulRecordRoundTripsThroughJSON() throws {
        var soul = SoulRecord()
        soul.record(JudgmentScript.scenes[5].answers[1])
        let data = try JSONEncoder().encode(soul)
        #expect(try JSONDecoder().decode(SoulRecord.self, from: data) == soul)
        #expect(soul.manner == .water)
    }

    @Test func archetypeGuidesAreDistinctOracleDeities() {
        let guides = SoulArchetype.allCases.map(\.guideDeityId)
        #expect(Set(guides).count == guides.count)
    }
}
