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
        case .notStarted: return String(localized: "Not Started")
        case .inProgress: return String(localized: "In Progress")
        case .completed: return String(localized: "Completed")
        case .mastered: return String(localized: "Mastered")
        }
    }
}
