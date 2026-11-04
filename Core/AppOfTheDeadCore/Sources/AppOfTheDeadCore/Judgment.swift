import Foundation

/// The qualities the Judgment weighs. Six are virtues somewhere among the dead's judges; `hubris` is the one every
/// tradition in the Judgment counts against a soul.
public enum Virtue: String, CaseIterable, Codable, Sendable {
    case truth
    case compassion
    case courage
    case loyalty
    case curiosity
    case detachment
    case hubris
}

/// How the player imagines their death. Norse and Aztec belief sent the dead by the manner of their death, not by
/// their deeds.
public enum DeathManner: String, CaseIterable, Codable, Sendable {
    case battle
    case water
    case oldAge
    case seeking
}

/// One answer of a scene: the virtues it weighs and, for the question of how the player will die, the manner it names.
public struct JudgmentAnswer: Equatable, Sendable {
    public let id: String
    public let weights: [Virtue: Int]
    public let manner: DeathManner?

    public init(id: String, weights: [Virtue: Int], manner: DeathManner? = nil) {
        self.id = id
        self.weights = weights
        self.manner = manner
    }
}

/// One scene of the Judgment, asked by a guardian of the dead from the tradition at `pathId`.
public struct JudgmentScene: Equatable, Sendable {
    public let id: String
    public let pathId: String
    public let answers: [JudgmentAnswer]

    public init(id: String, pathId: String, answers: [JudgmentAnswer]) {
        self.id = id
        self.pathId = pathId
        self.answers = answers
    }
}

/// The weighed soul: virtue totals and the manner of death. Codable so a verdict survives relaunches and iCloud.
public struct SoulRecord: Equatable, Codable, Sendable {
    public var scores: [Virtue: Int]
    public var manner: DeathManner

    public init(scores: [Virtue: Int] = [:], manner: DeathManner = .oldAge) {
        self.scores = scores
        self.manner = manner
    }

    public func score(_ virtue: Virtue) -> Int {
        scores[virtue, default: 0]
    }

    /// Adds an answer's weights, and takes its manner of death when it names one.
    public mutating func record(_ answer: JudgmentAnswer) {
        for (virtue, weight) in answer.weights {
            scores[virtue, default: 0] += weight
        }
        if let manner = answer.manner {
            self.manner = manner
        }
    }
}

/// The traditions the Judgment rules on, each tied to its learning path.
public enum JudgmentTradition: String, CaseIterable, Codable, Sendable {
    case egyptian
    case greek
    case norse
    case aztec
    case zoroastrian
    case buddhist

    public var pathId: String {
        switch self {
        case .egyptian: return "egyptian-afterlife"
        case .greek: return "greek-underworld"
        case .norse: return "norse"
        case .aztec: return "aztec-mictlan"
        case .zoroastrian: return "zoroastrianism"
        case .buddhist: return "buddhism"
        }
    }
}

/// Where a soul goes in one tradition. The raw values are stable ids for copy, symbols and storage.
public enum Realm: String, CaseIterable, Codable, Sendable {
    case solarBarque
    case fieldOfReeds
    case ammit
    case elysium
    case asphodel
    case tartarus
    case valhalla
    case folkvangr
    case ransHall
    case hel
    case nastrond
    case houseOfTheSun
    case tlalocan
    case mictlan
    case houseOfSong
    case hamistagan
    case houseOfLies
    case liberation
    case devaRealm
    case humanRealm
    case asuraRealm
    case hungryGhosts

    public var tradition: JudgmentTradition {
        switch self {
        case .solarBarque, .fieldOfReeds, .ammit: return .egyptian
        case .elysium, .asphodel, .tartarus: return .greek
        case .valhalla, .folkvangr, .ransHall, .hel, .nastrond: return .norse
        case .houseOfTheSun, .tlalocan, .mictlan: return .aztec
        case .houseOfSong, .hamistagan, .houseOfLies: return .zoroastrian
        case .liberation, .devaRealm, .humanRealm, .asuraRealm, .hungryGhosts: return .buddhist
        }
    }

    /// Whether the realm is a hard fate (a devoured heart, a pit, a corpse shore), which the verdict screen softens.
    public var isGrim: Bool {
        switch self {
        case .ammit, .tartarus, .nastrond, .houseOfLies, .hungryGhosts: return true
        default: return false
        }
    }
}

/// The soul's leading quality, with the Oracle deity who suits it.
public enum SoulArchetype: String, CaseIterable, Codable, Sendable {
    case featherLight
    case lanternBearer
    case chosenOfValkyries
    case oathkeeper
    case initiate
    case unbound
    case trickster

    public var virtue: Virtue {
        switch self {
        case .featherLight: return .truth
        case .lanternBearer: return .compassion
        case .chosenOfValkyries: return .courage
        case .oathkeeper: return .loyalty
        case .initiate: return .curiosity
        case .unbound: return .detachment
        case .trickster: return .hubris
        }
    }

    /// The `deity_prompts.json` id of the guide this soul is sent to.
    public var guideDeityId: String {
        switch self {
        case .featherLight: return "anubis"
        case .lanternBearer: return "azrael"
        case .chosenOfValkyries: return "odin"
        case .oathkeeper: return "ahura_mazda"
        case .initiate: return "hecate"
        case .unbound: return "yama"
        case .trickster: return "hermes"
        }
    }

    public static func archetype(for virtue: Virtue) -> SoulArchetype {
        allCases.first { $0.virtue == virtue } ?? .featherLight
    }
}

/// The Judgment's ruling: an archetype and one realm per tradition, in `JudgmentTradition` order.
public struct Verdict: Equatable, Codable, Sendable {
    public let archetype: SoulArchetype
    public let realms: [Realm]
    /// Whether a xolo carries this soul across the Apanohuaya in Mictlan.
    public let xoloCarries: Bool

    public init(archetype: SoulArchetype, realms: [Realm], xoloCarries: Bool) {
        self.archetype = archetype
        self.realms = realms
        self.xoloCarries = xoloCarries
    }

    public func realm(in tradition: JudgmentTradition) -> Realm? {
        realms.first { $0.tradition == tradition }
    }

    /// The tradition whose path the verdict sends the player to first: the one with the most striking realm.
    public var leadingTradition: JudgmentTradition {
        let striking: [Realm] = [.valhalla, .solarBarque, .elysium, .houseOfTheSun, .liberation, .tlalocan, .folkvangr, .ransHall, .houseOfSong]
        for realm in striking where realms.contains(realm) {
            return realm.tradition
        }
        return .egyptian
    }
}

/// Weighs a soul by the rules of six traditions. Pure: the same record always gets the same verdict.
public enum JudgmentEngine {

    public static func verdict(for soul: SoulRecord) -> Verdict {
        Verdict(
            archetype: archetype(for: soul),
            realms: JudgmentTradition.allCases.map { realm(in: $0, for: soul) },
            xoloCarries: soul.score(.compassion) >= 2 || soul.score(.loyalty) >= 3
        )
    }

    /// The highest-scoring virtue; ties go to the earlier virtue in `Virtue.allCases`, so the archetype is stable.
    public static func archetype(for soul: SoulRecord) -> SoulArchetype {
        let leading = Virtue.allCases.max { lhs, rhs in
            let left = soul.score(lhs), right = soul.score(rhs)
            if left != right { return left < right }
            return Virtue.allCases.firstIndex(of: lhs)! > Virtue.allCases.firstIndex(of: rhs)!
        } ?? .truth
        return .archetype(for: leading)
    }

    public static func realm(in tradition: JudgmentTradition, for soul: SoulRecord) -> Realm {
        switch tradition {
        case .egyptian: return egyptianRealm(for: soul)
        case .greek: return greekRealm(for: soul)
        case .norse: return norseRealm(for: soul)
        case .aztec: return aztecRealm(for: soul)
        case .zoroastrian: return zoroastrianRealm(for: soul)
        case .buddhist: return buddhistRealm(for: soul)
        }
    }

    /// The heart against the feather of Ma'at: truth and compassion lighten it, hubris weighs it down.
    static func egyptianRealm(for soul: SoulRecord) -> Realm {
        let lightness = soul.score(.truth) + soul.score(.compassion) - soul.score(.hubris)
        if lightness >= 7 && soul.score(.hubris) <= 0 { return .solarBarque }
        if lightness >= 1 { return .fieldOfReeds }
        return .ammit
    }

    /// Minos, Rhadamanthus and Aeacus: heroes and initiates of the Mysteries reach Elysium, the hubristic Tartarus,
    /// everyone else the Asphodel Meadows.
    static func greekRealm(for soul: SoulRecord) -> Realm {
        if soul.score(.hubris) >= 4 && soul.score(.truth) <= 1 { return .tartarus }
        if soul.score(.courage) >= 4 || soul.score(.curiosity) >= 5 { return .elysium }
        return .asphodel
    }

    /// The manner of death decides, except for oath-breakers.
    static func norseRealm(for soul: SoulRecord) -> Realm {
        if soul.score(.truth) <= -2 && soul.score(.loyalty) <= 0 { return .nastrond }
        switch soul.manner {
        case .battle:
            let odinsShare = soul.score(.courage) + soul.score(.hubris)
            let freyjasShare = soul.score(.compassion) + soul.score(.loyalty)
            return odinsShare >= freyjasShare ? .valhalla : .folkvangr
        case .water:
            return .ransHall
        case .oldAge, .seeking:
            return .hel
        }
    }

    /// Only the manner of death decides.
    static func aztecRealm(for soul: SoulRecord) -> Realm {
        switch soul.manner {
        case .battle: return .houseOfTheSun
        case .water: return .tlalocan
        case .oldAge, .seeking: return .mictlan
        }
    }

    /// Good thoughts, words and deeds on the Chinvat Bridge.
    static func zoroastrianRealm(for soul: SoulRecord) -> Realm {
        let balance = soul.score(.truth) + soul.score(.compassion) + soul.score(.loyalty) - soul.score(.hubris)
        if balance >= 4 { return .houseOfSong }
        if balance >= 0 { return .hamistagan }
        return .houseOfLies
    }

    /// Rebirth by karma, from the realm of hungry ghosts to the edge of liberation.
    static func buddhistRealm(for soul: SoulRecord) -> Realm {
        let detachment = soul.score(.detachment), compassion = soul.score(.compassion)
        if detachment >= 4 && compassion >= 2 && soul.score(.hubris) <= 0 { return .liberation }
        if soul.score(.hubris) >= 4 { return .asuraRealm }
        if detachment <= -2 { return .hungryGhosts }
        if compassion + soul.score(.truth) >= 5 { return .devaRealm }
        return .humanRealm
    }
}

/// The nine scenes, in order. Answer ids are stable: the copy and any saved progress refer to them.
public enum JudgmentScript {
    public static let scenes: [JudgmentScene] = [
        JudgmentScene(id: "thoth", pathId: "egyptian-afterlife", answers: [
            JudgmentAnswer(id: "promises", weights: [.loyalty: 2]),
            JudgmentAnswer(id: "truths", weights: [.truth: 2]),
            JudgmentAnswer(id: "strangers", weights: [.compassion: 2]),
            JudgmentAnswer(id: "places", weights: [.curiosity: 2]),
        ]),
        JudgmentScene(id: "charon", pathId: "greek-underworld", answers: [
            JudgmentAnswer(id: "pay", weights: [.truth: 1, .loyalty: 1]),
            JudgmentAnswer(id: "give", weights: [.compassion: 2, .detachment: 1]),
            JudgmentAnswer(id: "haggle", weights: [.hubris: 2]),
            JudgmentAnswer(id: "swim", weights: [.courage: 2, .hubris: 1]),
        ]),
        JudgmentScene(id: "rashnu", pathId: "zoroastrianism", answers: [
            JudgmentAnswer(id: "anyway", weights: [.truth: 3]),
            JudgmentAnswer(id: "gently", weights: [.truth: 1, .compassion: 2]),
            JudgmentAnswer(id: "silent", weights: [.detachment: 1, .truth: -1]),
            JudgmentAnswer(id: "bend", weights: [.truth: -2, .hubris: 1]),
        ]),
        JudgmentScene(id: "xolo", pathId: "aztec-mictlan", answers: [
            JudgmentAnswer(id: "love", weights: [.compassion: 2]),
            JudgmentAnswer(id: "loyal", weights: [.loyalty: 2]),
            JudgmentAnswer(id: "cat", weights: [.detachment: 1, .curiosity: 1]),
            JudgmentAnswer(id: "swim", weights: [.courage: 1, .hubris: 1]),
        ]),
        JudgmentScene(id: "assessors", pathId: "egyptian-afterlife", answers: [
            JudgmentAnswer(id: "lied", weights: [.truth: 2]),
            JudgmentAnswer(id: "weep", weights: [.compassion: 2]),
            JudgmentAnswer(id: "greedy", weights: [.detachment: 2]),
            JudgmentAnswer(id: "arrogant", weights: [.hubris: -2, .truth: 1]),
        ]),
        JudgmentScene(id: "odin", pathId: "norse", answers: [
            JudgmentAnswer(id: "fighting", weights: [.courage: 2], manner: .battle),
            JudgmentAnswer(id: "sea", weights: [.curiosity: 1, .courage: 1], manner: .water),
            JudgmentAnswer(id: "old", weights: [.loyalty: 1, .compassion: 1], manner: .oldAge),
            JudgmentAnswer(id: "secret", weights: [.curiosity: 2], manner: .seeking),
        ]),
        JudgmentScene(id: "yama", pathId: "buddhism", answers: [
            JudgmentAnswer(id: "people", weights: [.loyalty: 1, .compassion: 1, .detachment: -1]),
            JudgmentAnswer(id: "name", weights: [.hubris: 2, .detachment: -1]),
            JudgmentAnswer(id: "comfort", weights: [.detachment: -2]),
            JudgmentAnswer(id: "nothing", weights: [.detachment: 3]),
        ]),
        JudgmentScene(id: "hecate", pathId: "greek-underworld", answers: [
            JudgmentAnswer(id: "home", weights: [.loyalty: 1]),
            JudgmentAnswer(id: "dark", weights: [.courage: 1, .curiosity: 1]),
            JudgmentAnswer(id: "ask", weights: [.curiosity: 2]),
            JudgmentAnswer(id: "own", weights: [.hubris: 1, .courage: 1]),
        ]),
        JudgmentScene(id: "feather", pathId: "egyptian-afterlife", answers: [
            JudgmentAnswer(id: "best", weights: [.truth: 1]),
            JudgmentAnswer(id: "afraid", weights: [.courage: 1]),
            JudgmentAnswer(id: "kind", weights: [.compassion: 1]),
            JudgmentAnswer(id: "osiris", weights: [.hubris: 1]),
        ]),
    ]
}
