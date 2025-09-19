import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Hub
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
            
            return UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? true
        }
    }
    
    
    
    private var modelContainer: ModelContainer?
    private let modelCache = NSCache<NSString, ModelContainer>()
    private var currentModel: ModelConfiguration?
    
    
    static let availableModels: [(name: String, config: ModelConfiguration)] = [
        ("SmolLM-135M", LLMRegistry.smolLM_135M_4bit),
        ("Qwen3-0.6B", LLMRegistry.qwen3_0_6b_4bit),
        ("Qwen3-1.7B", LLMRegistry.qwen3_1_7b_4bit),
        ("Llama3.2-1B", LLMRegistry.llama3_2_1B_4bit),
        ("Llama3.2-3B", LLMRegistry.llama3_2_3B_4bit),
        ("Qwen2.5-7B", LLMRegistry.qwen2_5_7b),
        ("Mistral-Nemo", LLMRegistry.mistralNeMo4bit),
        ("Gemma2-9B", LLMRegistry.gemma_2_9b_it_4bit)
    ]
    
    
    
    static let defaultModel = LLMRegistry.llama3_2_3B_4bit
    
    var isModelLoaded: Bool {
        if DeviceUtility.isSimulator {
            return currentModel != nil
        }
        return modelContainer != nil
    }
    
    
    
    func loadModel(
        configuration: ModelConfiguration = defaultModel,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void
    ) async throws {
        
        if DeviceUtility.isSimulator {
            Self.debugLog("MLX: Running in simulator - using mock mode")
            
            let progress = Foundation.Progress(totalUnitCount: 100)
            for i in 0...100 {
                progress.completedUnitCount = Int64(i)
                progressHandler(progress)
                try await Task.sleep(nanoseconds: 10_000_000) 
            }
            
            self.currentModel = configuration
            return
        }
        
        
        MLX.GPU.set(cacheLimit: 512 * 1024 * 1024) 
        
        
        let cacheKey = configuration.name as NSString
        if let cached = modelCache.object(forKey: cacheKey) {
            self.modelContainer = cached
            self.currentModel = configuration
            return
        }
        
        
        let container = try await LLMModelFactory.shared.loadContainer(
            hub: HubApi(),
            configuration: configuration,
            progressHandler: progressHandler
        )
        
        
        modelCache.setObject(container, forKey: configuration.name as NSString)
        self.modelContainer = container
        self.currentModel = configuration
    }
    
    func unloadModel() {
        modelContainer = nil
        currentModel = nil
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
    }
    
    func generate(
        messages: [ChatMessage],
        config: GenerationConfig = GenerationConfig()
    ) async throws -> AsyncThrowingStream<String, Error> {
        
        if DeviceUtility.isSimulator {
            return createSimulatorResponse(for: messages, config: config)
        }
        
        guard let container = modelContainer else {
            throw MLXServiceError.modelNotLoaded
        }
        
        
        let chatMessages = messages.map { message in
            let role: Chat.Message.Role = {
                switch message.role {
                case .system:
                    return .system
                case .user:
                    return .user
                case .assistant:
                    return .assistant
                }
            }()
            
            return Chat.Message(role: role, content: message.content)
        }
        
        Self.debugLog("MLX Chat Messages:")
        for (index, msg) in chatMessages.enumerated() {
            Self.debugLog("  [\(index)] Role: \(msg.role), Content: \(msg.content)")
        }
        Self.debugLog("MLX Temperature: \(config.temperature)")
        Self.debugLog("MLX Max Tokens: \(config.maxTokens)")
        
        
        let userInput = UserInput(chat: chatMessages)
        
        
        let parameters = MLXLMCommon.GenerateParameters(
            maxTokens: config.maxTokens,
            temperature: config.temperature
        )
        
        return AsyncThrowingStream { continuation in
            let generationTask = Task {
                do {
                    
                    let impactGenerator = await MainActor.run {
                        let generator = UIImpactFeedbackGenerator(style: HapticConfig.impactStyle)
                        generator.prepare()
                        return generator
                    }
                    
                    let notificationGenerator = await MainActor.run {
                        let generator = UINotificationFeedbackGenerator()
                        generator.prepare()
                        return generator
                    }
                    
                    
                    let stream = try await container.perform { context in
                        let input = try await context.processor.prepare(input: userInput)
                        return try MLXLMCommon.generate(
                            input: input,
                            parameters: parameters,
                            context: context
                        )
                    }
                    
                    
                    var tokenCount = 0
                    var totalText = ""
                    
                    for try await generation in stream {
                        
                        try Task.checkCancellation()
                        
                        switch generation {
                        case .chunk(let text):
                            if !text.isEmpty {
                                tokenCount += 1
                                totalText += text
                                Self.debugLog("MLX Token #\(tokenCount): '\(text)'")
                                
                                
                                if HapticConfig.isStreamingHapticsEnabled && tokenCount % HapticConfig.tokenInterval == 0 {
                                    await MainActor.run {
                                        impactGenerator.impactOccurred(intensity: HapticConfig.impactIntensity)
                                    }
                                }
                                
                                continuation.yield(text)
                            }
                        case .info(let info):
                            Self.debugLog("MLX Generation Info: \(info)")
                            break
                        }
                    }
                    
                    Self.debugLog("MLX Generation Complete - Total tokens: \(tokenCount)")
                    Self.debugLog("MLX Total generated text: \(totalText)")
                    
                    
                    await MainActor.run {
                        notificationGenerator.notificationOccurred(.success)
                    }
                    
                    continuation.finish()
                } catch {
                    if error is CancellationError {
                        Self.debugLog("MLX Generation cancelled")
                        continuation.finish(throwing: CancellationError())
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    generationTask.cancel()
                    Self.debugLog("MLX Stream terminated - cancelling generation task")
                default:
                    break
                }
            }
        }
    }
    
    
    
    private func createSimulatorResponse(
        for messages: [ChatMessage],
        config: GenerationConfig
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let simulationTask = Task {
                do {
                    
                    let impactGenerator = await MainActor.run {
                        let generator = UIImpactFeedbackGenerator(style: HapticConfig.impactStyle)
                        generator.prepare()
                        return generator
                    }
                    
                    let notificationGenerator = await MainActor.run {
                        let generator = UINotificationFeedbackGenerator()
                        generator.prepare()
                        return generator
                    }
                    
                    
                    let lastUserMessage = messages.last { $0.role == .user }?.content ?? ""
                    
                    
                    let mockResponses = [
                        "[Simulator Mode] The ancient spirits whisper through the digital void...",
                        "[Simulator Mode] In the realm of simulation, all prophecies converge...",
                        "[Simulator Mode] The oracle's wisdom transcends physical hardware...",
                        "[Simulator Mode] Even in this ethereal plane, guidance can be found..."
                    ]
                    
                    
                    let baseResponse = mockResponses.randomElement() ?? mockResponses[0]
                    let contextualResponse = "\(baseResponse)\n\nRegarding your question: '\(lastUserMessage)'\n\nThe true oracle requires a physical device to channel the divine wisdom. This is merely a shadow of what could be..."
                    
                    
                    let words = contextualResponse.split(separator: " ")
                    var wordCount = 0
                    
                    for word in words {
                        
                        try Task.checkCancellation()
                        
                        wordCount += 1
                        
                        
                        if HapticConfig.isStreamingHapticsEnabled && wordCount % HapticConfig.tokenInterval == 0 {
                            await MainActor.run {
                                impactGenerator.impactOccurred(intensity: HapticConfig.impactIntensity)
                            }
                        }
                        
                        continuation.yield(String(word) + " ")
                        try await Task.sleep(nanoseconds: 50_000_000) 
                    }
                    
                    
                    await MainActor.run {
                        notificationGenerator.notificationOccurred(.success)
                    }
                    
                    continuation.finish()
                } catch {
                    if error is CancellationError {
                        Self.debugLog("Simulator generation cancelled")
                        continuation.finish(throwing: CancellationError())
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    simulationTask.cancel()
                    Self.debugLog("Simulator stream terminated - cancelling simulation task")
                default:
                    break
                }
            }
        }
    }
    
    
    
    func generateResponse(
        prompt: String,
        systemPrompt: String? = nil,
        maxTokens: Int = 300
    ) async throws -> String {
        var messages: [ChatMessage] = []
        
        if let systemPrompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: systemPrompt))
        }
        
        messages.append(ChatMessage(role: .user, content: prompt))
        
        let config = GenerationConfig(
            temperature: 0.7,
            maxTokens: maxTokens,
            topP: 0.95,
            repetitionPenalty: 1.1
        )
        
        var response = ""
        let stream = try await generate(messages: messages, config: config)
        
        for try await chunk in stream {
            response += chunk
        }
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    
    func checkModelDownloaded(configuration: ModelConfiguration = defaultModel) async -> Bool {
        if DeviceUtility.isSimulator {
            
            return true
        }
        
        
        return modelCache.object(forKey: configuration.name as NSString) != nil
    }
    
    func deleteModelCache(configuration: ModelConfiguration = defaultModel) async throws {
        
        modelCache.removeObject(forKey: configuration.name as NSString)
        
        
        
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

enum MLXServiceError: LocalizedError {
    case modelNotLoaded
    case invalidConfiguration
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model not loaded. Please load a model first."
        case .invalidConfiguration:
            return "Invalid model configuration"
        case .downloadFailed(let reason):
            return "Model download failed: \(reason)"
        }
    }
}