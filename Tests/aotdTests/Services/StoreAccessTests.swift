import Foundation
import Testing

@testable import aotd

@MainActor
struct StoreAccessTests {
    private func makeCache() throws -> EntitlementCache {
        EntitlementCache(defaults: try #require(UserDefaults(suiteName: "aotd.tests.\(UUID().uuidString)")))
    }

    private func firstLockedBeliefSystem(excluding owned: String? = nil) -> String? {
        ProductIdentifier.allCases.compactMap(\.beliefSystemId)
            .first { $0 != owned && !FreePaths.shared.isOpen($0) }
    }

    @Test func anEmptyCacheOpensNothingPaid() throws {
        let access = StoreAccess(store: nil, cache: try makeCache())

        #expect(access.entitlements.isEmpty)
        #expect(!access.hasAllAccess)
        #expect(!access.hasUnlimitedOracle)
        #expect(!access.hasDeityPack(for: "anubis"))
        if let locked = firstLockedBeliefSystem() {
            #expect(!access.hasPathAccess(locked))
        }
    }

    @Test func aLaunchWithNoNetworkOpensWhatTheStoreLastReported() throws {
        let cache = try makeCache()
        cache.record(["ultimate"])

        let access = StoreAccess(store: nil, cache: cache)

        #expect(access.hasAllAccess)
        #expect(access.hasUnlimitedOracle)
        for beliefSystemId in ProductIdentifier.allCases.compactMap(\.beliefSystemId) {
            #expect(access.hasPathAccess(beliefSystemId))
        }
    }

    @Test func aCachedPathOpensThatPathOnly() throws {
        let cache = try makeCache()
        cache.record(["path_ancient_egyptian"])

        let access = StoreAccess(store: nil, cache: cache)

        #expect(access.hasPathAccess("egyptian-afterlife"))
        #expect(!access.hasAllAccess)
        if let locked = firstLockedBeliefSystem(excluding: "egyptian-afterlife") {
            #expect(!access.hasPathAccess(locked))
        }
    }

    @Test func aCachedDeityPackOpensItsThreeDeitiesOnly() throws {
        let cache = try makeCache()
        cache.record(["deity_greek"])

        let access = StoreAccess(store: nil, cache: cache)

        for deity in ["hermes", "hecate", "pachamama"] {
            #expect(access.hasDeityPack(for: deity))
        }
        for deity in ["anubis", "kali", "baron_samedi", "yama", "meng_po", "izanami", "unknown"] {
            #expect(!access.hasDeityPack(for: deity))
        }
        #expect(!access.hasUnlimitedOracle)
    }

    @Test func theOracleWisdomEntitlementIsUnlimitedOracleWithoutAllAccess() throws {
        let cache = try makeCache()
        cache.record(["oracle_unlimited"])

        let access = StoreAccess(store: nil, cache: cache)

        #expect(access.hasUnlimitedOracle)
        #expect(!access.hasAllAccess)
    }

    @Test func theFreePathStaysOpenForEveryone() throws {
        let access = StoreAccess(store: nil, cache: try makeCache())

        #expect(access.hasPathAccess("judaism"))
    }

    @Test func theCacheKeepsNamesAcrossInstances() throws {
        let cache = try makeCache()

        cache.record(["ultimate", "path_norse"])

        #expect(cache.names == ["ultimate", "path_norse"])
        cache.record([])
        #expect(cache.names.isEmpty)
    }
}
