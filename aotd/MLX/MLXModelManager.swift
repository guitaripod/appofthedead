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
        // Qwen and Mistral models generally handle them better
        return true // Qwen2.5 and newer models support system prompts well
    }
    
    // MARK: - Download Progress
    
    struct DownloadProgress {
        let bytesDownloaded: Int64
        let totalBytes: Int64
        let progress: Float
        
        init(bytesDownloaded: Int64, totalBytes: Int64, progress: Float? = nil) {
            self.bytesDownloaded = bytesDownloaded
            self.totalBytes = totalBytes
            if let progress = progress {
                self.progress = progress
            } else {
                self.progress = totalBytes > 0 ? Float(bytesDownloaded) / Float(totalBytes) : 0
            }
        }
    }
    
    // MARK: - Model Loading
    
    func loadModelIfNeeded() async throws {
        guard !isModelLoaded else { return }
        try await loadModel()
    }
    
    func loadModel() async throws {
        do {
            try await mlxService.loadModel { (progress: Foundation.Progress) in
            }
            
            // Persist that we've loaded the model at least once
            UserDefaults.standard.set(true, forKey: "MLXModelLoadedOnce")
            
        } catch {
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
        guard isModelLoaded else {
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
        let startTime = Date()
        var firstTokenTime: Date?
        var tokenTimings: [TimeInterval] = []
        var lastTokenTime = startTime
        
        let stream = try await mlxService.generate(
            messages: messages,
            config: config
        )
        
        for try await token in stream {
            let tokenTime = Date()
            
            // Track first token latency
            if firstTokenTime == nil {
                firstTokenTime = tokenTime
            }
            
            // Track inter-token timing
            let tokenInterval = tokenTime.timeIntervalSince(lastTokenTime)
            tokenTimings.append(tokenInterval)
            lastTokenTime = tokenTime
            
            generatedText += token
            tokenCount += 1
            onToken(token)
        }
        
        return generatedText
    }
    
    // MARK: - Model Download
    
    func downloadModel(onProgress: @escaping (DownloadProgress) -> Void) async throws {
        // The MLXService will handle the actual download through Hub
        try await mlxService.loadModel { (progress: Foundation.Progress) in
            let downloadProgress = DownloadProgress(
                bytesDownloaded: 0,  // MLX doesn't provide actual bytes
                totalBytes: 0,       // MLX doesn't provide actual bytes
                progress: Float(progress.fractionCompleted)
            )
            onProgress(downloadProgress)
        }
    }
    
    // MARK: - Clean Up
    
    func unloadModel() {
        mlxService.unloadModel()
    }
    
    // MARK: - Memory Management
    
    /// Handle memory pressure by clearing caches but keeping model loaded if possible
    func handleMemoryPressure() {
        // Clear any caches or temporary data
        // The MLX framework should handle its own memory management
        // We don't want to unload the model unless absolutely necessary
        // as reloading is expensive
        
        // Force garbage collection in MLX
        // This is a placeholder - MLX should handle this internally
    }
    
    /// Check available memory to decide if we should preemptively manage resources
    func checkMemoryStatus() -> (availableMemory: Int64, totalMemory: Int64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Int64(info.resident_size)
            let totalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
            let availableMemory = totalMemory - usedMemory
            
            return (availableMemory, totalMemory)
        }
        
        return (0, 0)
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

