import XCTest
@testable import aotd

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private func items(_ state: SettingsState, in kind: SettingsSectionModel.Kind) -> [SettingsItem] {
        SettingsLayout.sections(for: state).first { $0.kind == kind }?.items ?? []
    }

    func testEverySectionAppearsInOrder() {
        let kinds = SettingsLayout.sections(for: SettingsState()).map(\.kind)

        XCTAssertEqual(kinds, [.membership, .journey, .oracle, .spread, .about, .account])
    }

    func testOnlyASubscriberIsOfferedManageSubscription() {
        XCTAssertEqual(items(SettingsState(), in: .membership), [.restorePurchases])

        var subscriber = SettingsState()
        subscriber.membership = .member
        subscriber.hasActiveSubscription = true

        XCTAssertEqual(items(subscriber, in: .membership), [.manageSubscription, .restorePurchases])
    }

    func testTheJourneyCarriesTheVerdictTheReminderAndGameCenter() {
        let time = Date(timeIntervalSince1970: 72_000)
        var state = SettingsState()
        state.soulName = "The Lantern-Bearer"
        state.reminderTime = time
        state.isGameCenterSignedIn = true

        XCTAssertEqual(items(state, in: .journey), [.soulCard(name: "The Lantern-Bearer"), .dailyReminder(time: time), .gameCenter(signedIn: true)])
    }

    func testALeftoverModelCanBeRemovedEvenWhenAppleIntelligenceAnswers() {
        var state = SettingsState()
        state.oracleVoice = .appleIntelligence
        state.modelBytesOnDisk = 3_581_000_000
        state.supportsHaptics = true

        XCTAssertEqual(items(state, in: .oracle), [.oracleVoice(.appleIntelligence), .removeModel(bytes: 3_581_000_000)])
    }

    func testStreamingHapticsShowOnlyForTheDownloadedModelOnAHapticIPhone() {
        var state = SettingsState()
        state.oracleVoice = .downloaded(modelName: "Gemma 4 (E2B)")
        state.modelBytesOnDisk = 10
        state.supportsHaptics = true

        XCTAssertEqual(items(state, in: .oracle).last, .streamingHaptics)

        state.supportsHaptics = false
        XCTAssertFalse(items(state, in: .oracle).contains(.streamingHaptics))
    }

    func testNothingOnDiskOffersNoRemoval() {
        XCTAssertEqual(items(SettingsState(), in: .oracle), [.oracleVoice(.notDownloaded)])
    }

    func testReloadReadsTheStateAndKeepsTheKnownSubscription() {
        var reads = 0
        let viewModel = SettingsViewModel(store: RestoreStub(result: .success(true))) {
            reads += 1
            var state = SettingsState()
            state.membership = .premiumWeek(daysLeft: 4)
            return state
        }
        var changes = 0
        viewModel.onChange = { changes += 1 }

        viewModel.reload()

        XCTAssertEqual(reads, 1)
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(viewModel.state.membership, .premiumWeek(daysLeft: 4))
    }

    func testARestoreThatFindsNothingSaysSo() async {
        let viewModel = SettingsViewModel(store: RestoreStub(result: .success(false))) { SettingsState() }

        do {
            try await viewModel.restorePurchases()
            XCTFail("A restore with nothing to restore must throw")
        } catch {
            XCTAssertEqual(error as? SettingsError, .nothingToRestore)
        }
    }

    func testARestoreThatFindsPurchasesSucceeds() async throws {
        let viewModel = SettingsViewModel(store: RestoreStub(result: .success(true))) { SettingsState() }

        try await viewModel.restorePurchases()
    }
}

@MainActor
private final class RestoreStub: PaywallProductProviding {
    let result: Result<Bool, Error>

    init(result: Result<Bool, Error>) {
        self.result = result
    }

    func fetchPremiumPlans(completion: @escaping (PremiumPlans) -> Void) {}
    func formattedPrice(for productId: ProductIdentifier) -> String? { nil }
    func fetchAndCachePrice(for productId: ProductIdentifier, completion: @escaping (String?) -> Void) { completion(nil) }
    func purchase(productId: ProductIdentifier, completion: @escaping (Result<PurchaseOutcome, Error>) -> Void) {}
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) { completion(result) }
}
