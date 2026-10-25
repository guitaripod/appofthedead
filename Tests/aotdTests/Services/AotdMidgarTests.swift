import MidgarCommerce
import Testing

@testable import aotd

struct AotdMidgarTests {
    @Test func theStoreBuysThroughMidgarCommerceInPurchasesMode() {
        #expect(AotdMidgar.storeConfiguration().mode == .purchases)
        #expect(AotdMidgar.storeConfiguration().appID == "app-of-the-dead")
    }

    @Test func theStoreKnowsEveryProductTheAppSells() {
        let sold = Set(ProductIdentifier.allCases.map(\.rawValue))
        #expect(Set(AotdMidgar.storeConfiguration().productIDs) == sold)
        #expect(sold.count == 28)
    }

    @Test func theThreeAllAccessProductsMapToTheUltimateEntitlement() {
        let map = AotdMidgar.storeConfiguration().entitlementsByProduct
        #expect(map["com.appofthedead.ultimate"] == "ultimate")
        #expect(map["com.appofthedead.premium.annual"] == "ultimate")
        #expect(map["com.appofthedead.premium.monthly"] == "ultimate")
        #expect(map.values.filter { $0 == "ultimate" }.count == 3)
    }

    @Test func everyProductMapsToAnEntitlement() {
        let map = AotdMidgar.storeConfiguration().entitlementsByProduct
        #expect(map.count == ProductIdentifier.allCases.count)
        #expect(map["com.appofthedead.oracle.wisdom"] == "oracle_unlimited")
    }

    @Test func noCrossAppEntitlementIsGrantedFromCode() {
        #expect(AotdMidgar.storeConfiguration().crossAppEntitlements.isEmpty)
    }

    @Test func aTestHostReachesNoMidgarService() {
        #expect(!AotdMidgar.reachesMidgarServices)
        #expect(AotdMidgar.shared.store == nil)
    }
}
