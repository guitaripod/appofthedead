import Foundation
import Testing

@testable import aotd

struct AotdEntitlementsTests {
    private static func registryEntitlements() throws -> [String: String] {
        let text = try String(contentsOf: registryEntryURL, encoding: .utf8)
        var inTable = false
        var table: [String: String] = [:]
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            if line.hasPrefix("[") {
                inTable = line == "[commerce.entitlements]"
                continue
            }
            guard inTable, let match = line.firstMatch(of: /^"([^"]+)"\s*=\s*"([^"]+)"/) else { continue }
            table[String(match.1)] = String(match.2)
        }
        return table
    }

    private static func registryProducts() throws -> Set<String> {
        let text = try String(contentsOf: registryEntryURL, encoding: .utf8)
        let line = try #require(text.split(separator: "\n").first { $0.hasPrefix("products = [") })
        return Set(line.matches(of: /"([^"]+)"/).map { String($0.1) })
    }

    @Test func theAppTableEqualsTheRegistryTableExactly() throws {
        let registry = try Self.registryEntitlements()

        #expect(!registry.isEmpty)
        #expect(ProductIdentifier.entitlementsByProduct == registry)
    }

    @Test func theRegistryListsExactlyTheProductsTheAppSells() throws {
        #expect(try Self.registryProducts() == Set(ProductIdentifier.allCases.map(\.rawValue)))
    }

    @Test func theRegistryNamesEveryProductsEntitlementAndTheAppChecksTheSameNames() throws {
        let registry = try Self.registryEntitlements()

        #expect(Set(registry.keys) == (try Self.registryProducts()))
        #expect(registry["com.appofthedead.path.egyptian"] == "path_ancient_egyptian")
        #expect(registry["com.appofthedead.deities.eastern"] == "deity_eastern")
    }

    @Test func everyPathProductUnlocksItsOwnBeliefSystemAndNothingElse() {
        let paths = ProductIdentifier.allCases.filter { $0.beliefSystemId != nil }

        #expect(paths.count == 21)
        #expect(Set(paths.map(\.entitlement)).count == 21)
        for product in paths {
            let beliefSystemId = product.beliefSystemId ?? ""
            #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: beliefSystemId) == product.entitlement)
            #expect(product.entitlement.hasPrefix("path_"))
        }
    }

    @Test func theSpecialPathNamesKeepTheirEntitlementNames() {
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "greek-underworld") == "path_greek")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "egyptian-afterlife") == "path_ancient_egyptian")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "aztec-mictlan") == "path_aztec_mictlan")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "aboriginal-dreamtime") == "path_aboriginal_dreamtime")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "native-american-visions") == "path_native_american")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "swedenborgian-visions") == "path_swedenborgian")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "zoroastrianism") == "path_zoroastrian")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "norse") == "path_norse")
        #expect(ProductIdentifier.pathEntitlement(forBeliefSystem: "judaism") == nil)
    }

    @Test func theDeityPacksKeepTheirEntitlementNames() {
        #expect(ProductIdentifier.egyptianPantheon.entitlement == "deity_egyptian")
        #expect(ProductIdentifier.greekGuides.entitlement == "deity_greek")
        #expect(ProductIdentifier.easternWisdom.entitlement == "deity_eastern")
        #expect(ProductIdentifier.oracleWisdom.entitlement == "oracle_unlimited")
    }
}
