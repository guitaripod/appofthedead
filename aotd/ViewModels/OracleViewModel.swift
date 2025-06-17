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
    
    // MARK: - Properties
    
    private let modelManager = MLXModelManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
    
    struct ChatMessage {
        let id = UUID()
        let text: String
        let isUser: Bool
        let deity: Deity?
        let timestamp: Date
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
        loadDeities()
        addWelcomeMessage()
    }
    
    // MARK: - Public Methods
    
    func loadModel() async {
        isModelLoading = true
        modelError = nil
        
        do {
            try await modelManager.loadModel()
            await MainActor.run {
                isModelLoaded = true
                isModelLoading = false
            }
        } catch {
            await MainActor.run {
                modelError = error.localizedDescription
                isModelLoading = false
            }
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let deity = selectedDeity else { return }
        
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
        selectedDeity = deity
        addDeityGreeting(deity)
    }
    
    // MARK: - Private Methods
    
    private func loadDeities() {
        guard let url = Bundle.main.url(forResource: "deity_prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deitiesData = try? JSONDecoder().decode(DeitiesData.self, from: data) else {
            return
        }
        
        availableDeities = Array(deitiesData.deities.values).sorted { $0.name < $1.name }
        selectedDeity = availableDeities.first
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
        guard isModelLoaded else {
            // Fallback response if model not loaded
            let fallbackResponse = "The divine connection is not yet established. Please wait while I prepare the sacred channels..."
            let message = ChatMessage(
                text: fallbackResponse,
                isUser: false,
                deity: deity,
                timestamp: Date()
            )
            await MainActor.run {
                messages.append(message)
            }
            return
        }
        
        await MainActor.run {
            isGenerating = true
        }
        
        do {
            var responseText = ""
            let responseMessage = ChatMessage(
                text: "",
                isUser: false,
                deity: deity,
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.append(responseMessage)
            }
            
            // Generate response with streaming
            let response = try await modelManager.generate(
                prompt: userMessage,
                systemPrompt: deity.systemPrompt,
                maxTokens: 256,
                temperature: 0.8
            ) { [weak self] token in
                Task { @MainActor in
                    guard let self = self else { return }
                    responseText += token
                    if let index = self.messages.lastIndex(where: { $0.id == responseMessage.id }) {
                        self.messages[index] = ChatMessage(
                            text: responseText,
                            isUser: false,
                            deity: deity,
                            timestamp: responseMessage.timestamp
                        )
                    }
                }
            }
            
            await MainActor.run {
                isGenerating = false
            }
            
        } catch {
            await MainActor.run {
                isGenerating = false
                modelError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Supporting Types
    
    private struct DeitiesData: Codable {
        let deities: [String: Deity]
    }
}