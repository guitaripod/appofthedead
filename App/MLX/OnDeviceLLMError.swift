import Foundation

/// Every failure mode the on-device LLM stack can surface, with user-facing copy
/// and a `isRecoverable` hint so the UI can decide between "retry" and "give up".
nonisolated enum OnDeviceLLMError: LocalizedError {
    case insufficientStorage(requiredBytes: Int64, availableBytes: Int64)
    case insufficientMemory(requiredBytes: Int64, availableBytes: Int64)
    case deviceNotSupported
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
            return String(localized: "Not enough space. The Oracle needs \(Self.gb(required)) free, but only \(Self.gb(available)) is available.")
        case let .insufficientMemory(required, available):
            return String(localized: "This device is low on memory for the Oracle. Close some apps and try again — the Oracle needs \(Self.gb(required)) free and \(Self.gb(available)) is available.")
        case .deviceNotSupported:
            return String(localized: "The Oracle needs Apple Intelligence or an iPhone 12 or later. This device cannot run its model, so downloading it would not help.")
        case .offline:
            return String(localized: "The Oracle's mind must be summoned over the network. Connect to Wi-Fi and try again.")
        case .downloadFailed:
            return String(localized: "The summoning was interrupted. Check your connection and try again — progress is kept.")
        case .loadFailed:
            return String(localized: "The Oracle could not awaken on this device.")
        case .sanityCheckFailed:
            return String(localized: "The Oracle awoke confused. Trying a more compatible mind…")
        case .allModelsExhausted:
            return String(localized: "No compatible Oracle could awaken on this device.")
        case .notReady:
            return String(localized: "The Oracle is not yet ready.")
        case .generationFailed:
            return String(localized: "The Oracle lost its voice mid-thought. Please try again.")
        case .cancelled:
            return String(localized: "Cancelled.")
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .insufficientStorage, .deviceNotSupported, .allModelsExhausted, .cancelled:
            return false
        case .offline, .downloadFailed, .insufficientMemory, .loadFailed, .sanityCheckFailed, .notReady, .generationFailed:
            return true
        }
    }

    private static func gb(_ bytes: Int64) -> String {
        String(format: "%.1f GB", locale: .current, Double(bytes) / 1_073_741_824)
    }
}
