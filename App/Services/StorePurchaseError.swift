import Foundation

/// Why a purchase or a restore did not complete, as a sentence the person can read. The store's own error goes to the
/// log; this is what the alert says.
enum StorePurchaseError: LocalizedError {
    case unavailable
    case purchaseFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .unavailable, .purchaseFailed:
            return String(localized: "The purchase could not be completed. Please try again.")
        case .restoreFailed:
            return String(localized: "Your purchases could not be restored. Please try again.")
        }
    }
}
