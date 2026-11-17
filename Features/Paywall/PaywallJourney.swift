import AppOfTheDeadCore
import Foundation

/// What the paywall knows about the person it is shown to: counts the app already keeps on the device and the
/// Judgment's verdict. None of it leaves the device or reaches a signal.
nonisolated struct PaywallJourney: Equatable {
    var lessonsFinished = 0
    var oracleQuestions = 0
    var achievements = 0
    var verdict: Verdict?
    var guideName: String?

    /// Someone the app knows nothing about yet: every line keeps its general wording.
    static let unknown = PaywallJourney()
}

extension PaywallJourney {
    /// Reads the person's counts from the database and their verdict from the Judgment's record.
    @MainActor
    static func live(database: DatabaseManager = .shared, judgment: JudgmentStore = JudgmentStore()) -> PaywallJourney {
        var journey = judgment.verdict.map { PaywallJourney().ruled($0) } ?? PaywallJourney()
        guard let user = database.fetchUser() else { return journey }
        do {
            journey.lessonsFinished = finishedLessons(in: try database.getUserProgress(userId: user.id))
            journey.oracleQuestions = try database.getTotalOracleConsultations(userId: user.id)
            journey.achievements = try database.getUserStatistics(userId: user.id).totalAchievements
        } catch {
            Diagnostics.logError(error, context: "Reading the journey for the paywall", category: .purchases)
        }
        return journey
    }

    /// The journey of someone the Judgment gave this verdict, with the guide it sent them to.
    @MainActor
    func ruled(_ verdict: Verdict) -> PaywallJourney {
        var journey = self
        journey.verdict = verdict
        journey.guideName = OracleDeityDirectory.name(for: verdict.archetype.guideDeityId)
        return journey
    }

    /// Distinct lessons finished across every path; a lesson replayed or mastered counts once.
    static func finishedLessons(in progress: [Progress]) -> Int {
        let finished = progress
            .filter { $0.questionId == nil && ($0.status == .completed || $0.status == .mastered) }
            .compactMap { record in record.lessonId.map { "\(record.beliefSystemId)/\($0)" } }
        return Set(finished).count
    }
}

/// The paywall's lines told about the person where the app knows enough: the realm the Judgment sent their soul to,
/// the lessons they have finished, the questions they have asked the Oracle. A line without enough history keeps its
/// general wording, so every function here answers nil when it has nothing true to say.
enum PaywallPersonalCopy {
    /// Finished lessons before a line counts them.
    static let lessonsWorthCounting = 3
    /// Finished lessons before the end of the Premium Week names them as progress that stays.
    static let lessonsWorthKeeping = 2
    /// Questions asked before the Oracle limit counts them: one deity's whole free allowance.
    static let questionsWorthCounting = 3

    static func subtitle(for reason: PaywallReason, journey: PaywallJourney, showsOracle: Bool = true) -> String? {
        switch reason {
        case .lockedPath(let beliefSystemId):
            return fate(inPath: beliefSystemId, journey: journey).map {
                String(localized: "Your soul's fate in this tradition: \($0). This path tells the whole story.")
            }
        case .lessonFinished(let nextPath):
            return lessonSubtitle(nextPath: nextPath, journey: journey)
        case .oracleLimit:
            guard journey.oracleQuestions >= questionsWorthCounting else { return nil }
            return String(localized: "You have asked the Oracle \(journey.oracleQuestions) questions. Ask all 21 guides without limits.")
        case .generalUpgrade:
            return lessonCount(journey).map { "\($0)\n\(reason.subtitle(showsOracle: showsOracle))" }
        case .premiumWeekEnded:
            guard journey.lessonsFinished >= lessonsWorthKeeping else { return nil }
            return String(localized: "Your \(journey.lessonsFinished) finished lessons stay exactly where you left them. Keep every path and every god open.")
        }
    }

    /// The paths benefit, for someone the Judgment has ruled on.
    static func pathsDetail(_ journey: PaywallJourney) -> String? {
        guard journey.verdict != nil else { return nil }
        return String(localized: "Including the six afterlives that judged your soul")
    }

    /// The Oracle benefit, naming the guide the verdict sent the person to.
    static func oracleDetail(_ journey: PaywallJourney) -> String? {
        guard journey.verdict != nil, let guide = journey.guideName else { return nil }
        return String(localized: "\(guide), your guide from the Judgment, and 20 more")
    }

    /// The achievements benefit, once the person has earned one.
    static func achievementsDetail(_ journey: PaywallJourney) -> String? {
        guard journey.achievements >= 1 else { return nil }
        return String(localized: "\(journey.achievements) earned so far. Every path holds more.")
    }

    /// After a lesson: the lessons finished once there are a few, before that the realm the Judgment ruled for the
    /// path the offer names.
    private static func lessonSubtitle(nextPath: (id: String, name: String)?, journey: PaywallJourney) -> String? {
        if let count = lessonCount(journey) {
            let ahead = nextPath.map { String(localized: "\($0.name) and every other path are one step away.") }
                ?? String(localized: "All 21 paths are one step away.")
            return "\(count)\n\(ahead)"
        }
        guard let nextPath, let realm = fate(inPath: nextPath.id, journey: journey) else { return nil }
        return String(localized: "The Judgment's ruling on your soul: \(realm). \(nextPath.name) and every other path are one step away.")
    }

    private static func lessonCount(_ journey: PaywallJourney) -> String? {
        guard journey.lessonsFinished >= lessonsWorthCounting else { return nil }
        return String(localized: "\(journey.lessonsFinished) lessons finished so far.")
    }

    /// The name of the realm the verdict rules for the tradition a path teaches; nil for a path the Judgment does not
    /// rule on, or before the Judgment.
    private static func fate(inPath pathId: String, journey: PaywallJourney) -> String? {
        guard let verdict = journey.verdict,
              let tradition = JudgmentTradition.allCases.first(where: { $0.pathId == pathId }),
              let realm = verdict.realm(in: tradition) else { return nil }
        return JudgmentCopy.realmName(realm)
    }
}
