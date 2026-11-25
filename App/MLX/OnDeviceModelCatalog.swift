import Foundation
import MLXLLM
import MLXLMCommon

/// A declarative description of an on-device language model.
///
/// Adding support for a future model is a single entry here — no call-site changes.
/// `OnDeviceModelCatalog` selects the best entry a given device can run, and the
/// runtime falls back down the list automatically when a heavier model fails to
/// load or fails its post-load sanity probe.
nonisolated struct OnDeviceModel: Sendable, Equatable {
    let id: String
    let displayName: String
    let configuration: ModelConfiguration
    let approximateDownloadBytes: Int64
    /// Minimum *physical* device RAM required to attempt this model.
    let minimumPhysicalMemoryBytes: UInt64

    static func == (lhs: OnDeviceModel, rhs: OnDeviceModel) -> Bool { lhs.id == rhs.id }

    var approximateDownloadGB: Double {
        Double(approximateDownloadBytes) / 1_073_741_824
    }
}

nonisolated enum OnDeviceModelCatalog {

    static let gemma4_e4b = OnDeviceModel(
        id: "gemma-4-e4b-it-4bit",
        displayName: "Gemma 4 (E4B)",
        configuration: LLMRegistry.gemma4_e4b_it_4bit,
        approximateDownloadBytes: 5_217_000_000,
        minimumPhysicalMemoryBytes: 7_800_000_000
    )

    static let gemma4_e2b = OnDeviceModel(
        id: "gemma-4-e2b-it-4bit",
        displayName: "Gemma 4 (E2B)",
        configuration: LLMRegistry.gemma4_e2b_it_4bit,
        approximateDownloadBytes: 3_581_000_000,
        minimumPhysicalMemoryBytes: 7_000_000_000
    )

    /// Reported physical memory is the RAM the device ships with minus what the
    /// system reserves (an iPhone with 6 GB reports about 5.7 GB), so the floors
    /// are set below the sticker size of the smallest device that runs the model.
    static let gemma3_text_4b = OnDeviceModel(
        id: "gemma-3-text-4b-it-4bit",
        displayName: "Gemma 3 (4B)",
        configuration: ModelConfiguration(id: "mlx-community/gemma-3-text-4b-it-4bit"),
        approximateDownloadBytes: 2_560_000_000,
        minimumPhysicalMemoryBytes: 5_500_000_000
    )

    /// The floor of the catalog: the only model a 3–4 GB iPhone (XS, XR, SE,
    /// 11, 12, 13) can page in without the system killing the app mid-answer.
    static let gemma3_1b = OnDeviceModel(
        id: "gemma-3-1b-it-qat-4bit",
        displayName: "Gemma 3 (1B)",
        configuration: LLMRegistry.gemma3_1B_qat_4bit,
        approximateDownloadBytes: 800_000_000,
        minimumPhysicalMemoryBytes: 0
    )

    /// Ordered best → safest. The first entry whose `minimumPhysicalMemoryBytes`
    /// the device satisfies is the preferred model; everything after it is a
    /// fallback the runtime can descend to on failure.
    static let all: [OnDeviceModel] = [gemma4_e2b, gemma3_text_4b, gemma3_1b]

    static var physicalMemoryBytes: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }

    /// The preferred model for this device — the heaviest entry it can run.
    static func preferred(physicalMemory: UInt64 = physicalMemoryBytes) -> OnDeviceModel {
        all.first { physicalMemory >= $0.minimumPhysicalMemoryBytes } ?? gemma3_1b
    }

    /// The fallback chain starting at `model` and descending to safer models.
    static func fallbackChain(from model: OnDeviceModel) -> [OnDeviceModel] {
        guard let index = all.firstIndex(of: model) else { return [model, gemma3_1b] }
        return Array(all[index...])
    }

    /// The chain to try for this device: what it succeeded with last time when that
    /// model still fits, else the preferred one. A model left over from a heavier
    /// device is dropped rather than retried on every launch.
    static func deviceChain(
        lastLoadedID: String?,
        physicalMemory: UInt64 = physicalMemoryBytes
    ) -> [OnDeviceModel] {
        let chain = fallbackChain(from: preferred(physicalMemory: physicalMemory))
        guard let lastLoadedID,
              let last = model(withID: lastLoadedID),
              chain.contains(last) else {
            return chain
        }
        return fallbackChain(from: last)
    }

    static func model(withID id: String) -> OnDeviceModel? {
        ([gemma4_e4b] + all).first { $0.id == id }
    }

    /// The smallest download in the device's fallback chain — used to decide whether
    /// *any* model can fit before refusing the download outright.
    static func smallestInChain(physicalMemory: UInt64 = physicalMemoryBytes) -> OnDeviceModel {
        fallbackChain(from: preferred(physicalMemory: physicalMemory))
            .min { $0.approximateDownloadBytes < $1.approximateDownloadBytes } ?? gemma3_1b
    }
}
