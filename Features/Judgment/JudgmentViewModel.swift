import Foundation
import MidgarCore
import AppOfTheDeadCore

/// The Judgment as a small state machine: an intro, nine scenes, the weighing, the verdict. Choosing an answer moves
/// forward; going back un-records the last answer. The verdict is saved and, the first time, opens the Premium Week.
@MainActor
final class JudgmentViewModel {

    enum Stage: Equatable {
        case intro
        case scene(Int)
        case weighing
        case verdict(Verdict)
    }

    enum Entry {
        /// The first run: the Judgment is the welcome.
        case firstRun
        /// Taken again from Home.
        case retake
        /// Opened on a saved verdict to look at or share it.
        case review(Verdict)
    }

    let scenes = JudgmentScript.scenes
    let entry: Entry
    var onStageChange: ((Stage) -> Void)?

    private(set) var stage: Stage {
        didSet { onStageChange?(stage) }
    }
    private(set) var picks: [Int] = []
    /// True when this verdict opened the Premium Week, so the screen announces it.
    private(set) var startedPremiumWeek = false

    private let store: JudgmentStore
    private let premiumWeek: PremiumWeekPass
    private let ownsAllAccess: () -> Bool

    init(
        entry: Entry,
        store: JudgmentStore = JudgmentStore(),
        premiumWeek: PremiumWeekPass = .shared,
        ownsAllAccess: @escaping () -> Bool = { StoreAccess.shared.hasAllAccess }
    ) {
        self.entry = entry
        self.store = store
        self.premiumWeek = premiumWeek
        self.ownsAllAccess = ownsAllAccess
        if case .review(let verdict) = entry {
            stage = .verdict(verdict)
        } else {
            stage = .intro
        }
    }

    var sceneCount: Int { scenes.count }

    func begin() {
        guard stage == .intro else { return }
        picks = []
        stage = .scene(0)
        Diagnostics.logUserAction("judgmentBegan", category: .learning)
    }

    func choose(answerAt index: Int) {
        guard case .scene(let current) = stage, scenes[current].answers.indices.contains(index) else { return }
        picks.append(index)
        if current + 1 < scenes.count {
            stage = .scene(current + 1)
        } else {
            stage = .weighing
        }
    }

    /// Steps back one scene, or to the intro from the first.
    func goBack() {
        guard case .scene(let current) = stage else { return }
        if current == 0 {
            stage = .intro
            return
        }
        picks.removeLast()
        stage = .scene(current - 1)
    }

    /// The soul as weighed by the answers so far.
    var soul: SoulRecord {
        var soul = SoulRecord()
        for (sceneIndex, pick) in picks.enumerated() {
            soul.record(scenes[sceneIndex].answers[pick])
        }
        return soul
    }

    /// Ends the weighing: saves the soul, rules on it and opens the Premium Week if it was never given.
    func finishWeighing() {
        guard stage == .weighing else { return }
        let soul = self.soul
        store.save(soul)
        let verdict = JudgmentEngine.verdict(for: soul)
        startedPremiumWeek = premiumWeek.start(ownsAllAccess: ownsAllAccess())
        Diagnostics.logUserAction("judgmentFinished", parameters: [
            "archetype": verdict.archetype.rawValue,
            "premiumWeek": startedPremiumWeek ? "started" : "not started"
        ], category: .learning)
        AppFunnel.note(.judgmentFinished)
        if startedPremiumWeek { AppFunnel.note(.premiumWeekStarted) }
        stage = .verdict(verdict)
    }

    var premiumWeekEnd: Date? {
        premiumWeek.endDate
    }

    /// The text that goes with a shared Soul Card.
    func shareMessage(for verdict: Verdict) -> String {
        String(localized: "Six afterlives just judged my soul. I'm \(JudgmentCopy.archetypeName(verdict.archetype)). Where will yours go?")
    }

    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6746733380")!
}
