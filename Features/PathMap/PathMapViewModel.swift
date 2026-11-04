import Foundation
import MidgarCore
import AppOfTheDeadCore

/// One tradition's lessons as a path: done, the one to do next, and the ones still ahead, ending in the mastery crown.
final class PathMapViewModel {

    enum NodeState: Equatable {
        case completed
        case current
        case ahead
    }

    struct Node: Equatable {
        let index: Int
        let title: String
        let state: NodeState
        let xpReward: Int
    }

    enum CrownState: Equatable {
        /// Lessons remain before the mastery test.
        case sealed(lessonsLeft: Int)
        /// Every lesson is done; the test waits.
        case ready
        /// The path is mastered, with the best score.
        case mastered(score: Int?)
    }

    let beliefSystem: BeliefSystem
    private let progressProvider: () -> [Progress]
    private(set) var nodes: [Node] = []
    private(set) var crown: CrownState = .sealed(lessonsLeft: 0)

    init(beliefSystem: BeliefSystem, progressProvider: @escaping () -> [Progress]) {
        self.beliefSystem = beliefSystem
        self.progressProvider = progressProvider
        reload()
    }

    convenience init(beliefSystem: BeliefSystem, databaseManager: DatabaseManager = .shared) {
        self.init(beliefSystem: beliefSystem) {
            guard let user = databaseManager.fetchUser() else { return [] }
            return (try? databaseManager.getUserProgress(userId: user.id)) ?? []
        }
    }

    func reload() {
        let records = progressProvider().filter { $0.beliefSystemId == beliefSystem.id }
        let completedLessons = Set(records.filter { $0.status == .completed || $0.status == .mastered }.compactMap(\.lessonId))
        let pathRecord = records.first { $0.lessonId == nil }
        var currentAssigned = false
        nodes = beliefSystem.lessons.enumerated().map { index, lesson in
            let state: NodeState
            if completedLessons.contains(lesson.id) {
                state = .completed
            } else if !currentAssigned {
                state = .current
                currentAssigned = true
            } else {
                state = .ahead
            }
            return Node(index: index, title: lesson.title, state: state, xpReward: lesson.xpReward)
        }
        if pathRecord?.status == .mastered {
            crown = .mastered(score: pathRecord?.score)
        } else {
            let left = nodes.filter { $0.state != .completed }.count
            crown = left == 0 ? .ready : .sealed(lessonsLeft: left)
        }
    }

    var completedCount: Int {
        nodes.filter { $0.state == .completed }.count
    }

    var earnedXP: Int {
        nodes.filter { $0.state == .completed }.map(\.xpReward).reduce(0, +)
    }

    /// The node the map scrolls to and highlights: the next lesson, or the crown once every lesson is done.
    var focusIndex: Int? {
        nodes.first { $0.state == .current }?.index
    }

    /// Whether a node can be opened: done lessons replay, the current one starts, the ones ahead wait.
    func canOpen(_ node: Node) -> Bool {
        node.state != .ahead
    }

    var summary: String {
        String(localized: "\(completedCount) of \(nodes.count) lessons · \(earnedXP) XP")
    }
}
