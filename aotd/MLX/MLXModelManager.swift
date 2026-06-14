import Foundation
import MLX

final class MLXModelManager {

    static let shared = MLXModelManager()

    private init() {
        if UserDefaults.standard.bool(forKey: "MLXModelLoadedOnce") {
            Task { try? await loadModelIfNeeded() }
        }
    }

    private let service = MLXService.shared

    private static let lastLoadedModelKey = "MLXLastLoadedModelID"

    /// The model this device will run: the one currently loaded, else the one that
    /// succeeded last time, else the heaviest catalog entry the device can handle.
    var activeModel: OnDeviceModel {
        if let loaded = service.loadedModel { return loaded }
        if let lastID = UserDefaults.standard.string(forKey: Self.lastLoadedModelKey),
           let last = OnDeviceModelCatalog.model(withID: lastID) {
            return last
        }
        return OnDeviceModelCatalog.preferred()
    }

    var isModelDownloaded: Bool {
        get async { await service.checkModelDownloaded(activeModel) }
    }

    var isModelLoaded: Bool { service.isModelLoaded }

    var supportsSystemPrompts: Bool { true }

    struct DownloadProgress {
        let bytesDownloaded: Int64
        let totalBytes: Int64
        let progress: Float

        init(bytesDownloaded: Int64, totalBytes: Int64, progress: Float? = nil) {
            self.bytesDownloaded = bytesDownloaded
            self.totalBytes = totalBytes
            if let progress {
                self.progress = progress
            } else {
                self.progress = totalBytes > 0 ? Float(bytesDownloaded) / Float(totalBytes) : 0
            }
        }
    }

    func loadModelIfNeeded() async throws {
        guard !isModelLoaded else { return }
        try await loadWithFallback { _ in }
    }

    func loadModel() async throws {
        try await loadWithFallback { _ in }
    }

    func downloadModel(onProgress: @escaping (DownloadProgress) -> Void) async throws {
        let preferred = activeModel
        try ensureSufficientStorage(for: OnDeviceModelCatalog.smallestInChain())

        try await loadWithFallback { progress in
            let total: Int64 = progress.totalUnitCount > 0
                ? progress.totalUnitCount
                : preferred.approximateDownloadBytes
            let fraction = Float(progress.fractionCompleted)
            let downloaded = progress.completedUnitCount > 0
                ? progress.completedUnitCount
                : Int64(Double(total) * progress.fractionCompleted)
            onProgress(DownloadProgress(bytesDownloaded: downloaded, totalBytes: total, progress: fraction))
        }
    }

    /// Tries the device's preferred model, descending the fallback chain on load or
    /// sanity-probe failure. Network/storage/cancellation errors stop immediately —
    /// burning through the chain on an offline error would be pointless.
    private func loadWithFallback(progressHandler: @escaping @Sendable (Foundation.Progress) -> Void) async throws {
        guard !isModelLoaded else { return }

        for model in resolvedChain() {
            do {
                try await service.loadModel(model, progressHandler: progressHandler)
                let actual = service.loadedModel ?? model
                service.markModelDownloaded(actual)
                UserDefaults.standard.set(actual.id, forKey: Self.lastLoadedModelKey)
                UserDefaults.standard.set(true, forKey: "MLXModelLoadedOnce")
                AppLogger.mlx.info("Loaded on-device model \(actual.id, privacy: .public)")
                return
            } catch let error as OnDeviceLLMError {
                switch error {
                case .loadFailed, .sanityCheckFailed:
                    AppLogger.mlx.error("Model \(model.id, privacy: .public) failed (\(error.localizedDescription, privacy: .public)); trying fallback")
                    continue
                default:
                    throw error
                }
            }
        }
        throw OnDeviceLLMError.allModelsExhausted
    }

    /// Prefer the model that actually succeeded last time, so a device that fell back
    /// to a smaller model doesn't re-attempt (and re-fail the sanity probe on) the
    /// heavier one on every launch.
    private func resolvedChain() -> [OnDeviceModel] {
        if let lastID = UserDefaults.standard.string(forKey: Self.lastLoadedModelKey),
           let last = OnDeviceModelCatalog.model(withID: lastID) {
            return OnDeviceModelCatalog.fallbackChain(from: last)
        }
        return OnDeviceModelCatalog.fallbackChain(from: OnDeviceModelCatalog.preferred())
    }

    func generate(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.7,
        useSystemPrompt: Bool = false,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard isModelLoaded else { throw OnDeviceLLMError.notReady }

        let config = MLXService.GenerationConfig(temperature: temperature, maxTokens: maxTokens)
        let stream = try await service.generate(
            systemPrompt: useSystemPrompt ? systemPrompt : nil,
            userPrompt: prompt,
            config: config
        )

        var generated = ""
        for try await chunk in stream {
            generated += chunk
            onToken(chunk)
        }
        return generated
    }

    func unloadModel() {
        service.unloadModel()
    }

    func handleMemoryPressure() {
        AppLogger.mlx.warning("Memory pressure — unloading on-device model")
        service.unloadModel()
    }

    func diskUsageBytes() -> Int64 { service.diskUsageBytes() }

    private func ensureSufficientStorage(for model: OnDeviceModel) throws {
        let required = Int64(Double(model.approximateDownloadBytes) * 1.2)
        let available = Self.availableDiskBytes()
        guard available == nil || available! >= required else {
            throw OnDeviceLLMError.insufficientStorage(requiredBytes: required, availableBytes: available!)
        }
    }

    private static func availableDiskBytes() -> Int64? {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let url,
              let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let capacity = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }
        return capacity
    }

    func checkMemoryStatus() -> (availableMemory: Int64, totalMemory: Int64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMemory = Int64(info.resident_size)
            let totalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
            return (totalMemory - usedMemory, totalMemory)
        }
        return (0, 0)
    }
}

enum MLXError: LocalizedError {
    case modelNotDownloaded
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotDownloaded: return "Model has not been downloaded yet"
        case .modelNotLoaded: return "Model has not been loaded into memory"
        }
    }
}
