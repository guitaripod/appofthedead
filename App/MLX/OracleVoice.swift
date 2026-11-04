import Foundation
import MidgarCore
import MidgarIntelligence

/// Who speaks for the Oracle. On an iPhone with Apple Intelligence it is Apple's on-device model: no download, private,
/// ready on the first tap. Elsewhere it is Gemma 4, downloaded once. Both run on the device; nothing leaves it.
final class OracleVoice {
    static let shared = OracleVoice()

    enum Engine: String {
        case apple
        case gemma
    }

    private let systemModel: MidgarOnDeviceModel
    private let gemma: MLXModelManager

    init(systemModel: MidgarOnDeviceModel = MidgarOnDeviceModel(), gemma: MLXModelManager = .shared) {
        self.systemModel = systemModel
        self.gemma = gemma
    }

    var engine: Engine {
        #if DEBUG
        if let forced = ProcessInfo.processInfo.environment["AOTD_ORACLE_ENGINE"].flatMap(Engine.init(rawValue:)) {
            return forced
        }
        #endif
        if case .available = systemModel.availability { return .apple }
        return .gemma
    }

    /// Names the model that answers, so cached answers from one model are never shown as another's.
    var modelId: String {
        switch engine {
        case .apple: return "apple-on-device"
        case .gemma: return gemma.activeModel.id
        }
    }

    /// True when a question can be answered right now, with no download or load first.
    var isReady: Bool {
        switch engine {
        case .apple: return true
        case .gemma: return gemma.isModelLoaded
        }
    }

    /// Streams the answer's text as it is written.
    func stream(instructions: String, prompt: String, temperature: Double, maxTokens: Int) -> AsyncThrowingStream<String, Error> {
        switch engine {
        case .apple:
            let request = MidgarPrompt(instructions: instructions, text: prompt, maxOutputTokens: maxTokens, temperature: temperature)
            return systemModel.streamResponse(to: request)
        case .gemma:
            return gemmaStream(instructions: instructions, prompt: prompt, temperature: temperature, maxTokens: maxTokens)
        }
    }

    private func gemmaStream(instructions: String, prompt: String, temperature: Double, maxTokens: Int) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.gemma.loadModelIfNeeded()
                    let config = MLXService.GenerationConfig(temperature: Float(temperature), maxTokens: maxTokens)
                    let upstream = try await MLXService.shared.generate(systemPrompt: instructions, userPrompt: prompt, config: config)
                    var filter = ThinkBlockFilter()
                    for try await chunk in upstream {
                        try Task.checkCancellation()
                        if let visible = filter.visibleText(after: chunk) {
                            continuation.yield(visible)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Drops a `<think>…</think>` block a model may stream before its answer, passing through only what follows it.
struct ThinkBlockFilter {
    private var buffer = ""
    private var emitted = 0

    mutating func visibleText(after chunk: String) -> String? {
        buffer += chunk
        let visible: String
        if let open = buffer.range(of: "<think>") {
            guard let close = buffer.range(of: "</think>", range: open.upperBound..<buffer.endIndex) else { return nil }
            visible = String(buffer[..<open.lowerBound]) + String(buffer[close.upperBound...]).trimmingLeadingWhitespace()
        } else {
            visible = buffer
        }
        guard visible.count > emitted else { return nil }
        let delta = String(visible.dropFirst(emitted))
        emitted = visible.count
        return delta
    }
}

private extension String {
    func trimmingLeadingWhitespace() -> String {
        String(drop(while: { $0.isWhitespace }))
    }
}
