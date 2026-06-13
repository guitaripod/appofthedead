import Foundation

struct PathJourneyItem {
    let id: String
    let name: String
    let iconName: String
    let colorHex: String
    let status: Progress.ProgressStatus
    let earnedXP: Int
    let totalXP: Int
    let totalAttempts: Int
    let completedAt: Date?

    var progressFraction: Float {
        guard totalXP > 0 else { return 0 }
        return min(1.0, Float(earnedXP) / Float(totalXP))
    }

    var statusLabel: String {
        switch status {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .mastered: return "Mastered"
        }
    }
}
