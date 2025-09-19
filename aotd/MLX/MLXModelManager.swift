import Foundation
import MLX

final class MLXModelManager {
    
    
    
    static let shared = MLXModelManager()
    
    private init() {
        
        if UserDefaults.standard.bool(forKey: "MLXModelLoadedOnce") {
            
            Task {
                try? await loadModelIfNeeded()
            }
        }
    }
    
    
    
    private let mlxService = MLXService.shared
    
    var isModelDownloaded: Bool {
        get async {
            await mlxService.checkModelDownloaded()
        }
    }
    
    var isModelLoaded: Bool {
        mlxService.isModelLoaded
    }
    
    
    var supportsSystemPrompts: Bool {
        
        
        return true 
    }
    
    
    
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
    
    
    
    func loadModelIfNeeded() async throws {
        guard !isModelLoaded else { return }
        try await loadModel()
    }
    
    func loadModel() async throws {
        do {
            try await mlxService.loadModel { (progress: Foundation.Progress) in
            }
            
            
            UserDefaults.standard.set(true, forKey: "MLXModelLoadedOnce")
            
        } catch {
            throw error
        }
    }
    
    
    
    func generate(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.7,
        useSystemPrompt: Bool = false, 
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard isModelLoaded else {
            throw MLXError.modelNotLoaded
        }
        
        
        let messages: [ChatMessage]
        if useSystemPrompt {
            
            messages = [
                ChatMessage(role: .system, content: systemPrompt),
                ChatMessage(role: .user, content: prompt)
            ]
        } else {
            
            messages = [
                ChatMessage(role: .user, content: prompt)
            ]
        }
        
        
        let config = MLXService.GenerationConfig(
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        
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
            
            
            if firstTokenTime == nil {
                firstTokenTime = tokenTime
            }
            
            
            let tokenInterval = tokenTime.timeIntervalSince(lastTokenTime)
            tokenTimings.append(tokenInterval)
            lastTokenTime = tokenTime
            
            generatedText += token
            tokenCount += 1
            onToken(token)
        }
        
        return generatedText
    }
    
    
    
    func downloadModel(onProgress: @escaping (DownloadProgress) -> Void) async throws {
        
        try await mlxService.loadModel { (progress: Foundation.Progress) in
            let downloadProgress = DownloadProgress(
                bytesDownloaded: 0,  
                totalBytes: 0,       
                progress: Float(progress.fractionCompleted)
            )
            onProgress(downloadProgress)
        }
    }
    
    
    
    func unloadModel() {
        mlxService.unloadModel()
    }
    
    
    
    
    func handleMemoryPressure() {
        
        
        
        
        
        
        
    }
    
    
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

