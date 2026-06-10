import XCTest
@testable import aotd

final class PaywallViewModelTests: XCTestCase {

    private var store: StubStore!
    private var scheduler: StubReminderScheduler!

    override func setUp() {
        super.setUp()
        store = StubStore()
        scheduler = StubReminderScheduler()
    }

    override func tearDown() {
        store = nil
        scheduler = nil
        super.tearDown()
    }

    private func makeSut(reason: PaywallReason = .generalUpgrade) -> PaywallViewModel {
        PaywallViewModel(reason: reason, store: store, reminderScheduler: scheduler)
    }

    private static let fullPlans = PremiumPlans(
        annual: PremiumPlanInfo(
            productId: .premiumAnnual,
            localizedPrice: "$39.99",
            monthlyEquivalentPrice: "$3.33",
            trialDays: 7),
        monthly: PremiumPlanInfo(
            productId: .premiumMonthly,
            localizedPrice: "$9.99",
            monthlyEquivalentPrice: nil,
            trialDays: nil),
        lifetime: PremiumPlanInfo(
            productId: .ultimateEnlightenment,
            localizedPrice: "$89.99",
            monthlyEquivalentPrice: nil,
            trialDays: nil)
    )

    func testPlanCardsOrderedAnnualLifetimeMonthly() {
        store.plans = Self.fullPlans
        let sut = makeSut()

        sut.loadProducts()

        XCTAssertEqual(sut.planCards.map(\.plan), [.annual, .lifetime, .monthly])
    }

    func testAnnualCardCarriesTrialBadgeAndMonthlyEquivalent() {
        store.plans = Self.fullPlans
        let sut = makeSut()

        sut.loadProducts()

        let annual = sut.planCards.first { $0.plan == .annual }
        XCTAssertEqual(annual?.badge, .freeTrial(days: 7))
        XCTAssertEqual(annual?.billedPrice, "$39.99/year")
        XCTAssertEqual(annual?.detail, "≈ $3.33/month, billed yearly")
    }

    func testLifetimeCardShowsOneTimeFraming() {
        store.plans = Self.fullPlans
        let sut = makeSut()

        sut.loadProducts()

        let lifetime = sut.planCards.first { $0.plan == .lifetime }
        XCTAssertEqual(lifetime?.badge, .ownForever)
        XCTAssertEqual(lifetime?.billedPrice, "$89.99 once")
    }

    func testDefaultSelectionIsAnnualWithTrialCTA() {
        store.plans = Self.fullPlans
        let sut = makeSut()

        sut.loadProducts()

        XCTAssertEqual(sut.selectedPlan, .annual)
        XCTAssertEqual(sut.ctaTitle, "Start My 7-Day Free Trial")
        XCTAssertTrue(sut.showsNoPaymentDueNow)
    }

    func testTrialIneligibleAnnualShowsSubscribeCTA() {
        store.plans = PremiumPlans(
            annual: PremiumPlanInfo(productId: .premiumAnnual, localizedPrice: "$39.99", monthlyEquivalentPrice: nil, trialDays: nil),
            monthly: nil,
            lifetime: nil)
        let sut = makeSut()

        sut.loadProducts()

        XCTAssertEqual(sut.ctaTitle, "Subscribe")
        XCTAssertFalse(sut.showsNoPaymentDueNow)
        XCTAssertNil(sut.timelineSteps)
    }

    func testSelectingLifetimeUpdatesCTAAndHidesTrialUI() {
        store.plans = Self.fullPlans
        let sut = makeSut()
        sut.loadProducts()

        var selectionChanged = false
        sut.onSelectionChanged = { selectionChanged = true }
        sut.select(.lifetime)

        XCTAssertTrue(selectionChanged)
        XCTAssertEqual(sut.ctaTitle, "Unlock Lifetime")
        XCTAssertFalse(sut.showsNoPaymentDueNow)
        XCTAssertNil(sut.timelineSteps)
        XCTAssertTrue(sut.disclosureText.contains("One-time payment of $89.99"))
    }

    func testTimelineStepsForSevenDayTrial() {
        store.plans = Self.fullPlans
        let sut = makeSut()
        sut.loadProducts()

        let steps = sut.timelineSteps
        XCTAssertEqual(steps?.count, 3)
        XCTAssertEqual(steps?[0].title, "Today")
        XCTAssertEqual(steps?[1].title, "Day 5")
        XCTAssertEqual(steps?[2].title, "Day 7")
        XCTAssertTrue(steps?[2].detail.contains("$39.99/year") == true)
    }

    func testAnnualDisclosureStatesTrialPriceAndAutoRenewal() {
        store.plans = Self.fullPlans
        let sut = makeSut()
        sut.loadProducts()

        XCTAssertTrue(sut.disclosureText.contains("7 days free"))
        XCTAssertTrue(sut.disclosureText.contains("$39.99 per year"))
        XCTAssertTrue(sut.disclosureText.contains("Auto-renews"))
    }

    func testSelectionFallsBackToFirstAvailablePlanWhenAnnualMissing() {
        store.plans = PremiumPlans(
            annual: nil,
            monthly: nil,
            lifetime: PremiumPlanInfo(productId: .ultimateEnlightenment, localizedPrice: "$89.99", monthlyEquivalentPrice: nil, trialDays: nil))
        let sut = makeSut()

        sut.loadProducts()

        XCTAssertEqual(sut.selectedPlan, .lifetime)
        XCTAssertEqual(sut.ctaTitle, "Unlock Lifetime")
    }

    func testALaCarteProductForLockedPath() {
        let sut = makeSut(reason: .lockedPath(beliefSystemId: "norse"))

        XCTAssertEqual(sut.aLaCarteProduct, .norse)
    }

    func testALaCarteProductForOracleLimitMapsDeityPack() {
        let sut = makeSut(reason: .oracleLimit(deityId: "anubis", deityName: "Anubis"))

        XCTAssertEqual(sut.aLaCarteProduct, .egyptianPantheon)
    }

    func testNoALaCarteProductForGeneralUpgrade() {
        XCTAssertNil(makeSut(reason: .generalUpgrade).aLaCarteProduct)
    }

    func testPurchasingTrialAnnualSchedulesReminder() {
        store.plans = Self.fullPlans
        store.purchaseResult = .success(true)
        let sut = makeSut()
        sut.loadProducts()

        var states: [PaywallViewModel.PurchaseState] = []
        sut.onPurchaseStateChanged = { states.append($0) }
        sut.purchaseSelectedPlan()

        XCTAssertEqual(store.purchasedProducts, [.premiumAnnual])
        XCTAssertEqual(scheduler.scheduledTrialDays, [7])
        guard case .purchasing = states.first, case .success = states.last else {
            return XCTFail("Expected purchasing then success, got \(states)")
        }
    }

    func testPurchasingMonthlyDoesNotScheduleReminder() {
        store.plans = Self.fullPlans
        store.purchaseResult = .success(true)
        let sut = makeSut()
        sut.loadProducts()

        sut.select(.monthly)
        sut.purchaseSelectedPlan()

        XCTAssertEqual(store.purchasedProducts, [.premiumMonthly])
        XCTAssertTrue(scheduler.scheduledTrialDays.isEmpty)
    }

    func testFailedPurchaseReportsFailureAndSkipsReminder() {
        store.plans = Self.fullPlans
        store.purchaseResult = .failure(NSError(domain: "test", code: 1))
        let sut = makeSut()
        sut.loadProducts()

        var states: [PaywallViewModel.PurchaseState] = []
        sut.onPurchaseStateChanged = { states.append($0) }
        sut.purchaseSelectedPlan()

        guard case .failure = states.last else {
            return XCTFail("Expected failure state, got \(states)")
        }
        XCTAssertTrue(scheduler.scheduledTrialDays.isEmpty)
    }

    func testPurchaseALaCarteBuysContextProduct() {
        store.purchaseResult = .success(true)
        let sut = makeSut(reason: .lockedPath(beliefSystemId: "wicca"))

        sut.purchaseALaCarte()

        XCTAssertEqual(store.purchasedProducts, [.wicca])
        XCTAssertTrue(scheduler.scheduledTrialDays.isEmpty)
    }
}

private final class StubStore: PaywallProductProviding {

    var plans: PremiumPlans = .empty
    var purchaseResult: Result<Bool, Error> = .success(true)
    var prices: [ProductIdentifier: String] = [:]
    private(set) var purchasedProducts: [ProductIdentifier] = []

    func fetchPremiumPlans(completion: @escaping (PremiumPlans) -> Void) {
        completion(plans)
    }

    func formattedPrice(for productId: ProductIdentifier) -> String? {
        prices[productId]
    }

    func fetchAndCachePrice(for productId: ProductIdentifier, completion: @escaping (String?) -> Void) {
        completion(prices[productId])
    }

    func purchase(productId: ProductIdentifier, completion: @escaping (Result<Bool, Error>) -> Void) {
        purchasedProducts.append(productId)
        completion(purchaseResult)
    }

    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
}

private final class StubReminderScheduler: TrialReminderScheduling {

    private(set) var scheduledTrialDays: [Int] = []

    func scheduleTrialEndingReminder(trialDays: Int) {
        scheduledTrialDays.append(trialDays)
    }
}
