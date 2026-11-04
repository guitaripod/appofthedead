import Foundation
import MidgarCore
import AppOfTheDeadCore

/// The day's question: one multiple-choice or true-or-false question from any tradition's lessons, locked or not, so
/// the whole map can be tasted a day at a time.
struct DailyOmen: Equatable {
    let dayKey: String
    let pathId: String
    let pathName: String
    let pathColor: String
    let questionId: String
    let question: String
    let options: [String]
    let correctAnswers: [String]
    let explanation: String

    func isCorrect(_ choice: String) -> Bool {
        correctAnswers.contains(choice)
    }
}

/// Picks the day's omen and remembers the answer. A right answer earns XP; any answer keeps the streak alive.
final class DailyOmenService {
    static let xpReward = 10
    private static let answerKeyPrefix = "aotd.omen.answer."

    private let beliefSystems: () -> [BeliefSystem]
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private let reward: @MainActor (Bool) -> Void

    init(
        beliefSystems: @escaping () -> [BeliefSystem] = { DatabaseManager.shared.loadBeliefSystems() },
        defaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init,
        reward: @escaping @MainActor (Bool) -> Void = { DailyOmenService.liveReward($0) }
    ) {
        self.beliefSystems = beliefSystems
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.reward = reward
    }

    func today() -> DailyOmen? {
        let date = now()
        let candidates = Self.candidates(from: beliefSystems())
        let day = DailyOmenSchedule.dayNumber(for: date, calendar: calendar)
        guard let index = DailyOmenSchedule.index(forDay: day, count: candidates.count) else { return nil }
        let (system, question) = candidates[index]
        let options: [String]
        switch question.type {
        case .trueFalse:
            options = ["true", "false"]
        case .multipleChoice:
            options = question.options ?? []
        case .matching:
            options = []
        }
        let correct: [String]
        switch question.correctAnswer.value {
        case .string(let value): correct = [value]
        case .array(let values): correct = values
        }
        return DailyOmen(
            dayKey: DailyOmenSchedule.dayKey(for: date, calendar: calendar),
            pathId: system.id,
            pathName: system.name,
            pathColor: system.color,
            questionId: question.id,
            question: question.question,
            options: options,
            correctAnswers: correct,
            explanation: question.explanation
        )
    }

    /// The answer given for `omen`, if it was answered today.
    func answer(for omen: DailyOmen) -> String? {
        defaults.string(forKey: Self.answerKeyPrefix + omen.dayKey)
    }

    /// Records `choice` once per day and returns whether it was right. A second answer on the same day changes nothing.
    @discardableResult
    func record(_ choice: String, for omen: DailyOmen) -> Bool {
        let correct = omen.isCorrect(choice)
        guard answer(for: omen) == nil else { return correct }
        defaults.set(choice, forKey: Self.answerKeyPrefix + omen.dayKey)
        reward(correct)
        Diagnostics.logUserAction("dailyOmenAnswered", parameters: ["pathId": omen.pathId, "correct": correct], category: .gamification)
        return correct
    }

    /// Every multiple-choice and true-or-false lesson question, in a fixed order.
    static func candidates(from systems: [BeliefSystem]) -> [(BeliefSystem, Question)] {
        systems.sorted { $0.id < $1.id }.flatMap { system in
            system.lessons.sorted { $0.order < $1.order }.flatMap { lesson in
                lesson.questions
                    .filter { $0.type == .trueFalse || ($0.type == .multipleChoice && ($0.options?.count ?? 0) >= 2) }
                    .map { (system, $0) }
            }
        }
    }

    static func liveReward(_ correct: Bool) {
        guard let user = DatabaseManager.shared.fetchUser() else { return }
        if correct {
            GamificationService.shared.awardXP(to: user.id, amount: xpReward, reason: "dailyOmen")
        } else {
            GamificationService.shared.updateStreakIfNeeded(for: user.id)
            NotificationCenter.default.post(name: Notification.Name("UserDataDidUpdate"), object: nil)
        }
    }
}
