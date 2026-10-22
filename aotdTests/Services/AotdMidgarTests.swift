import MidgarCommerce
import Testing

@testable import aotd

struct AotdMidgarTests {
    @Test func theLedgerStoreOnlyReadsBecauseRevenueCatKeepsPurchasing() {
        #expect(AotdMidgar.storeConfiguration.mode == .readOnly)
        #expect(AotdMidgar.storeConfiguration.appID == "app-of-the-dead")
    }

    @Test func theStoreKnowsEveryProductTheAppSells() {
        let sold = Set(ProductIdentifier.allCases.map(\.rawValue))
        #expect(Set(AotdMidgar.storeConfiguration.productIDs) == sold)
    }

    @Test func theThreeAllAccessProductsMapToTheUltimateEntitlement() {
        let map = AotdMidgar.storeConfiguration.entitlementsByProduct
        #expect(map["com.appofthedead.ultimate"] == "ultimate")
        #expect(map["com.appofthedead.premium.annual"] == "ultimate")
        #expect(map["com.appofthedead.premium.monthly"] == "ultimate")
        #expect(map.count == 3)
    }

    @Test func noCrossAppEntitlementIsGrantedFromCode() {
        #expect(AotdMidgar.storeConfiguration.crossAppEntitlements.isEmpty)
    }

    @Test func aTestHostReachesNoMidgarService() {
        #expect(!AotdMidgar.reachesMidgarServices)
        #expect(AotdMidgar.shared.ledger == nil)
    }
}
