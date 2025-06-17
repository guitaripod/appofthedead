import Foundation
import UIKit
import Combine

final class OracleViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var selectedDeity: Deity?
    @Published var availableDeities: [Deity] = []
    @Published var isModelLoading = false
    @Published var isModelLoaded = false
    @Published var isGenerating = false
    @Published var modelError: String?
    @Published var downloadProgress: Float = 0.0
    @Published var downloadStatus: String = ""
    @Published var downloadStage: String = "" // Track current stage
    
    // MARK: - Properties
    
    private let modelManager = MLXModelManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
    
    struct ChatMessage {
        let id: UUID
        let text: String
        let isUser: Bool
        let deity: Deity?
        let timestamp: Date
        
        init(id: UUID = UUID(), text: String, isUser: Bool, deity: Deity?, timestamp: Date) {
            self.id = id
            self.text = text
            self.isUser = isUser
            self.deity = deity
            self.timestamp = timestamp
        }
    }
    
    struct Deity: Codable {
        let id: String
        let name: String
        let tradition: String
        let role: String
        let avatar: String
        let color: String
        let systemPrompt: String
        
        var uiColor: UIColor {
            UIColor(hex: color) ?? UIColor.Papyrus.gold
        }
    }
    
    // MARK: - Initialization
    
    init() {
        print("[OracleViewModel] Initializing")
        loadDeities()
        addWelcomeMessage()
        
        // Check initial model status
        isModelLoaded = modelManager.isModelLoaded
        print("[OracleViewModel] Initial model loaded status: \(isModelLoaded)")
        
        // Auto-load model if it was previously downloaded
        Task {
            await checkAndAutoLoadModel()
        }
    }
    
    // MARK: - Public Methods
    
    func syncModelLoadedState() {
        isModelLoaded = modelManager.isModelLoaded
        print("[OracleViewModel] Synced model loaded state: \(isModelLoaded)")
    }
    
    func loadModel() async {
        print("[OracleViewModel] Starting model load")
        
        await MainActor.run {
            isModelLoading = true
            modelError = nil
        }
        
        do {
            // First download if needed
            let isDownloaded = await modelManager.isModelDownloaded
            if !isDownloaded {
                print("[OracleViewModel] Model not downloaded, starting download")
                // Estimate total size for Llama3.2-3B model (overestimate to ~1.8GB)
                let estimatedTotalSize: Int64 = 1_932_735_283 // ~1.8GB in bytes
                
                await MainActor.run {
                    self.downloadStatus = "Preparing divine connection..."
                    self.downloadStage = "Downloading Llama 3.2 (3B) model"
                    self.downloadProgress = 0.0
                }
                
                // Add a small initial progress to show something is happening
                await MainActor.run {
                    self.downloadProgress = 0.02
                }
                
                var lastProgress: Float = 0.0
                let startTime = Date()
                var lastBytesDownloaded: Int64 = 0
                
                try await modelManager.downloadModel { progress in
                    // The progress object provides a fraction (0-1), not actual bytes
                    // Calculate estimated bytes based on progress
                    let actualProgress = progress.progress
                    let totalBytes = estimatedTotalSize
                    
                    let percentage = actualProgress * 100
                    
                    print("[OracleViewModel] Download progress: \(actualProgress) (\(percentage)%)")
                    
                    Task { @MainActor in
                        // Smooth out progress updates
                        let smoothedProgress = self.smoothProgress(current: actualProgress, last: lastProgress)
                        self.downloadProgress = smoothedProgress
                        lastProgress = smoothedProgress
                        
                        // Format download size
                        let downloadedMB = Double(smoothedProgress) * Double(totalBytes) / (1024 * 1024)
                        let totalMB = Double(totalBytes) / (1024 * 1024)
                        
                        // Update status with more descriptive messages
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        if smoothedProgress < 0.3 {
                            self.downloadStatus = String(format: "Gathering sacred texts... %.0f MB / %.0f MB", downloadedMB, totalMB)
                        } else if smoothedProgress < 0.6 {
                            self.downloadStatus = String(format: "Channeling divine wisdom... %.0f MB / %.0f MB", downloadedMB, totalMB)
                        } else if smoothedProgress < 0.9 {
                            self.downloadStatus = String(format: "Establishing connection... %.0f MB / %.0f MB", downloadedMB, totalMB)
                        } else {
                            self.downloadStatus = String(format: "Finalizing oracle preparations... %.0f MB / %.0f MB", downloadedMB, totalMB)
                        }
                        
                        // Calculate download speed and time estimate
                        let estimatedBytesDownloaded = Int64(smoothedProgress * Float(totalBytes))
                        if elapsedTime > 3 && estimatedBytesDownloaded > lastBytesDownloaded {
                            let bytesPerSecond = Double(estimatedBytesDownloaded) / elapsedTime
                            let remainingBytes = totalBytes - estimatedBytesDownloaded
                            let remainingSeconds = Double(remainingBytes) / bytesPerSecond
                            
                            if remainingSeconds > 5 && remainingSeconds < 3600 { // Between 5 seconds and 1 hour
                                let speedMBps = bytesPerSecond / (1024 * 1024)
                                self.downloadStage = String(format: "%.1f MB/s • %@", speedMBps, self.formatTime(remainingSeconds))
                            }
                        }
                        
                        lastBytesDownloaded = estimatedBytesDownloaded
                    }
                }
                
                await MainActor.run {
                    self.downloadProgress = 1.0
                    self.downloadStatus = "Download complete! Awakening the oracle..."
                    self.downloadStage = ""
                }
            }
            
            // Then load the model
            print("[OracleViewModel] Loading model into memory")
            await MainActor.run {
                self.downloadStatus = "Oracle awakening..."
            }
            
            try await modelManager.loadModel()
            
            await MainActor.run {
                isModelLoaded = true
                isModelLoading = false
                self.downloadStatus = ""
                self.downloadStage = ""
                print("[OracleViewModel] Model loaded successfully")
            }
        } catch {
            print("[OracleViewModel] Model load error: \(error)")
            await MainActor.run {
                modelError = error.localizedDescription
                isModelLoading = false
                isModelLoaded = false
            }
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let deity = selectedDeity else {
            print("[OracleViewModel] Cannot send message - empty text or no deity selected")
            return
        }
        
        print("[OracleViewModel] Sending message: \(text) to deity: \(deity.name)")
        
        // Add user message
        let userMessage = ChatMessage(
            text: text,
            isUser: true,
            deity: nil,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(userMessage)
        }
        
        // Generate response
        await generateResponse(to: text, deity: deity)
    }
    
    func selectDeity(_ deity: Deity) {
        print("[OracleViewModel] Selecting deity: \(deity.name)")
        selectedDeity = deity
        // Clear chat history when switching deities
        messages.removeAll()
        addDeityGreeting(deity)
    }
    
    // MARK: - Private Methods
    
    private func checkAndAutoLoadModel() async {
        print("[OracleViewModel] Checking for auto-load")
        
        // Check if model was previously loaded
        let wasLoadedBefore = UserDefaults.standard.bool(forKey: "MLXModelLoadedOnce")
        print("[OracleViewModel] Model was loaded before: \(wasLoadedBefore)")
        
        // Check if model is already loaded in memory
        if isModelLoaded {
            print("[OracleViewModel] Model already loaded in memory")
            return
        }
        
        // Check if model files exist and auto-load if they do
        let isDownloaded = await modelManager.isModelDownloaded
        if wasLoadedBefore && isDownloaded {
            print("[OracleViewModel] Auto-loading previously downloaded model")
            
            await MainActor.run {
                isModelLoading = true
                downloadStatus = "Loading Oracle model..."
            }
            
            do {
                try await modelManager.loadModel()
                
                await MainActor.run {
                    isModelLoaded = true
                    isModelLoading = false
                    downloadStatus = ""
                    print("[OracleViewModel] Model auto-loaded successfully")
                }
            } catch {
                print("[OracleViewModel] Auto-load error: \(error)")
                await MainActor.run {
                    modelError = "Failed to auto-load model: \(error.localizedDescription)"
                    isModelLoading = false
                    downloadStatus = ""
                }
            }
        }
    }
    
    private func loadDeities() {
        print("[OracleViewModel] Loading deities from JSON")
        
        guard let url = Bundle.main.url(forResource: "deity_prompts", withExtension: "json") else {
            print("[OracleViewModel] Error: Could not find deity_prompts.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let deitiesData = try JSONDecoder().decode(DeitiesData.self, from: data)
            availableDeities = Array(deitiesData.deities.values).sorted { $0.name < $1.name }
            selectedDeity = availableDeities.first
            
            print("[OracleViewModel] Loaded \(availableDeities.count) deities")
            print("[OracleViewModel] Selected deity: \(selectedDeity?.name ?? "none")")
        } catch {
            print("[OracleViewModel] Error loading deities: \(error)")
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeText = "Welcome to the Oracle! Here you can converse with divine beings from various traditions. Select a deity to begin your dialogue."
        let welcomeMessage = ChatMessage(
            text: welcomeText,
            isUser: false,
            deity: nil,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func addDeityGreeting(_ deity: Deity) {
        let greetings: [String: String] = [
            "anubis": "I am Anubis, Guardian of the Scales. I have witnessed countless souls on their journey through the afterlife. What wisdom do you seek?",
            "hermes": "Greetings, mortal! I am Hermes, swift messenger between realms. I traverse both the world of the living and the dead. How may I guide you?",
            "gabriel": "Peace be upon you. I am Gabriel, herald of divine messages. I bring tidings from the celestial realm. What questions weigh upon your heart?",
            "yama": "I am Yama, the first to die and thus the guide for all who follow. I maintain the cosmic order between life and death. Speak, and I shall answer.",
            "mictlantecuhtli": "I am Mictlantecuhtli, Lord of the Bone Palace. In Mictlan, all souls find their rest. What do you wish to know about the journey ahead?",
            "baron_samedi": "Ah, another soul comes to Baron Samedi! I stand at the crossroads between life and death. What brings you to my domain, child?",
            "odin": "I am Odin, All-Father, who sacrificed an eye for wisdom. I know the fate of all things. What knowledge do you seek from the halls of Asgard?",
            "kali": "I am Kali, dancer upon the cremation grounds, destroyer of illusion. Through destruction comes liberation. What veils would you have me tear away?"
        ]
        
        if let greeting = greetings[deity.id] {
            let message = ChatMessage(
                text: greeting,
                isUser: false,
                deity: deity,
                timestamp: Date()
            )
            messages.append(message)
        }
    }
    
    private func generateResponse(to userMessage: String, deity: Deity) async {
        print("[OracleViewModel] Generating response for: \(userMessage)")
        print("[OracleViewModel] Using deity: \(deity.name)")
        
        await MainActor.run {
            isGenerating = true
        }
        
        do {
            // Create a message that will be updated with streaming tokens
            let responseMessage = ChatMessage(
                text: "",
                isUser: false,
                deity: deity,
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.append(responseMessage)
            }
            
            let messageIndex = messages.count - 1
            var fullResponse = ""
            
            // Generate response with streaming
            #if DEBUG
            print("🔮 Oracle System Prompt: \(deity.systemPrompt)")
            print("🔮 Oracle User Message: \(userMessage)")
            print("🔮 Oracle Starting response generation...")
            #endif
            
            // Qwen3 should handle system prompts properly
            _ = try await modelManager.generate(
                prompt: userMessage,
                systemPrompt: deity.systemPrompt,
                maxTokens: 800,  // Increased to allow complete responses
                temperature: 0.7,
                useSystemPrompt: true // Enable system prompts for Qwen3
            ) { token in
                // Update message with each token
                Task { @MainActor in
                    fullResponse += token
                    
                    #if DEBUG
                    print("🔮 Oracle Token: \(token)")
                    #endif
                    
                    // Only update UI if we're not inside think tags
                    if !fullResponse.contains("<think>") || fullResponse.contains("</think>") {
                        let cleanedResponse = self.removeThinkTags(from: fullResponse)
                        if messageIndex < self.messages.count && !cleanedResponse.isEmpty {
                            self.messages[messageIndex] = ChatMessage(
                                id: responseMessage.id,
                                text: cleanedResponse,
                                isUser: false,
                                deity: deity,
                                timestamp: responseMessage.timestamp
                            )
                        }
                    }
                }
            }
            
            // Final cleanup and update
            let cleanedResponse = removeThinkTags(from: fullResponse)
            
            // Ensure final message is updated with complete cleaned response
            await MainActor.run {
                if messageIndex < messages.count {
                    messages[messageIndex] = ChatMessage(
                        id: responseMessage.id,
                        text: cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines),
                        isUser: false,
                        deity: deity,
                        timestamp: responseMessage.timestamp
                    )
                }
                isGenerating = false
            }
            
            #if DEBUG
            print("🔮 Oracle Complete Response: \(cleanedResponse)")
            print("🔮 Oracle Response length: \(cleanedResponse.count) characters")
            if cleanedResponse != fullResponse {
                print("🔮 Oracle Filtered out think tags")
            }
            #endif
            
        } catch {
            print("[OracleViewModel] Generation error: \(error)")
            
            let errorMessage = ChatMessage(
                text: "I apologize, but I'm having trouble connecting to the divine realm. Please try again.",
                isUser: false,
                deity: deity,
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.append(errorMessage)
                modelError = error.localizedDescription
                isGenerating = false
            }
        }
    }
    
    private func removeThinkTags(from text: String) -> String {
        // Simple regex to remove think tags
        let pattern = "<think>.*?</think>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let regex = regex {
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return text
    }
    
    // MARK: - Helper Methods
    
    private func smoothProgress(current: Float, last: Float) -> Float {
        // If progress jumped backwards or stayed the same, keep incrementing slowly
        if current <= last {
            return min(last + 0.001, 0.99) // Never reach 100% until actually done
        }
        
        // For normal progress, smooth out large jumps
        let maxJump: Float = 0.05 // Maximum 5% jump at a time
        let diff = current - last
        
        if diff > maxJump {
            return last + maxJump
        }
        
        return current
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
            return secs > 0 ? "\(minutes)m \(secs)s" : "\(minutes)m"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    // MARK: - Supporting Types
    
    private struct DeitiesData: Codable {
        let deities: [String: Deity]
    }
}