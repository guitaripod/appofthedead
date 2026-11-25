import XCTest
@testable import aotd

@MainActor final class OnDeviceModelCatalogTests: XCTestCase {

    func testPreferredModelOnHighMemoryDeviceIsGemma4E2B() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 8_000_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma4_e2b.id)
    }

    func testGemma4ConfigsStopAtGemma4EndOfTurn() {
        for model in [OnDeviceModelCatalog.gemma4_e2b, OnDeviceModelCatalog.gemma4_e4b] {
            let tokens = model.configuration.extraEOSTokens
            XCTAssertTrue(tokens.contains("<turn|>"), "\(model.id) must stop at Gemma 4's end-of-turn token")
            XCTAssertFalse(tokens.contains("<end_of_turn>"), "\(model.id) must not use Gemma 3's token, absent from Gemma 4's vocabulary")
        }
    }

    func testPreferredModelOnSixGBDeviceFallsBackToGemma3Text() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 6_000_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma3_text_4b.id)
    }

    func testFourGBDeviceGetsTheOneBModelInsteadOfTheFourBOne() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 3_760_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma3_1b.id)
    }

    func testPreferredModelOnTinyDeviceNeverCrashesAndPicksSafest() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 1_000_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma3_1b.id)
    }

    func testFallbackChainFromE2BDescendsThroughEverySmallerModel() {
        let chain = OnDeviceModelCatalog.fallbackChain(from: OnDeviceModelCatalog.gemma4_e2b)
        XCTAssertEqual(chain.map(\.id), [
            OnDeviceModelCatalog.gemma4_e2b.id,
            OnDeviceModelCatalog.gemma3_text_4b.id,
            OnDeviceModelCatalog.gemma3_1b.id
        ])
    }

    func testFallbackChainFromFourBDescendsToOneB() {
        let chain = OnDeviceModelCatalog.fallbackChain(from: OnDeviceModelCatalog.gemma3_text_4b)
        XCTAssertEqual(chain.map(\.id), [
            OnDeviceModelCatalog.gemma3_text_4b.id,
            OnDeviceModelCatalog.gemma3_1b.id
        ])
    }

    func testFallbackChainFromSafestModelIsTerminal() {
        let chain = OnDeviceModelCatalog.fallbackChain(from: OnDeviceModelCatalog.gemma3_1b)
        XCTAssertEqual(chain.map(\.id), [OnDeviceModelCatalog.gemma3_1b.id])
    }

    func testDeviceChainKeepsAModelThatFitsOnThisDevice() {
        let chain = OnDeviceModelCatalog.deviceChain(
            lastLoadedID: OnDeviceModelCatalog.gemma3_text_4b.id,
            physicalMemory: 6_000_000_000
        )
        XCTAssertEqual(chain.first?.id, OnDeviceModelCatalog.gemma3_text_4b.id)
    }

    func testDeviceChainDropsAModelTheDeviceCannotRun() {
        let chain = OnDeviceModelCatalog.deviceChain(
            lastLoadedID: OnDeviceModelCatalog.gemma3_text_4b.id,
            physicalMemory: 3_760_000_000
        )
        XCTAssertEqual(chain.map(\.id), [
            OnDeviceModelCatalog.gemma3_1b.id
        ])
    }

    func testDeviceChainStartsWithThePreferredModelWithNoHistory() {
        let chain = OnDeviceModelCatalog.deviceChain(lastLoadedID: nil, physicalMemory: 8_000_000_000)
        XCTAssertEqual(chain.first?.id, OnDeviceModelCatalog.gemma4_e2b.id)
    }

    func testEveryFloorSitsBelowTheStickerMemoryOfTheDeviceItTargets() {
        XCTAssertGreaterThan(OnDeviceModelCatalog.gemma3_text_4b.minimumPhysicalMemoryBytes, 3_760_000_000)
        XCTAssertLessThanOrEqual(OnDeviceModelCatalog.gemma3_text_4b.minimumPhysicalMemoryBytes, 5_726_158_848)
        XCTAssertLessThanOrEqual(OnDeviceModelCatalog.gemma4_e2b.minimumPhysicalMemoryBytes, 7_480_000_000)
    }

    func testRequiredMemoryLeavesRoomBeyondTheWeights() {
        let model = OnDeviceModelCatalog.gemma3_1b
        let required = MLXService.requiredMemoryBytes(for: model)
        XCTAssertGreaterThan(required, model.approximateDownloadBytes)
        XCTAssertLessThan(required, Int64(1_500_000_000), "the one-billion model must fit on a 3 GB iPhone")
    }

    func testEveryCatalogEntryUsesApacheLicensedGemmaWeights() {
        for model in OnDeviceModelCatalog.all {
            XCTAssertTrue(model.configuration.name.contains("gemma"),
                          "Catalog model \(model.id) is not a Gemma model")
        }
    }

    func testApproximateDownloadGBMatchesBytes() {
        XCTAssertEqual(OnDeviceModelCatalog.gemma4_e2b.approximateDownloadGB,
                       Double(OnDeviceModelCatalog.gemma4_e2b.approximateDownloadBytes) / 1_073_741_824,
                       accuracy: 0.0001)
    }
}
