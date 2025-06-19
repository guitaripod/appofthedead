import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Hub
import UIKit

final class MLXService {
    
    // MARK: - Singleton
    
    static let shared = MLXService()
    
    private init() {}
    
    // MARK: - Haptic Configuration
    
    private struct HapticConfig {
        static let tokenInterval = 3 // Haptic every 3rd token
        static let impactIntensity: CGFloat = 0.4 // Medium-subtle intensity
        static let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
        static let userDefaultsKey = "StreamingHapticsEnabled"
        
        static var isStreamingHapticsEnabled: Bool {
            // Default to true if not set
            return UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? true
        }
    }
    
    // MARK: - Properties
    
    private var modelContainer: ModelContainer?
    private let modelCache = NSCache<NSString, ModelContainer>()
    private var currentModel: ModelConfiguration?
    
    // Available models suitable for mobile
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
    
    // Default model for Oracle
    // Using Llama3.2-3B for good quality with mobile-friendly memory usage
    static let defaultModel = LLMRegistry.llama3_2_3B_4bit
    
    var isModelLoaded: Bool {
        if DeviceUtility.isSimulator {
            return currentModel != nil
        }
        return modelContainer != nil
    }
    
    // MARK: - Model Management
    
    func loadModel(
        configuration: ModelConfiguration = defaultModel,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void
    ) async throws {
        // Check if running in simulator
        if DeviceUtility.isSimulator {
            print("🤖 MLX: Running in simulator - using mock mode")
            // Simulate loading progress
            let progress = Foundation.Progress(totalUnitCount: 100)
            for i in 0...100 {
                progress.completedUnitCount = Int64(i)
                progressHandler(progress)
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
            }
            // Mark as loaded without actually loading
            self.currentModel = configuration
            return
        }
        
        // Set GPU memory limit for iOS
        MLX.GPU.set(cacheLimit: 512 * 1024 * 1024) // 512MB cache for Llama3.2-3B
        
        // Check cache first
        let cacheKey = configuration.name as NSString
        if let cached = modelCache.object(forKey: cacheKey) {
            self.modelContainer = cached
            self.currentModel = configuration
            return
        }
        
        // Load from hub
        let container = try await LLMModelFactory.shared.loadContainer(
            hub: HubApi(),
            configuration: configuration,
            progressHandler: progressHandler
        )
        
        // Cache the loaded model
        modelCache.setObject(container, forKey: configuration.name as NSString)
        self.modelContainer = container
        self.currentModel = configuration
    }
    
    func unloadModel() {
        modelContainer = nil
        currentModel = nil
        MLX.GPU.set(cacheLimit: 0)
        
        // Force memory cleanup
        MLX.GPU.clearCache()
    }
    
    // MARK: - Text Generation
    
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
        // Handle simulator mode
        if DeviceUtility.isSimulator {
            return createSimulatorResponse(for: messages, config: config)
        }
        
        guard let container = modelContainer else {
            throw MLXServiceError.modelNotLoaded
        }
        
        // Convert to MLX chat format
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
        
        #if DEBUG
        print("🤖 MLX Chat Messages:")
        for (index, msg) in chatMessages.enumerated() {
            print("  [\(index)] Role: \(msg.role), Content: \(msg.content)")
        }
        print("🤖 MLX Temperature: \(config.temperature)")
        print("🤖 MLX Max Tokens: \(config.maxTokens)")
        #endif
        
        // Create user input
        let userInput = UserInput(chat: chatMessages)
        
        // Generate parameters
        let parameters = MLXLMCommon.GenerateParameters(
            maxTokens: config.maxTokens,
            temperature: config.temperature
        )
        
        return AsyncThrowingStream { continuation in
            let generationTask = Task {
                do {
                    // Prepare haptic generators
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
                    
                    // Use the model container to generate
                    let stream = try await container.perform { context in
                        let input = try await context.processor.prepare(input: userInput)
                        return try MLXLMCommon.generate(
                            input: input,
                            parameters: parameters,
                            context: context
                        )
                    }
                    
                    // Stream the tokens
                    #if DEBUG
                    var tokenCount = 0
                    var totalText = ""
                    #endif
                    
                    for try await generation in stream {
                        // Check for cancellation before processing each token
                        try Task.checkCancellation()
                        
                        switch generation {
                        case .chunk(let text):
                            if !text.isEmpty {
                                #if DEBUG
                                tokenCount += 1
                                totalText += text
                                print("🤖 MLX Token #\(tokenCount): '\(text)'")
                                #endif
                                
                                // Subtle impact haptic feedback at configured interval
                                if HapticConfig.isStreamingHapticsEnabled && tokenCount % HapticConfig.tokenInterval == 0 {
                                    await MainActor.run {
                                        impactGenerator.impactOccurred(intensity: HapticConfig.impactIntensity)
                                    }
                                }
                                
                                continuation.yield(text)
                            }
                        case .info(let info):
                            #if DEBUG
                            print("🤖 MLX Generation Info: \(info)")
                            #endif
                            break
                        }
                    }
                    
                    #if DEBUG
                    print("🤖 MLX Generation Complete - Total tokens: \(tokenCount)")
                    print("🤖 MLX Total generated text: \(totalText)")
                    #endif
                    
                    // Success haptic on completion
                    await MainActor.run {
                        notificationGenerator.notificationOccurred(.success)
                    }
                    
                    continuation.finish()
                } catch {
                    if error is CancellationError {
                        #if DEBUG
                        print("🤖 MLX Generation cancelled")
                        #endif
                        continuation.finish(throwing: CancellationError())
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            // Handle stream termination on cancellation
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    generationTask.cancel()
                    #if DEBUG
                    print("🤖 MLX Stream terminated - cancelling generation task")
                    #endif
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Simulator Support
    
    private func createSimulatorResponse(
        for messages: [ChatMessage],
        config: GenerationConfig
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let simulationTask = Task {
                do {
                    // Prepare haptic generators for simulator mode too
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
                    
                    // Get the last user message
                    let lastUserMessage = messages.last { $0.role == .user }?.content ?? ""
                    
                    // Generate a mock response based on the context
                    let mockResponses = [
                        "🔮 [Simulator Mode] The ancient spirits whisper through the digital void...",
                        "📱 [Simulator Mode] In the realm of simulation, all prophecies converge...",
                        "✨ [Simulator Mode] The oracle's wisdom transcends physical hardware...",
                        "🌟 [Simulator Mode] Even in this ethereal plane, guidance can be found..."
                    ]
                    
                    // Pick a response and add context
                    let baseResponse = mockResponses.randomElement() ?? mockResponses[0]
                    let contextualResponse = "\(baseResponse)\n\nRegarding your question: '\(lastUserMessage)'\n\nThe true oracle requires a physical device to channel the divine wisdom. This is merely a shadow of what could be..."
                    
                    // Simulate streaming response with haptics
                    let words = contextualResponse.split(separator: " ")
                    var wordCount = 0
                    
                    for word in words {
                        // Check for cancellation before each word
                        try Task.checkCancellation()
                        
                        wordCount += 1
                        
                        // Subtle impact haptic feedback at configured interval
                        if HapticConfig.isStreamingHapticsEnabled && wordCount % HapticConfig.tokenInterval == 0 {
                            await MainActor.run {
                                impactGenerator.impactOccurred(intensity: HapticConfig.impactIntensity)
                            }
                        }
                        
                        continuation.yield(String(word) + " ")
                        try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                    }
                    
                    // Success haptic on completion
                    await MainActor.run {
                        notificationGenerator.notificationOccurred(.success)
                    }
                    
                    continuation.finish()
                } catch {
                    if error is CancellationError {
                        #if DEBUG
                        print("🤖 Simulator generation cancelled")
                        #endif
                        continuation.finish(throwing: CancellationError())
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            // Handle stream termination on cancellation
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    simulationTask.cancel()
                    #if DEBUG
                    print("🤖 Simulator stream terminated - cancelling simulation task")
                    #endif
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
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
    
    // MARK: - Model Information
    
    func checkModelDownloaded(configuration: ModelConfiguration = defaultModel) async -> Bool {
        if DeviceUtility.isSimulator {
            // Always return true for simulator
            return true
        }
        // For now, check if the model is in cache
        // In production, you'd check the actual file system
        return modelCache.object(forKey: configuration.name as NSString) != nil
    }
    
    func deleteModelCache(configuration: ModelConfiguration = defaultModel) async throws {
        // Remove from memory cache
        modelCache.removeObject(forKey: configuration.name as NSString)
        
        // In production, you'd also delete the actual model files from disk
        // For now, just clear the cache
    }
}

// MARK: - Supporting Types

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