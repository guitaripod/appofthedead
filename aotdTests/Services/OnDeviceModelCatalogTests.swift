import XCTest
@testable import aotd

final class OnDeviceModelCatalogTests: XCTestCase {

    func testPreferredModelOnHighMemoryDeviceIsGemma4E2B() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 8_000_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma4_e2b.id)
    }

    func testGemma4ConfigsUseCorrectEndOfTurnStopToken() {
        for model in [OnDeviceModelCatalog.gemma4_e2b, OnDeviceModelCatalog.gemma4_e4b] {
            let tokens = model.configuration.extraEOSTokens
            XCTAssertTrue(tokens.contains("<end_of_turn>"), "\(model.id) must stop at end-of-turn")
            XCTAssertFalse(tokens.contains("<turn|>"), "\(model.id) must not carry the SDK typo stop token")
        }
    }

    func testPreferredModelOnSixGBDeviceFallsBackToGemma3Text() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 6_000_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma3_text_4b.id)
    }

    func testPreferredModelOnTinyDeviceNeverCrashesAndPicksSafest() {
        let model = OnDeviceModelCatalog.preferred(physicalMemory: 1_000_000_000)
        XCTAssertEqual(model.id, OnDeviceModelCatalog.gemma3_text_4b.id)
    }

    func testFallbackChainFromE2BDescendsToGemma3Text() {
        let chain = OnDeviceModelCatalog.fallbackChain(from: OnDeviceModelCatalog.gemma4_e2b)
        XCTAssertEqual(chain.map(\.id), [
            OnDeviceModelCatalog.gemma4_e2b.id,
            OnDeviceModelCatalog.gemma3_text_4b.id
        ])
    }

    func testFallbackChainFromSafestModelIsTerminal() {
        let chain = OnDeviceModelCatalog.fallbackChain(from: OnDeviceModelCatalog.gemma3_text_4b)
        XCTAssertEqual(chain.map(\.id), [OnDeviceModelCatalog.gemma3_text_4b.id])
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
