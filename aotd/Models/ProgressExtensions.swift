import Foundation

extension Progress {
    var currentXP: Int {
        // Calculate XP based on progress through the belief system
        // For now, we'll use the score or default to 0
        return score ?? 0
    }
}