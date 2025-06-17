import Foundation
import MLX
import MLXNN
import MLXLinalg

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
    
    private var model: LLMModel?
    private var tokenizer: Tokenizer?
    private let modelName = "HuggingFaceTB/SmolLM2-1.7B-Instruct-Q8-mlx"
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var modelURL: URL {
        documentsURL.appendingPathComponent("SmolLM2-1.7B-Instruct-Q8-mlx")
    }
    
    var isModelDownloaded: Bool {
        FileManager.default.fileExists(atPath: modelURL.path)
    }
    
    var isModelLoaded: Bool {
        model != nil && tokenizer != nil
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
        
        // Set memory limit for iOS
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024) // 20MB buffer cache
        
        // For demonstration, create a mock configuration
        // In production, this would load from the actual model files
        let config = LLMModelConfiguration(
            modelType: "smollm2",
            vocabSize: 49152,
            hiddenSize: 1536,
            numHiddenLayers: 28,
            numAttentionHeads: 24,
            intermediateSize: 8960,
            maxPositionEmbeddings: 2048,
            rmsNormEps: 1e-5,
            ropeTheta: 10000.0,
            tieWordEmbeddings: true
        )
        
        print("[MLXModelManager] Creating LLM model")
        // Create model (for demo purposes)
        let llmModel = try LLMModel(configuration: config)
        
        print("[MLXModelManager] Creating tokenizer")
        // Create tokenizer
        let tokenizerConfig = TokenizerConfig(
            modelMaxLength: 2048,
            padTokenId: 3,
            eosTokenId: 2,
            bosTokenId: 0
        )
        let llmTokenizer = try Tokenizer(config: tokenizerConfig)
        
        // Set the properties
        self.model = llmModel
        self.tokenizer = llmTokenizer
        
        // Persist that we've loaded the model at least once
        UserDefaults.standard.set(true, forKey: "MLXModelLoadedOnce")
        
        print("[MLXModelManager] Model loaded successfully")
        print("[MLXModelManager] isModelLoaded: \(isModelLoaded)")
    }
    
    // MARK: - Text Generation
    
    func generate(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.7,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        print("[MLXModelManager] Generate called")
        print("[MLXModelManager] Model loaded: \(model != nil), Tokenizer loaded: \(tokenizer != nil)")
        
        guard let model = model, let tokenizer = tokenizer else {
            print("[MLXModelManager] Error: Model or tokenizer not loaded")
            throw MLXError.modelNotLoaded
        }
        
        // Format prompt with system message
        let fullPrompt = formatPrompt(system: systemPrompt, user: prompt)
        print("[MLXModelManager] Full prompt length: \(fullPrompt.count) characters")
        
        // Create the generate parameters
        let generateParams = GenerateParameters(
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        // Generate with streaming
        var generatedText = ""
        var tokenCount = 0
        
        print("[MLXModelManager] Starting generation stream")
        
        for try await token in model.generate(
            prompt: fullPrompt,
            parameters: generateParams
        ) {
            generatedText += token
            tokenCount += 1
            onToken(token)
        }
        
        print("[MLXModelManager] Generation complete. Generated \(tokenCount) tokens")
        
        return generatedText
    }
    
    // MARK: - Helpers
    
    private func formatPrompt(system: String, user: String) -> String {
        return """
        <|im_start|>system
        \(system)<|im_end|>
        <|im_start|>user
        \(user)<|im_end|>
        <|im_start|>assistant
        """
    }
    
    // MARK: - Model Download
    
    func downloadModel(onProgress: @escaping (DownloadProgress) -> Void) async throws {
        print("[MLXModelManager] Starting model download (simulated)")
        
        // For demonstration purposes, we'll simulate model availability
        // In production, this would download from Hugging Face Hub
        
        // Create model directory
        try FileManager.default.createDirectory(
            at: modelURL,
            withIntermediateDirectories: true
        )
        
        // Simulate download progress
        for i in 0...10 {
            let progress = DownloadProgress(
                bytesDownloaded: Int64(i * 100_000_000),
                totalBytes: 1_000_000_000
            )
            onProgress(progress)
            
            // Call on main thread
            await MainActor.run {
                print("[MLXModelManager] Download progress: \(Int(progress.progress * 100))%")
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        print("[MLXModelManager] Model download complete (simulated)")
        
        // Create a marker file to indicate download complete
        let markerURL = modelURL.appendingPathComponent(".downloaded")
        try "downloaded".write(to: markerURL, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Clean Up
    
    func unloadModel() {
        model = nil
        tokenizer = nil
        MLX.GPU.set(cacheLimit: 0)
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

// MARK: - Generate Parameters

struct GenerateParameters {
    let temperature: Float
    let maxTokens: Int
    let topP: Float = 0.95
    let repetitionPenalty: Float = 1.1
}