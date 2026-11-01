import Foundation
import MidgarCommerce

/// When a finished lesson offers the paywall, through the shared ``MidgarOfferPolicy``: right after the first lesson,
/// then after every third one and at least three days apart, three times in all, and never once everything is unlocked.
enum LessonOffer {
    private static let legacyShownKey = "aotd.didShowFirstLessonPaywall"

    static let policy: MidgarOfferPolicy = {
        let policy = MidgarOfferPolicy(appID: AotdMidgar.appID, firstOfferAfter: 1, laterOfferEvery: 3)
        carryOverLegacyOffer(into: policy)
        return policy
    }()

    /// 1.4.13 and earlier showed one paywall after the first lesson and kept only a flag; a person who saw it counts as
    /// offered once, so they are not offered again on the first lesson of this version.
    private static func carryOverLegacyOffer(into policy: MidgarOfferPolicy, defaults: UserDefaults = .standard) {
        guard defaults.bool(forKey: legacyShownKey) else { return }
        if policy.offers == 0 {
            policy.noteOffered()
        }
        defaults.removeObject(forKey: legacyShownKey)
    }
}

/// The path a person picked on the welcome screen as the one they are most curious about. The offer after a lesson
/// names it.
enum CuriousPath {
    static let key = "aotd.curiousPathId"

    static var id: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
