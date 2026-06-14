import Foundation

/// Every failure mode the on-device LLM stack can surface, with user-facing copy
/// and a `isRecoverable` hint so the UI can decide between "retry" and "give up".
enum OnDeviceLLMError: LocalizedError {
    case insufficientStorage(requiredBytes: Int64, availableBytes: Int64)
    case offline
    case downloadFailed(underlying: Error)
    case loadFailed(underlying: Error)
    case sanityCheckFailed(modelID: String)
    case allModelsExhausted
    case notReady
    case generationFailed(underlying: Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case let .insufficientStorage(required, available):
            return "Not enough space. The Oracle needs \(Self.gb(required)) free, but only \(Self.gb(available)) is available."
        case .offline:
            return "The Oracle's mind must be summoned over the network. Connect to Wi-Fi and try again."
        case .downloadFailed:
            return "The summoning was interrupted. Check your connection and try again — progress is kept."
        case .loadFailed:
            return "The Oracle could not awaken on this device."
        case .sanityCheckFailed:
            return "The Oracle awoke confused. Trying a more compatible mind…"
        case .allModelsExhausted:
            return "No compatible Oracle could awaken on this device."
        case .notReady:
            return "The Oracle is not yet ready."
        case .generationFailed:
            return "The Oracle lost its voice mid-thought. Please try again."
        case .cancelled:
            return "Cancelled."
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .insufficientStorage, .allModelsExhausted, .cancelled:
            return false
        case .offline, .downloadFailed, .loadFailed, .sanityCheckFailed, .notReady, .generationFailed:
            return true
        }
    }

    private static func gb(_ bytes: Int64) -> String {
        String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
    }
}
