import Foundation
import MidgarCore

enum PaywallReason {
    case lockedPath(beliefSystemId: String)
    case oracleLimit(deityId: String, deityName: String)
    case generalUpgrade
    /// Offered after a finished lesson, naming the path the person said they are most curious about, if any.
    case lessonFinished(nextPath: (id: String, name: String)?)
    /// Shown once when the Premium Week has ended.
    case premiumWeekEnded

    /// Where the paywall came from, as `paywall.view` reports it.
    var placement: MidgarSignal.Placement {
        switch self {
        case .lockedPath:
            return .feature
        case .oracleLimit:
            return .limit
        case .generalUpgrade:
            return .settings
        case .lessonFinished, .premiumWeekEnded:
            return .moment
        }
    }

    var title: String {
        switch self {
        case .lockedPath:
            return String(localized: "Unlock Your Journey")
        case .oracleLimit:
            return String(localized: "Continue the Conversation")
        case .generalUpgrade:
            return String(localized: "Unlock Everything")
        case .lessonFinished:
            return String(localized: "Keep the Journey Going")
        case .premiumWeekEnded:
            return String(localized: "Your Premium Week Has Ended")
        }
    }

    var subtitle: String {
        switch self {
        case .lockedPath:
            return String(localized: "Every path, every deity, every lesson — one membership")
        case .oracleLimit:
            return String(localized: "Unlimited wisdom from all 21 divine guides")
        case .generalUpgrade:
            return String(localized: "All 21 paths, unlimited Oracle and every path still to come")
        case .lessonFinished(let nextPath):
            if let nextPath {
                return String(localized: "You finished a lesson. \(nextPath.name) and every other path are one step away.")
            }
            return String(localized: "You finished a lesson. All 21 paths are one step away.")
        case .premiumWeekEnded:
            return String(localized: "Keep every path and every god open. Your progress stays exactly where you left it.")
        }
    }
}

protocol TrialReminderScheduling: AnyObject {
    func scheduleTrialEndingReminder(trialDays: Int)
}

final class PaywallViewModel {

    enum Plan: CaseIterable {
        case annual
        case monthly
        case lifetime

        var productId: ProductIdentifier {
            switch self {
            case .annual: return .premiumAnnual
            case .monthly: return .premiumMonthly
            case .lifetime: return .ultimateEnlightenment
            }
        }
    }

    enum Badge: Equatable {
        case freeTrial(days: Int)
        case savePercent(Int)
        case ownForever
    }

    struct PlanCard: Equatable {
        let plan: Plan
        let title: String
        let billedPrice: String
        let detail: String?
        let badge: Badge?
    }

    struct TimelineStep: Equatable {
        let icon: String
        let title: String
        let detail: String
    }

    enum PurchaseState {
        case idle
        case purchasing
        case success
        case pending
        case cancelled
        case failure(Error)
    }

    let reason: PaywallReason

    private let store: PaywallProductProviding
    private let reminderScheduler: TrialReminderScheduling
    private var plans: PremiumPlans = .empty

    private(set) var selectedPlan: Plan = .annual
    private(set) var planCards: [PlanCard] = []

    var onPlansUpdated: (() -> Void)?
    var onSelectionChanged: (() -> Void)?
    var onPurchaseStateChanged: ((PurchaseState) -> Void)?
    var onALaCartePriceUpdated: (() -> Void)?

    init(reason: PaywallReason,
         store: PaywallProductProviding = StoreManager.shared,
         reminderScheduler: TrialReminderScheduling = NotificationManager.shared) {
        self.reason = reason
        self.store = store
        self.reminderScheduler = reminderScheduler
    }

    func loadProducts() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["AOTD_DEMO_PLANS"] == "1" {
            plans = Self.demoPlans
            rebuildPlanCards()
            onPlansUpdated?()
            return
        }
        #endif
        store.fetchPremiumPlans { [weak self] plans in
            guard let self else { return }
            self.plans = plans
            self.rebuildPlanCards()
            self.onPlansUpdated?()
        }

        for product in [aLaCarteProduct, oracleWisdomProduct].compactMap({ $0 }) where store.formattedPrice(for: product) == nil {
            store.fetchAndCachePrice(for: product) { [weak self] _ in
                self?.onALaCartePriceUpdated?()
            }
        }
    }

    func select(_ plan: Plan) {
        guard plan != selectedPlan else { return }
        selectedPlan = plan
        onSelectionChanged?()
    }

    var annualTrialDays: Int? {
        plans.annual?.trialDays
    }

    var ctaTitle: String {
        switch selectedPlan {
        case .annual:
            if let days = annualTrialDays {
                return String(localized: "Start My \(days)-Day Free Trial")
            }
            return String(localized: "Unlock All 21 Paths")
        case .monthly:
            return String(localized: "Unlock All 21 Paths")
        case .lifetime:
            return String(localized: "Unlock Forever")
        }
    }

    /// How much the annual plan saves against twelve months of the monthly one, in whole percent; nil when it does
    /// not save or either price is missing.
    var annualSavingsPercent: Int? {
        guard let annual = plans.annual?.price, let monthly = plans.monthly?.price, monthly > 0 else { return nil }
        let year = (monthly as NSDecimalNumber).doubleValue * 12
        let percent = Int(((year - (annual as NSDecimalNumber).doubleValue) / year * 100).rounded(.down))
        return percent > 0 ? percent : nil
    }

    var showsNoPaymentDueNow: Bool {
        selectedPlan == .annual && annualTrialDays != nil
    }

    var disclosureText: String {
        switch selectedPlan {
        case .annual:
            guard let annual = plans.annual else { return "" }
            if let days = annual.trialDays {
                return String(localized: "\(days) days free, then \(annual.localizedPrice) per year. Auto-renews until cancelled in Settings at least a day before each renewal.")
            }
            return String(localized: "\(annual.localizedPrice) per year. Auto-renews until cancelled in Settings at least a day before each renewal.")
        case .monthly:
            guard let monthly = plans.monthly else { return "" }
            return String(localized: "\(monthly.localizedPrice) per month. Auto-renews until cancelled in Settings at least a day before each renewal.")
        case .lifetime:
            guard let lifetime = plans.lifetime else { return "" }
            return String(localized: "One-time payment of \(lifetime.localizedPrice). Yours forever, no subscription.")
        }
    }

    var timelineSteps: [TimelineStep]? {
        guard selectedPlan == .annual,
              let annual = plans.annual,
              let days = annual.trialDays else { return nil }
        let reminderDay = max(1, days - 2)
        return [
            TimelineStep(
                icon: "lock.open.fill",
                title: String(localized: "Today"),
                detail: String(localized: "Unlock all 21 paths and unlimited Oracle instantly")),
            TimelineStep(
                icon: "bell.fill",
                title: String(localized: "Day \(reminderDay)"),
                detail: String(localized: "We remind you before your trial ends")),
            TimelineStep(
                icon: "creditcard.fill",
                title: String(localized: "Day \(days)"),
                detail: String(localized: "Annual plan starts at \(annual.localizedPrice)/year. Cancel anytime before."))
        ]
    }

    /// What the person can count on when they pay without a trial: shown in the trial timeline's place.
    var assuranceSteps: [TimelineStep] {
        let keeping = selectedPlan == .lifetime
            ? TimelineStep(
                icon: "infinity",
                title: String(localized: "Yours for good"),
                detail: String(localized: "One payment, never renews"))
            : TimelineStep(
                icon: "arrow.uturn.backward.circle.fill",
                title: String(localized: "Cancel anytime"),
                detail: String(localized: "Turn off renewal in Settings whenever you like"))
        return [
            TimelineStep(
                icon: "lock.open.fill",
                title: String(localized: "Unlocks right away"),
                detail: String(localized: "All 21 paths and the Oracle open the moment you pay")),
            keeping,
            TimelineStep(
                icon: "arrow.triangle.2.circlepath",
                title: String(localized: "On all your devices"),
                detail: String(localized: "Restore with your Apple Account on any iPhone or iPad"))
        ]
    }

    var features: [(icon: String, title: String, description: String)] {
        switch reason {
        case .lockedPath, .lessonFinished:
            return [
                ("book.fill", String(localized: "All 21 Learning Paths"), String(localized: "Every lesson, quiz, and achievement")),
                ("bubble.left.and.bubble.right.fill", String(localized: "Unlimited Oracle"), String(localized: "Consult all 21 divine guides freely")),
                ("sparkles", String(localized: "Everything We Add Next"), String(localized: "New paths included as they arrive"))
            ]
        case .oracleLimit:
            return [
                ("bubble.left.and.bubble.right.fill", String(localized: "Unlimited Consultations"), String(localized: "No limits with any deity")),
                ("book.fill", String(localized: "All 21 Learning Paths"), String(localized: "Every lesson and quiz included")),
                ("sparkles", String(localized: "Everything We Add Next"), String(localized: "New paths included as they arrive"))
            ]
        case .generalUpgrade, .premiumWeekEnded:
            return [
                ("book.fill", String(localized: "All 21 Learning Paths"), String(localized: "From Valhalla to the Duat")),
                ("bubble.left.and.bubble.right.fill", String(localized: "Unlimited Oracle"), String(localized: "All 21 divine guides, no limits")),
                ("star.fill", String(localized: "Every Achievement"), String(localized: "Every path's achievements within reach"))
            ]
        }
    }

    var aLaCarteProduct: ProductIdentifier? {
        switch reason {
        case .lockedPath(let beliefSystemId):
            return ProductIdentifier.allCases.first { $0.beliefSystemId == beliefSystemId }
        case .lessonFinished(let nextPath):
            guard let id = nextPath?.id else { return nil }
            return ProductIdentifier.allCases.first { $0.beliefSystemId == id }
        case .oracleLimit(let deityId, _):
            return ProductIdentifier.deityPack(for: deityId)
        case .generalUpgrade, .premiumWeekEnded:
            return nil
        }
    }

    var aLaCarteText: String? {
        guard let product = aLaCarteProduct else { return nil }
        let price = store.formattedPrice(for: product) ?? "…"
        switch reason {
        case .lockedPath:
            return String(localized: "Or unlock just this path for \(price)")
        case .lessonFinished(let nextPath):
            guard let nextPath else { return nil }
            return String(localized: "Or unlock just \(nextPath.name) for \(price)")
        case .oracleLimit:
            return String(localized: "Or get the \(product.displayName) for \(price)")
        case .generalUpgrade, .premiumWeekEnded:
            return nil
        }
    }

    func purchaseSelectedPlan() {
        purchase(selectedPlan.productId, schedulingTrialReminder: showsNoPaymentDueNow)
    }

    func purchaseALaCarte() {
        guard let product = aLaCarteProduct else { return }
        purchase(product, schedulingTrialReminder: false)
    }

    /// The Oracle Wisdom pack, offered beside the deity's own pack when that deity's free consultations run out: every
    /// god without limits, bought once, for someone who wants the Oracle and not the paths.
    var oracleWisdomProduct: ProductIdentifier? {
        guard case .oracleLimit = reason else { return nil }
        return .oracleWisdom
    }

    var oracleWisdomText: String? {
        guard let product = oracleWisdomProduct else { return nil }
        let price = store.formattedPrice(for: product) ?? "…"
        return String(localized: "Or unlimited Oracle with all 21 gods for \(price)")
    }

    func purchaseOracleWisdom() {
        guard let product = oracleWisdomProduct else { return }
        purchase(product, schedulingTrialReminder: false)
    }

    func restore(completion: @escaping (Result<Bool, Error>) -> Void) {
        store.restorePurchases(completion: completion)
    }

    private func purchase(_ productId: ProductIdentifier, schedulingTrialReminder: Bool) {
        onPurchaseStateChanged?(.purchasing)
        let trialDays = annualTrialDays
        store.purchase(productId: productId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(.purchased):
                if schedulingTrialReminder, let trialDays {
                    self.reminderScheduler.scheduleTrialEndingReminder(trialDays: trialDays)
                }
                self.onPurchaseStateChanged?(.success)
            case .success(.pending):
                self.onPurchaseStateChanged?(.pending)
            case .success(.cancelled):
                self.onPurchaseStateChanged?(.cancelled)
            case .failure(let error):
                self.onPurchaseStateChanged?(.failure(error))
            }
        }
    }

    private func rebuildPlanCards() {
        var cards: [PlanCard] = []

        if let annual = plans.annual {
            let detail = annual.monthlyEquivalentPrice.map { String(localized: "≈ \($0)/month, billed yearly") }
            cards.append(PlanCard(
                plan: .annual,
                title: String(localized: "Annual"),
                billedPrice: String(localized: "\(annual.localizedPrice)/year"),
                detail: detail,
                badge: annual.trialDays.map { .freeTrial(days: $0) } ?? annualSavingsPercent.map { .savePercent($0) }))
        }

        if let lifetime = plans.lifetime {
            cards.append(PlanCard(
                plan: .lifetime,
                title: String(localized: "Lifetime"),
                billedPrice: String(localized: "\(lifetime.localizedPrice) once"),
                detail: String(localized: "Pay once, keep everything forever"),
                badge: .ownForever))
        }

        if let monthly = plans.monthly {
            cards.append(PlanCard(
                plan: .monthly,
                title: String(localized: "Monthly"),
                billedPrice: String(localized: "\(monthly.localizedPrice)/month"),
                detail: nil,
                badge: nil))
        }

        planCards = cards

        if !cards.contains(where: { $0.plan == selectedPlan }), let fallback = cards.first?.plan {
            selectedPlan = fallback
        }
    }
}

#if DEBUG
extension PaywallViewModel {
    /// Mirrors the live ASC configuration so screenshot runs render the full
    /// paywall without StoreKit (AOTD_DEMO_PLANS=1).
    static let demoPlans = PremiumPlans(
        annual: PremiumPlanInfo(productId: .premiumAnnual, localizedPrice: "$19.99", price: 19.99, monthlyEquivalentPrice: "$1.67", trialDays: nil),
        monthly: PremiumPlanInfo(productId: .premiumMonthly, localizedPrice: "$2.99", price: 2.99, monthlyEquivalentPrice: nil, trialDays: nil),
        lifetime: PremiumPlanInfo(productId: .ultimateEnlightenment, localizedPrice: "$89.99", price: 89.99, monthlyEquivalentPrice: nil, trialDays: nil)
    )
}
#endif

extension NotificationManager: TrialReminderScheduling {}
