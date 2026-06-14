import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
import UIKit
import os.log

final class MLXService {

    static let shared = MLXService()

    private init() {}

    private static let logger = Logger(subsystem: "com.appofthedead", category: "MLXService")

    private static func debugLog(_ message: String) {
        #if targetEnvironment(simulator) || DEBUG
        logger.debug("\(message)")
        #endif
    }

    private struct HapticConfig {
        static let tokenInterval = 3
        static let impactIntensity: CGFloat = 0.4
        static let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
        static let userDefaultsKey = "StreamingHapticsEnabled"

        static var isStreamingHapticsEnabled: Bool {
            UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? true
        }
    }

    private var modelContainer: ModelContainer?
    private let modelCache = NSCache<NSString, ModelContainer>()
    private(set) var loadedModel: OnDeviceModel?
    private struct InFlightLoad { let modelID: String; let generation: Int; let task: Task<Void, Error> }
    private var inFlightLoad: InFlightLoad?
    private var loadGeneration = 0
    private var progressObservers: [@Sendable (Foundation.Progress) -> Void] = []
    private let loadStateLock = NSLock()

    static var defaultModel: OnDeviceModel { OnDeviceModelCatalog.preferred() }

    var isModelLoaded: Bool {
        if DeviceUtility.isSimulator {
            return loadedModel != nil
        }
        return modelContainer != nil
    }

    func loadModel(
        _ model: OnDeviceModel = defaultModel,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void = { _ in }
    ) async throws {
        if DeviceUtility.isSimulator {
            let progress = Foundation.Progress(totalUnitCount: 100)
            for i in 0...100 {
                progress.completedUnitCount = Int64(i)
                progressHandler(progress)
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            self.loadedModel = model
            return
        }

        try await sharedLoadTask(model: model, progressHandler: progressHandler).value
    }

    private func sharedLoadTask(
        model: OnDeviceModel,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void
    ) -> Task<Void, Error> {
        loadStateLock.lock()
        defer { loadStateLock.unlock() }

        if let inFlightLoad, inFlightLoad.modelID == model.id {
            progressObservers.append(progressHandler)
            return inFlightLoad.task
        }

        loadGeneration += 1
        let generation = loadGeneration
        progressObservers = [progressHandler]

        let task = Task {
            defer { self.clearInFlightLoadTask(generation: generation) }
            try await self.performLoad(model: model) { [weak self] progress in
                self?.notifyProgress(progress)
            }
        }
        inFlightLoad = InFlightLoad(modelID: model.id, generation: generation, task: task)
        return task
    }

    private func notifyProgress(_ progress: Foundation.Progress) {
        loadStateLock.lock()
        let observers = progressObservers
        loadStateLock.unlock()
        for observer in observers { observer(progress) }
    }

    private func clearInFlightLoadTask(generation: Int) {
        loadStateLock.lock()
        if inFlightLoad?.generation == generation {
            inFlightLoad = nil
            progressObservers = []
        }
        loadStateLock.unlock()
    }

    private func performLoad(
        model: OnDeviceModel,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void
    ) async throws {
        MLX.GPU.set(cacheLimit: 512 * 1024 * 1024)

        let cacheKey = model.id as NSString
        if let cached = modelCache.object(forKey: cacheKey) {
            self.modelContainer = cached
            self.loadedModel = model
            return
        }

        let container: ModelContainer
        do {
            container = try await LLMModelFactory.shared.loadContainer(
                from: #hubDownloader(),
                using: #huggingFaceTokenizerLoader(),
                configuration: model.configuration,
                progressHandler: progressHandler
            )
        } catch {
            throw OnDeviceLLMError.loadFailed(underlying: error)
        }

        self.modelContainer = container
        self.loadedModel = model

        do {
            try await runSanityProbe(on: container)
        } catch {
            self.modelContainer = nil
            self.loadedModel = nil
            throw OnDeviceLLMError.sanityCheckFailed(modelID: model.id)
        }

        modelCache.setObject(container, forKey: cacheKey)
    }

    /// Generates a handful of tokens and verifies the model emits coherent, printable
    /// text — catching quantization regressions (e.g. early Gemma 4 PLE-quant garbage)
    /// before the model is shown to the user.
    private func runSanityProbe(on container: ModelContainer) async throws {
        let session = ChatSession(
            container,
            instructions: "You are a helpful assistant.",
            generateParameters: GenerateParameters(maxTokens: 24, temperature: 0.0)
        )
        var output = ""
        for try await chunk in session.streamResponse(to: "Reply with exactly: OK") {
            output += chunk
            if output.count > 64 { break }
        }
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OnDeviceLLMError.sanityCheckFailed(modelID: loadedModel?.id ?? "unknown")
        }
        let printable = trimmed.unicodeScalars.filter { $0.value >= 32 || $0 == "\n" }.count
        let ratio = Double(printable) / Double(max(trimmed.unicodeScalars.count, 1))
        guard ratio > 0.8 else {
            throw OnDeviceLLMError.sanityCheckFailed(modelID: loadedModel?.id ?? "unknown")
        }
    }

    func unloadModel() {
        modelContainer = nil
        loadedModel = nil
        MLX.GPU.set(cacheLimit: 0)
        MLX.GPU.clearCache()
    }

    struct GenerationConfig {
        let temperature: Float
        let maxTokens: Int
        let topP: Float
        let repetitionPenalty: Float

        init(
            temperature: Float = 0.7,
            maxTokens: Int = 512,
            topP: Float = 0.95,
            repetitionPenalty: Float = 1.1
        ) {
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.topP = topP
            self.repetitionPenalty = repetitionPenalty
        }

        var parameters: GenerateParameters {
            GenerateParameters(
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                repetitionPenalty: repetitionPenalty
            )
        }
    }

    func generate(
        messages: [ChatMessage],
        config: GenerationConfig = GenerationConfig()
    ) async throws -> AsyncThrowingStream<String, Error> {
        let system = messages.first { $0.role == .system }?.content
        let user = messages.last { $0.role == .user }?.content ?? ""
        return try await generate(systemPrompt: system, userPrompt: user, config: config)
    }

    func generate(
        systemPrompt: String?,
        userPrompt: String,
        config: GenerationConfig = GenerationConfig()
    ) async throws -> AsyncThrowingStream<String, Error> {
        if DeviceUtility.isSimulator {
            return createSimulatorResponse(for: userPrompt)
        }

        guard let container = modelContainer else {
            throw OnDeviceLLMError.notReady
        }

        let session = ChatSession(
            container,
            instructions: systemPrompt,
            generateParameters: config.parameters
        )
        let upstream = session.streamResponse(to: userPrompt)

        return AsyncThrowingStream { continuation in
            let task = Task {
                let impactGenerator = await MainActor.run { () -> UIImpactFeedbackGenerator in
                    let g = UIImpactFeedbackGenerator(style: HapticConfig.impactStyle)
                    g.prepare()
                    return g
                }
                let notificationGenerator = await MainActor.run { () -> UINotificationFeedbackGenerator in
                    let g = UINotificationFeedbackGenerator()
                    g.prepare()
                    return g
                }

                do {
                    var tokenCount = 0
                    for try await chunk in upstream {
                        try Task.checkCancellation()
                        guard !chunk.isEmpty else { continue }
                        tokenCount += 1
                        if HapticConfig.isStreamingHapticsEnabled && tokenCount % HapticConfig.tokenInterval == 0 {
                            await MainActor.run { impactGenerator.impactOccurred(intensity: HapticConfig.impactIntensity) }
                        }
                        continuation.yield(chunk)
                    }
                    await MainActor.run { notificationGenerator.notificationOccurred(.success) }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: OnDeviceLLMError.generationFailed(underlying: error))
                }
            }

            continuation.onTermination = { @Sendable termination in
                if case .cancelled = termination { task.cancel() }
            }
        }
    }

    private func createSimulatorResponse(for prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let response = "[Simulator Mode] The Oracle speaks only on a physical device. Regarding '\(prompt)': the divine wisdom requires real hardware to channel."
                for word in response.split(separator: " ") {
                    try Task.checkCancellation()
                    continuation.yield(String(word) + " ")
                    try await Task.sleep(nanoseconds: 40_000_000)
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable termination in
                if case .cancelled = termination { task.cancel() }
            }
        }
    }

    func checkModelDownloaded(_ model: OnDeviceModel = defaultModel) async -> Bool {
        if DeviceUtility.isSimulator { return true }
        guard UserDefaults.standard.bool(forKey: Self.downloadedKey(model)) else { return false }
        if Self.modelFilesPresent(model) { return true }
        UserDefaults.standard.set(false, forKey: Self.downloadedKey(model))
        return false
    }

    /// iOS can purge `Library/Caches` (where the Hub stores weights) under disk
    /// pressure, so a stored "downloaded" flag is not enough — verify the weights
    /// are actually on disk and self-heal the flag if they were evicted.
    private static func modelFilesPresent(_ model: OnDeviceModel) -> Bool {
        let fm = FileManager.default
        guard let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return false }
        let dirName = "models--" + model.configuration.name.replacingOccurrences(of: "/", with: "--")
        let modelDir = caches
            .appendingPathComponent("huggingface", isDirectory: true)
            .appendingPathComponent("hub", isDirectory: true)
            .appendingPathComponent(dirName, isDirectory: true)
        guard let enumerator = fm.enumerator(at: modelDir, includingPropertiesForKeys: nil) else { return false }
        for case let url as URL in enumerator where url.pathExtension == "safetensors" {
            return true
        }
        return false
    }

    func markModelDownloaded(_ model: OnDeviceModel) {
        UserDefaults.standard.set(true, forKey: Self.downloadedKey(model))
    }

    static func downloadedKey(_ model: OnDeviceModel) -> String {
        "OnDeviceModelDownloaded-\(model.id)"
    }

    func diskUsageBytes() -> Int64 {
        let fm = FileManager.default
        guard let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return 0 }
        let hub = caches.appendingPathComponent("huggingface", isDirectory: true)
        return Self.directorySize(at: hub)
    }

    private static func directorySize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return total
    }
}

struct ChatMessage {
    enum Role {
        case system
        case user
        case assistant
    }

    let role: Role
    let content: String
}
