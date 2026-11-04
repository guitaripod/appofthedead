import Foundation
import MidgarCore

/// The first-run steps 2.0 is judged on: the Judgment finished, a Soul Card shared, the Premium Week opened, an Oracle
/// answer. Each is written to the app's log; none leaves the device.
enum AppFunnel {
    enum Step: String {
        case judgmentFinished = "judgment_finished"
        case soulCardShared = "soul_card_shared"
        case premiumWeekStarted = "premium_week_started"
        case oracleAnswered = "oracle_answered"
    }

    // TODO: send these as anonymous funnel.step counts once registry/signals.yaml lists the steps and the privacy policy says so.
    static func note(_ step: Step) {
        MidgarLog.info("Funnel step \(step.rawValue)", category: .general)
    }
}

/// Names of the Oracle's deities by id, from `deity_prompts.json`.
enum OracleDeityDirectory {
    static func name(for deityId: String) -> String? {
        ContentLoader().loadDeities()[deityId]?.name
    }
}
