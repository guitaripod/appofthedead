import Foundation

enum PaywallReason {
    case lockedPath(beliefSystemId: String)
    case oracleLimit(deityId: String, deityName: String)
    case generalUpgrade

    var title: String {
        switch self {
        case .lockedPath:
            return String(localized: "Unlock Your Journey")
        case .oracleLimit:
            return String(localized: "Continue the Conversation")
        case .generalUpgrade:
            return String(localized: "Unlock Everything")
        }
    }

    var subtitle: String {
        switch self {
        case .lockedPath:
            return String(localized: "Every path, every deity, every lesson — one membership")
        case .oracleLimit:
            return String(localized: "Unlimited wisdom from all 21 divine guides")
        case .generalUpgrade:
            return String(localized: "All 21 paths, unlimited Oracle, every future addition")
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

        if let product = aLaCarteProduct, store.formattedPrice(for: product) == nil {
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
            return String(localized: "Subscribe")
        case .monthly:
            return String(localized: "Subscribe")
        case .lifetime:
            return String(localized: "Unlock Lifetime")
        }
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

    var features: [(icon: String, title: String, description: String)] {
        switch reason {
        case .lockedPath:
            return [
                ("book.fill", String(localized: "All 21 Learning Paths"), String(localized: "Every lesson, quiz, and achievement")),
                ("bubble.left.and.bubble.right.fill", String(localized: "Unlimited Oracle"), String(localized: "Consult all 21 divine guides freely")),
                ("sparkles", String(localized: "Everything We Add Next"), String(localized: "New paths and features included"))
            ]
        case .oracleLimit:
            return [
                ("bubble.left.and.bubble.right.fill", String(localized: "Unlimited Consultations"), String(localized: "No limits with any deity")),
                ("book.fill", String(localized: "All 21 Learning Paths"), String(localized: "Every lesson and quiz included")),
                ("clock.fill", String(localized: "Conversation History"), String(localized: "Revisit past wisdom anytime"))
            ]
        case .generalUpgrade:
            return [
                ("book.fill", String(localized: "All 21 Learning Paths"), String(localized: "From Valhalla to the Duat")),
                ("bubble.left.and.bubble.right.fill", String(localized: "Unlimited Oracle"), String(localized: "All 21 divine guides, no limits")),
                ("star.fill", String(localized: "Every Achievement"), String(localized: "Nothing locked, ever"))
            ]
        }
    }

    var aLaCarteProduct: ProductIdentifier? {
        switch reason {
        case .lockedPath(let beliefSystemId):
            return ProductIdentifier.allCases.first { $0.beliefSystemId == beliefSystemId }
        case .oracleLimit(let deityId, _):
            return ProductIdentifier.deityPack(for: deityId)
        case .generalUpgrade:
            return nil
        }
    }

    var aLaCarteText: String? {
        guard let product = aLaCarteProduct else { return nil }
        let price = store.formattedPrice(for: product) ?? "…"
        switch reason {
        case .lockedPath:
            return String(localized: "Or unlock just this path for \(price)")
        case .oracleLimit:
            return String(localized: "Or get the \(product.displayName) for \(price)")
        case .generalUpgrade:
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

    func restore(completion: @escaping (Result<Bool, Error>) -> Void) {
        store.restorePurchases(completion: completion)
    }

    private func purchase(_ productId: ProductIdentifier, schedulingTrialReminder: Bool) {
        onPurchaseStateChanged?(.purchasing)
        let trialDays = annualTrialDays
        store.purchase(productId: productId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(true):
                if schedulingTrialReminder, let trialDays {
                    self.reminderScheduler.scheduleTrialEndingReminder(trialDays: trialDays)
                }
                self.onPurchaseStateChanged?(.success)
            case .success(false):
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
                badge: annual.trialDays.map { .freeTrial(days: $0) }))
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
        annual: PremiumPlanInfo(productId: .premiumAnnual, localizedPrice: "$39.99", monthlyEquivalentPrice: "$3.33", trialDays: 7),
        monthly: PremiumPlanInfo(productId: .premiumMonthly, localizedPrice: "$9.99", monthlyEquivalentPrice: nil, trialDays: nil),
        lifetime: PremiumPlanInfo(productId: .ultimateEnlightenment, localizedPrice: "$89.99", monthlyEquivalentPrice: nil, trialDays: nil)
    )
}
#endif

extension NotificationManager: TrialReminderScheduling {}
