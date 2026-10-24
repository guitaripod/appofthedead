import Foundation

enum GameCenterLeaderboard: String, CaseIterable {
    case totalXP
    case currentStreak
    case pathsMastered
    case pathsCompleted
    case correctAnswers

    var id: String {
        switch self {
        case .totalXP: return "com.marcusziade.aotd.leaderboard.total_xp"
        case .currentStreak: return "com.marcusziade.aotd.leaderboard.current_streak"
        case .pathsMastered: return "com.marcusziade.aotd.leaderboard.paths_mastered"
        case .pathsCompleted: return "com.marcusziade.aotd.leaderboard.paths_completed"
        case .correctAnswers: return "com.marcusziade.aotd.leaderboard.correct_answers"
        }
    }

    var title: String {
        switch self {
        case .totalXP: return "Total Enlightenment"
        case .currentStreak: return "Days of Devotion"
        case .pathsMastered: return "Realms Mastered"
        case .pathsCompleted: return "Gates Walked"
        case .correctAnswers: return "Sacred Knowledge"
        }
    }
}
