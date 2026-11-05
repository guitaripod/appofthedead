import Foundation

/// A snapshot of everything the Settings screen depends on, so each combination of states is one value to test.
struct SettingsState: Equatable {
    enum Membership: Equatable {
        case free
        case premiumWeek(daysLeft: Int)
        case member
    }

    enum OracleVoiceState: Hashable {
        case appleIntelligence
        case downloaded(modelName: String)
        case notDownloaded
    }

    var membership: Membership = .free
    var hasActiveSubscription = false
    var soulName: String?
    var reminderTime: Date?
    var isGameCenterSignedIn = false
    var oracleVoice: OracleVoiceState = .notDownloaded
    var modelBytesOnDisk: Int64 = 0
    var supportsHaptics = false
}

/// One row of Settings, independent of how it is drawn.
enum SettingsItem: Hashable {
    case manageSubscription
    case restorePurchases
    case soulCard(name: String?)
    case dailyReminder(time: Date?)
    case gameCenter(signedIn: Bool)
    case oracleVoice(SettingsState.OracleVoiceState)
    case removeModel(bytes: Int64)
    case streamingHaptics
    case rate
    case share
    case support
    case usageCounts
    case licenses
    case privacyPolicy
    case termsOfUse
    case version
    case deleteMidgarID
}

struct SettingsSectionModel: Equatable {
    enum Kind: String {
        case membership
        case journey
        case oracle
        case spread
        case about
        case account
    }

    let kind: Kind
    let items: [SettingsItem]
}

/// Which rows Settings shows for a state, and in what order.
enum SettingsLayout {
    static func sections(for state: SettingsState) -> [SettingsSectionModel] {
        [
            SettingsSectionModel(kind: .membership, items: membershipItems(for: state)),
            SettingsSectionModel(kind: .journey, items: [
                .soulCard(name: state.soulName),
                .dailyReminder(time: state.reminderTime),
                .gameCenter(signedIn: state.isGameCenterSignedIn),
            ]),
            SettingsSectionModel(kind: .oracle, items: oracleItems(for: state)),
            SettingsSectionModel(kind: .spread, items: [.rate, .share, .support]),
            SettingsSectionModel(kind: .about, items: [.usageCounts, .licenses, .privacyPolicy, .termsOfUse, .version]),
            SettingsSectionModel(kind: .account, items: [.deleteMidgarID]),
        ]
    }

    /// A subscriber manages billing here; everyone can restore. The upsell itself lives in the card above the list.
    private static func membershipItems(for state: SettingsState) -> [SettingsItem] {
        state.hasActiveSubscription ? [.manageSubscription, .restorePurchases] : [.restorePurchases]
    }

    /// A downloaded model can be removed even when Apple Intelligence now answers, which frees the gigabytes an older
    /// install left behind. Streaming haptics only exist for the downloaded model.
    private static func oracleItems(for state: SettingsState) -> [SettingsItem] {
        var items: [SettingsItem] = [.oracleVoice(state.oracleVoice)]
        if state.modelBytesOnDisk > 0 {
            items.append(.removeModel(bytes: state.modelBytesOnDisk))
        }
        if state.supportsHaptics && state.oracleVoice != .appleIntelligence {
            items.append(.streamingHaptics)
        }
        return items
    }
}
