import Foundation
import StoreKit
import MidgarCore
import AppOfTheDeadCore

/// Reads the live state Settings shows and runs the actions that need no screen: restoring purchases, removing the
/// downloaded Oracle model and deleting the Midgar ID.
@MainActor
final class SettingsViewModel {
    private(set) var state = SettingsState()
    var onChange: (() -> Void)?

    private let store: PaywallProductProviding
    private let readState: @MainActor () -> SettingsState

    init(store: PaywallProductProviding = StoreManager.shared, readState: (@MainActor () -> SettingsState)? = nil) {
        self.store = store
        self.readState = readState ?? Self.liveState
    }

    var sections: [SettingsSectionModel] {
        SettingsLayout.sections(for: state)
    }

    /// Reads everything again, then asks StoreKit in the background whether a subscription is current.
    func reload() {
        let subscribed = state.hasActiveSubscription
        state = readState()
        state.hasActiveSubscription = subscribed
        onChange?()
        Task { await refreshSubscription() }
    }

    /// Restores earlier purchases; an Apple Account with nothing to restore is reported as an error, so the person
    /// is told rather than shown a success.
    func restorePurchases() async throws {
        let restored = try await withCheckedThrowingContinuation { continuation in
            store.restorePurchases { continuation.resume(with: $0) }
        }
        reload()
        guard restored else { throw SettingsError.nothingToRestore }
    }

    func removeDownloadedModel() {
        MLXModelManager.shared.removeDownloadedModels()
        reload()
    }

    func deleteMidgarID() async throws {
        try await AotdMidgar.shared.identity.deleteIdentity()
        Diagnostics.logUserAction("deleteMidgarID", parameters: [:])
    }

    /// Whether a Premium subscription is current, from StoreKit's own entitlements, so Manage Subscription only shows
    /// to someone with a subscription to manage.
    private func refreshSubscription() async {
        var subscribed = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, Self.subscriptionIDs.contains(transaction.productID) {
                subscribed = true
            }
        }
        guard subscribed != state.hasActiveSubscription else { return }
        state.hasActiveSubscription = subscribed
        onChange?()
    }

    private static let subscriptionIDs: Set<String> = [
        ProductIdentifier.premiumAnnual.rawValue,
        ProductIdentifier.premiumMonthly.rawValue,
    ]

    private static func liveState() -> SettingsState {
        var state = SettingsState()
        state.membership = membership()
        state.soulName = JudgmentStore().verdict.map { JudgmentCopy.archetypeName($0.archetype) }
        state.reminderTime = DailyReminder.shared.isEnabled ? DailyReminder.shared.time : nil
        state.isGameCenterSignedIn = GameCenterManager.shared.isAuthenticated
        state.oracleVoice = oracleVoice()
        state.modelBytesOnDisk = BackgroundModelDownloader.diskUsageBytes()
        state.supportsHaptics = DeviceUtility.supportsTapticEngine
        return state
    }

    private static func membership() -> SettingsState.Membership {
        let access = StoreAccess.shared
        if access.hasAllAccess {
            return .member
        }
        if access.isPremiumWeekActive, let daysLeft = PremiumWeekPass.shared.daysLeft {
            return .premiumWeek(daysLeft: daysLeft)
        }
        return .free
    }

    private static func oracleVoice() -> SettingsState.OracleVoiceState {
        switch OracleVoice.shared.engine {
        case .apple:
            return .appleIntelligence
        case .gemma:
            let manager = MLXModelManager.shared
            return manager.isModelDownloadedSync ? .downloaded(modelName: manager.activeModel.displayName) : .notDownloaded
        }
    }
}

enum SettingsError: LocalizedError {
    case nothingToRestore

    var errorDescription: String? {
        switch self {
        case .nothingToRestore:
            return String(localized: "This Apple Account has no earlier purchases to restore.")
        }
    }
}
