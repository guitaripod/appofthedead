import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Hub

final class MLXService {
    
    // MARK: - Singleton
    
    static let shared = MLXService()
    
    private init() {}
    
    // MARK: - Properties
    
    private var modelContainer: ModelContainer?
    private let modelCache = NSCache<NSString, ModelContainer>()
    private var currentModel: ModelConfiguration?
    
    // Available models suitable for mobile
    static let availableModels: [(name: String, config: ModelConfiguration)] = [
        ("SmolLM-135M", LLMRegistry.smolLM_135M_4bit),
        ("Qwen3-0.6B", LLMRegistry.qwen3_0_6b_4bit),
        ("Qwen3-1.7B", LLMRegistry.qwen3_1_7b_4bit)
    ]
    
    // Default model for Oracle
    static let defaultModel = LLMRegistry.smolLM_135M_4bit
    
    var isModelLoaded: Bool {
        modelContainer != nil
    }
    
    // MARK: - Model Management
    
    func loadModel(
        configuration: ModelConfiguration = defaultModel,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void
    ) async throws {
        // Set GPU memory limit for iOS
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024) // 20MB cache
        
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
        
        // Create user input
        let userInput = UserInput(chat: chatMessages)
        
        // Generate parameters
        let parameters = MLXLMCommon.GenerateParameters(
            temperature: config.temperature
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
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
                    for try await generation in stream {
                        switch generation {
                        case .chunk(let text):
                            if !text.isEmpty {
                                continuation.yield(text)
                            }
                        case .info:
                            // Ignore completion info for now
                            break
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Model Information
    
    func checkModelDownloaded(configuration: ModelConfiguration = defaultModel) async -> Bool {
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