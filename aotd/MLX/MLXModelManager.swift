import Foundation
import MLX

final class MLXModelManager {
    
    // MARK: - Singleton
    
    static let shared = MLXModelManager()
    
    private init() {
        // Check if model was previously loaded
        if UserDefaults.standard.bool(forKey: "MLXModelLoadedOnce") {
            // The model was loaded before, we can auto-load it
            Task {
                try? await loadModelIfNeeded()
            }
        }
    }
    
    // MARK: - Properties
    
    private let mlxService = MLXService.shared
    
    var isModelDownloaded: Bool {
        get async {
            await mlxService.checkModelDownloaded()
        }
    }
    
    var isModelLoaded: Bool {
        mlxService.isModelLoaded
    }
    
    /// Returns true if the currently loaded model supports system prompts well
    var supportsSystemPrompts: Bool {
        // SmolLM models have known issues with system prompts
        // Qwen models generally handle them better
        return false // For now, always return false since we're using SmolLM by default
    }
    
    // MARK: - Download Progress
    
    struct DownloadProgress {
        let bytesDownloaded: Int64
        let totalBytes: Int64
        var progress: Float {
            guard totalBytes > 0 else { return 0 }
            return Float(bytesDownloaded) / Float(totalBytes)
        }
    }
    
    // MARK: - Model Loading
    
    func loadModelIfNeeded() async throws {
        guard !isModelLoaded else { return }
        try await loadModel()
    }
    
    func loadModel() async throws {
        print("[MLXModelManager] Starting model load")
        
        do {
            try await mlxService.loadModel { (progress: Foundation.Progress) in
                let fractionCompleted = progress.totalUnitCount > 0 ? Double(progress.completedUnitCount) / Double(progress.totalUnitCount) : 0
                print("[MLXModelManager] Load progress: \(fractionCompleted * 100)%")
            }
            
            // Persist that we've loaded the model at least once
            UserDefaults.standard.set(true, forKey: "MLXModelLoadedOnce")
            
            print("[MLXModelManager] Model loaded successfully")
            print("[MLXModelManager] isModelLoaded: \(isModelLoaded)")
        } catch {
            print("[MLXModelManager] Model load error: \(error)")
            throw error
        }
    }
    
    // MARK: - Text Generation
    
    func generate(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.7,
        useSystemPrompt: Bool = false, // Control whether to use system prompts
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        print("[MLXModelManager] Generate called")
        print("[MLXModelManager] Model loaded: \(isModelLoaded)")
        
        guard isModelLoaded else {
            print("[MLXModelManager] Error: Model not loaded")
            throw MLXError.modelNotLoaded
        }
        
        // Create chat messages
        let messages: [ChatMessage]
        if useSystemPrompt {
            // Use system prompts for models that support them (e.g., Qwen3)
            messages = [
                ChatMessage(role: .system, content: systemPrompt),
                ChatMessage(role: .user, content: prompt)
            ]
        } else {
            // For models like SmolLM that may not properly support system prompts
            messages = [
                ChatMessage(role: .user, content: prompt)
            ]
        }
        
        // Configure generation
        let config = MLXService.GenerationConfig(
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        // Generate with streaming
        var generatedText = ""
        var tokenCount = 0
        
        print("[MLXModelManager] Starting generation stream")
        
        let stream = try await mlxService.generate(
            messages: messages,
            config: config
        )
        
        for try await token in stream {
            generatedText += token
            tokenCount += 1
            onToken(token)
        }
        
        print("[MLXModelManager] Generation complete. Generated \(tokenCount) tokens")
        
        return generatedText
    }
    
    // MARK: - Model Download
    
    func downloadModel(onProgress: @escaping (DownloadProgress) -> Void) async throws {
        print("[MLXModelManager] Starting model download")
        
        // The MLXService will handle the actual download through Hub
        try await mlxService.loadModel { (progress: Foundation.Progress) in
            let downloadProgress = DownloadProgress(
                bytesDownloaded: progress.completedUnitCount,
                totalBytes: progress.totalUnitCount
            )
            onProgress(downloadProgress)
        }
        
        print("[MLXModelManager] Model download complete")
    }
    
    // MARK: - Clean Up
    
    func unloadModel() {
        mlxService.unloadModel()
    }
}

// MARK: - Supporting Types

enum MLXError: LocalizedError {
    case modelNotDownloaded
    case modelNotLoaded
    case downloadNotImplemented
    
    var errorDescription: String? {
        switch self {
        case .modelNotDownloaded:
            return "Model has not been downloaded yet"
        case .modelNotLoaded:
            return "Model has not been loaded into memory"
        case .downloadNotImplemented:
            return "Model download not yet implemented"
        }
    }
}

