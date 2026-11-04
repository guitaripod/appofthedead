import Foundation
import UIKit
import Combine
import MidgarCore
import MidgarIntelligence
import AppOfTheDeadCore

final class OracleViewModel: ObservableObject {
    
    
    
    @Published var messages: [ChatMessage] = []
    @Published var selectedDeity: Deity?
    @Published var availableDeities: [Deity] = []
    @Published var isModelLoading = false
    @Published var isModelLoaded = false
    @Published var isGenerating = false
    @Published var modelError: String?
    @Published var downloadProgress: Float = 0.0
    @Published var downloadStatus: String = ""
    @Published var downloadStage: String = "" 
    
    
    
    private let modelManager = MLXModelManager.shared
    private let voice = OracleVoice.shared
    private let contentLoader = ContentLoader()
    private var cancellables = Set<AnyCancellable>()
    private var generationTask: Task<Void, Never>?
    private var activeGenerationID: UUID?
    private var activeGenerationDeityId: String?
    private var activeGenerationDelivered = false
    
    
    private var lastBytesDownloaded: Int64 = 0
    private var lastUpdateTime = Date()
    private var lastKnownSpeed: Double = 0.0
    
    
    private var downloadStartTime = Date()
    private var lastReportedProgress: Float = 0.0
    private var progressHistory: [(time: Date, progress: Float)] = []
    private var smoothedProgressValue: Float = 0.0
    private var progressAnimator: Timer?
    
    
    
    struct ChatMessage {
        /// What a message is: a turn of the conversation, or the app stepping out of the persona to offer help.
        enum Kind {
            case conversation
            case care
            /// The app speaking for a persona that could not answer; never fed back to the model as its words.
            case notice
        }

        let id: UUID
        let text: String
        let isUser: Bool
        let deity: Deity?
        let timestamp: Date
        let kind: Kind

        init(id: UUID = UUID(), text: String, isUser: Bool, deity: Deity?, timestamp: Date, kind: Kind = .conversation) {
            self.id = id
            self.text = text
            self.isUser = isUser
            self.deity = deity
            self.timestamp = timestamp
            self.kind = kind
        }
    }
    
    nonisolated struct Deity: Codable, Hashable {
        let id: String
        let name: String
        let tradition: String
        let role: String
        let avatar: String
        let color: String
        let systemPrompt: String
        let suggestedPrompts: [String]?
        
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Deity, rhs: Deity) -> Bool {
            lhs.id == rhs.id
        }
        
    }
    
    
    
    init() {
        loadDeities()
        
        
        
        isModelLoaded = voice.isReady

        if seedDemoConversation() { return }
        askRequestedQuestion()
        
        Task {
            await checkAndAutoLoadModel()
        }
    }

    /// QA rig: `AOTD_ORACLE_ASK=<question>|<question>` asks the deity named by `AOTD_DEMO_DEITY` through the real model on
    /// launch, one question after another, so answers can be checked and captured on a device or simulator with Apple
    /// Intelligence.
    private func askRequestedQuestion() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        guard let question = environment["AOTD_ORACLE_ASK"] else { return }
        if let id = environment["AOTD_DEMO_DEITY"], let deity = availableDeities.first(where: { $0.id == id }) {
            selectedDeity = deity
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            for part in question.split(separator: "|") {
                await self.sendMessage(String(part))
            }
        }
        #endif
    }

    /// The screenshot rig fills the chat from a canned conversation and skips the model.
    private func seedDemoConversation() -> Bool {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["AOTD_ORACLE_ASK"] == nil,
              let conversation = DemoOracle.conversation(for: availableDeities) else { return false }
        selectedDeity = conversation.deity
        messages = conversation.messages
        isModelLoaded = true
        return true
        #else
        return false
        #endif
    }
    
    
    
    func syncModelLoadedState() {
        isModelLoaded = voice.isReady
    }

    /// Which model answers on this iPhone.
    var engine: OracleVoice.Engine {
        voice.engine
    }

    /// Answers a message that speaks of self-harm in the app's own voice, with help, instead of the persona's. It is
    /// not a consultation.
    @MainActor
    func respondWithCare(to text: String) {
        messages.append(ChatMessage(text: text, isUser: true, deity: nil, timestamp: Date()))
        messages.append(ChatMessage(text: CompassionGuard.message, isUser: false, deity: nil, timestamp: Date(), kind: .care))
        MidgarLog.notice("Oracle answered a message with care resources", category: .viewModel)
    }
    
    func loadModel() async {
        
        await MainActor.run {
            isModelLoading = true
            modelError = nil
        }
        
        do {
            
            let isDownloaded = await modelManager.isModelDownloaded
            if !isDownloaded {
                
                let activeModel = modelManager.activeModel
                let estimatedTotalSize: Int64 = activeModel.approximateDownloadBytes

                await MainActor.run {
                    self.downloadStatus = String(localized: "Preparing divine connection...")
                    self.downloadStage = String(localized: "Downloading \(activeModel.displayName) model")
                    self.downloadProgress = 0.0
                }
                
                
                await MainActor.run {
                    self.downloadProgress = 0.02
                }
                
                
                lastBytesDownloaded = 0
                lastUpdateTime = Date()
                lastKnownSpeed = 0.0
                downloadStartTime = Date()
                lastReportedProgress = 0.0
                progressHistory = []
                smoothedProgressValue = 0.0
                
                try await modelManager.downloadModel { [weak self] progress in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.handleProgressUpdate(progress.progress, estimatedTotalSize: estimatedTotalSize)
                    }
                }
                
                await MainActor.run {
                    self.downloadProgress = 1.0
                    self.downloadStatus = String(localized: "Download complete! Awakening the oracle...")
                    self.downloadStage = ""
                }
            }
            
            
            await MainActor.run {
                self.downloadStatus = String(localized: "Oracle awakening...")
            }
            
            try await modelManager.loadModel()
            
            await MainActor.run {
                isModelLoaded = true
                isModelLoading = false
                self.downloadStatus = ""
                self.downloadStage = ""
            }
        } catch {
            await MainActor.run {
                modelError = error.localizedDescription
                isModelLoading = false
                isModelLoaded = false
            }
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        guard let task = await MainActor.run(body: { startGeneration(for: text) }) else {
            MidgarLog.debug("Oracle send ignored: no deity selected or generation already in progress", category: .viewModel)
            return
        }

        await task.value
    }

    func selectDeity(_ deity: Deity) {

        guard deity.id != selectedDeity?.id else { return }

        cancelActiveGeneration()

        selectedDeity = deity

        messages.removeAll()

    }

    /// A cancelled stream the user already read still counts as a consultation,
    /// or switching deities mid-answer would make the free quota unlimited.
    private func cancelActiveGeneration() {
        if activeGenerationDelivered, let deityId = activeGenerationDeityId,
           let user = DatabaseManager.shared.fetchUser() {
            user.recordOracleConsultation(deityId: deityId)
        }
        activeGenerationDeityId = nil
        activeGenerationDelivered = false
        generationTask?.cancel()
        generationTask = nil
        activeGenerationID = nil
        if isGenerating {
            isGenerating = false
        }
    }
    
    
    
    private func checkAndAutoLoadModel() async {
        guard voice.engine == .gemma else { return }
        
        let wasLoadedBefore = UserDefaults.standard.bool(forKey: "MLXModelLoadedOnce")
        
        
        if isModelLoaded {
            return
        }
        
        
        let isDownloaded = await modelManager.isModelDownloaded
        if wasLoadedBefore && isDownloaded {
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
                }
            } catch {
                await MainActor.run {
                    modelError = String(localized: "Failed to auto-load model: \(error.localizedDescription)")
                    isModelLoading = false
                    downloadStatus = ""
                }
            }
        }
    }
    
    private func loadDeities() {
        guard let url = Bundle.main.url(forResource: "deity_prompts", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let deitiesData = try JSONDecoder().decode(DeitiesData.self, from: data)
            
            
            let deityArray = Array(deitiesData.deities.values)
            var validDeities: [Deity] = []
            
            for deity in deityArray {
                
                if !deity.id.isEmpty && !deity.name.isEmpty && !deity.color.isEmpty {
                    validDeities.append(deity)
                }
            }
            
            availableDeities = validDeities.sorted { $0.name < $1.name }
            selectedDeity = availableDeities.first
        } catch {
            
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
            "kali": "I am Kali, dancer upon the cremation grounds, destroyer of illusion. Through destruction comes liberation. What veils would you have me tear away?",
            "azrael": "In the name of the Most Merciful, I am Azrael, the Angel of Death. I separate souls with gentleness and grace. How may I ease your heart?",
            "meng_po": "Welcome, traveler. I am Meng Po, keeper of the Tea of Oblivion. I have watched countless souls cross the bridge of rebirth. What would you know?",
            "izanami": "From the shadows of Yomi, I am Izanami. Once I created life, now I rule the realm of death. What brings you to seek the Mother of Shadows?",
            "waheguru": "Waheguru's light shines through all. I speak with the voice of eternal wisdom. The cycle of birth and death is but illusion. What truth do you seek?",
            "ahura_mazda": "I am Ahura Mazda, Lord of Wisdom and Light. The battle between truth and lie shapes all destinies. Choose your thoughts, words, and deeds wisely.",
            "pachamama": "I am Pachamama, the Earth Mother. All that lives returns to me. Death is but transformation in the eternal dance of existence. What do you wish to understand?",
            "raven": "Caw! I am Raven, the trickster who stole the light. Death? Life? They're all part of the great joke! What riddle shall we unravel together?",
            "hecate": "By torch-light and moonbeam, I am Hecate of the Crossroads. I hold the keys to all mysteries. Which threshold do you wish to cross?",
            "michael": "I am Michael, Archangel of this age. I guide souls through the planetary spheres toward spiritual consciousness. What aspect of your journey concerns you?",
            "sophia": "I am Sophia, Divine Wisdom incarnate. I illuminate the path through all planes of existence. What knowledge of the eternal realms do you seek?",
            "emanuel": "Welcome to the spiritual world! I am your guide in Swedenborg's vision. Here, your inner state creates your reality. What would you discover?",
            "oyasama": "With a mother's love, I am Oyasama. Death is but a joyous return home. Let us speak of the Joyous Life and God's loving providence.",
            "the_eternal": "I AM THAT I AM. Known by countless names, I am the thread connecting all beliefs. In Me, all paths converge. What universal truth calls to you?"
        ]
        
        
        let greetingText = greetings[deity.id] ?? "I am \(deity.name), \(deity.role) of the \(deity.tradition) tradition. I am here to guide you. What would you like to know?"
        
        let message = ChatMessage(
            text: greetingText,
            isUser: false,
            deity: deity,
            timestamp: Date()
        )
        messages.append(message)
    }
    
    @MainActor
    private func startGeneration(for text: String) -> Task<Void, Never>? {
        guard !isGenerating, let deity = selectedDeity else { return nil }

        let userMessage = ChatMessage(
            text: text,
            isUser: true,
            deity: nil,
            timestamp: Date()
        )

        let placeholderMessage = ChatMessage(
            text: "",
            isUser: false,
            deity: deity,
            timestamp: Date()
        )

        isGenerating = true
        activeGenerationID = placeholderMessage.id
        activeGenerationDeityId = deity.id
        activeGenerationDelivered = false
        messages.append(userMessage)
        messages.append(placeholderMessage)

        let task = Task {
            await self.runGeneration(
                userMessage: text,
                deity: deity,
                generationID: placeholderMessage.id,
                placeholderTimestamp: placeholderMessage.timestamp
            )
        }
        generationTask = task
        return task
    }

    private func runGeneration(
        userMessage: String,
        deity: Deity,
        generationID: UUID,
        placeholderTimestamp: Date
    ) async {
        let history = await MainActor.run { conversationHistory(with: deity, excluding: generationID) }
        let grounding = OraclePrompt.grounding(deityId: deity.id, question: userMessage, systems: contentLoader.loadBeliefSystems())
        let instructions = OraclePrompt.instructions(
            persona: deity.systemPrompt,
            deityName: deity.name,
            grounding: grounding,
            mentionsSelfHarm: OraclePrompt.mentionsSelfHarm(userMessage)
        )
        let prompt = OraclePrompt.prompt(question: userMessage, history: history)
        do {
            var streamedResponse = ""
            for try await delta in voice.stream(instructions: instructions, prompt: prompt, temperature: 0.7, maxTokens: OracleTokenBudget.conversation) {
                try Task.checkCancellation()
                streamedResponse += delta
                let snapshot = streamedResponse
                await MainActor.run {
                    self.applyStreamedResponse(snapshot, generationID: generationID, deity: deity, timestamp: placeholderTimestamp)
                }
            }
            try Task.checkCancellation()
            let finalText = removeThinkTags(from: streamedResponse)
            guard !finalText.isEmpty else {
                await MainActor.run {
                    self.declineGeneration(generationID: generationID, deity: deity, question: userMessage)
                }
                return
            }
            await MainActor.run {
                self.completeGeneration(
                    generationID: generationID,
                    deity: deity,
                    timestamp: placeholderTimestamp,
                    finalText: finalText
                )
            }
        } catch is CancellationError {
            MidgarLog.debug("Oracle generation cancelled for deity \(deity.id)", category: .viewModel)
        } catch MidgarIntelligenceError.onDeviceRefused {
            MidgarLog.notice("Oracle model declined a question for \(deity.id)", category: .viewModel)
            await MainActor.run {
                self.declineGeneration(generationID: generationID, deity: deity, question: userMessage)
            }
        } catch {
            Diagnostics.logError(error, context: "Oracle generation", category: .mlx)
            await MainActor.run {
                self.failGeneration(generationID: generationID, deity: deity, error: error)
            }
        }
    }

    /// The finished exchanges with `deity` in this conversation, oldest first, for the model's short memory.
    @MainActor
    private func conversationHistory(with deity: Deity, excluding generationID: UUID) -> [OraclePrompt.Turn] {
        var turns: [OraclePrompt.Turn] = []
        var pendingQuestion: String?
        for message in messages where message.id != generationID && message.kind == .conversation {
            if message.isUser {
                pendingQuestion = message.text
            } else if let question = pendingQuestion, message.deity?.id == deity.id, !message.text.isEmpty {
                turns.append(OraclePrompt.Turn(question: question, answer: message.text))
                pendingQuestion = nil
            }
        }
        return turns
    }

    /// The model would not answer. The persona stays silent in character, and nothing is counted; a question that
    /// touched on suicide gets the app's care and the helpline instead of silence.
    @MainActor
    private func declineGeneration(generationID: UUID, deity: Deity, question: String) {
        guard activeGenerationID == generationID else { return }
        if OraclePrompt.mentionsSelfHarm(question) {
            replaceMessage(id: generationID, with: ChatMessage(id: generationID, text: CompassionGuard.message, isUser: false, deity: nil, timestamp: Date(), kind: .care))
        } else {
            replaceMessage(id: generationID, with: ChatMessage(
                id: generationID,
                text: String(localized: "\(deity.name) is silent on this. Ask it another way."),
                isUser: false,
                deity: deity,
                timestamp: Date(),
                kind: .notice
            ))
        }
        activeGenerationID = nil
        activeGenerationDeityId = nil
        activeGenerationDelivered = false
        generationTask = nil
        isGenerating = false
    }

    @MainActor
    private func applyStreamedResponse(_ rawResponse: String, generationID: UUID, deity: Deity, timestamp: Date) {
        guard activeGenerationID == generationID else { return }
        guard !rawResponse.contains("<think>") || rawResponse.contains("</think>") else { return }

        let cleanedResponse = removeThinkTags(from: rawResponse)
        guard !cleanedResponse.isEmpty else { return }

        activeGenerationDelivered = true
        updateGeneratedMessage(id: generationID, text: cleanedResponse, deity: deity, timestamp: timestamp)
    }

    @MainActor
    private func completeGeneration(generationID: UUID, deity: Deity, timestamp: Date, finalText: String) {
        guard activeGenerationID == generationID else { return }

        updateGeneratedMessage(
            id: generationID,
            text: finalText.trimmingCharacters(in: .whitespacesAndNewlines),
            deity: deity,
            timestamp: timestamp
        )
        recordSuccessfulConsultation(deityId: deity.id)
        AppFunnel.note(.oracleAnswered)
        activeGenerationID = nil
        activeGenerationDeityId = nil
        activeGenerationDelivered = false
        generationTask = nil
        isGenerating = false
    }

    @MainActor
    private func failGeneration(generationID: UUID, deity: Deity, error: Error) {
        guard activeGenerationID == generationID else { return }
        replaceMessage(id: generationID, with: ChatMessage(
            id: generationID,
            text: String(localized: "I apologize, but I'm having trouble connecting to the divine realm. Please try again."),
            isUser: false,
            deity: deity,
            timestamp: Date(),
            kind: .notice
        ))
        modelError = error.localizedDescription
        activeGenerationID = nil
        activeGenerationDeityId = nil
        activeGenerationDelivered = false
        generationTask = nil
        isGenerating = false
    }

    @MainActor
    private func replaceMessage(id: UUID, with message: ChatMessage) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index] = message
    }

    @MainActor
    private func updateGeneratedMessage(id: UUID, text: String, deity: Deity, timestamp: Date) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }

        messages[index] = ChatMessage(
            id: id,
            text: text,
            isUser: false,
            deity: deity,
            timestamp: timestamp
        )
    }

    @MainActor
    private func recordSuccessfulConsultation(deityId: String) {
        guard let user = DatabaseManager.shared.fetchUser() else {
            MidgarLog.error("Cannot record Oracle consultation: no user found", category: .viewModel)
            return
        }
        user.recordOracleConsultation(deityId: deityId)
    }
    
    private func removeThinkTags(from text: String) -> String {
        
        let pattern = "<think>.*?</think>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let regex = regex {
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return text
    }
    
    
    
    private func smoothProgress(current: Float, last: Float) -> Float {
        
        if current <= last {
            return min(last + 0.001, 0.99) 
        }
        
        
        let maxJump: Float = 0.05 
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
    
    
    
    private struct DeitiesData: Codable {
        let deities: [String: Deity]
    }
    
    
    
    private func handleProgressUpdate(_ reportedProgress: Float, estimatedTotalSize: Int64) {
        let currentTime = Date()
        
        
        progressHistory.append((time: currentTime, progress: reportedProgress))
        
        
        progressHistory = progressHistory.filter { currentTime.timeIntervalSince($0.time) < 10 }
        
        
        if reportedProgress > lastReportedProgress {
            lastReportedProgress = reportedProgress
            startSmoothProgressAnimation(to: reportedProgress, estimatedTotalSize: estimatedTotalSize)
        }
        
        updateProgressUI(estimatedTotalSize: estimatedTotalSize)
    }
    
    private func startSmoothProgressAnimation(to targetProgress: Float, estimatedTotalSize: Int64) {
        
        progressAnimator?.invalidate()
        
        let startProgress = smoothedProgressValue
        let progressDelta = targetProgress - startProgress
        let animationDuration: TimeInterval = 2.0 
        let updateInterval: TimeInterval = 0.05 
        let totalSteps = Int(animationDuration / updateInterval)
        var currentStep = 0
        
        progressAnimator = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            if currentStep >= totalSteps {
                Task { @MainActor in
                    self.smoothedProgressValue = targetProgress
                    self.progressAnimator = nil
                    self.updateProgressUI(estimatedTotalSize: estimatedTotalSize)
                }
                timer.invalidate()
            } else {
                
                let t = Float(currentStep) / Float(totalSteps)
                let easedT = 1 - pow(1 - t, 3) 
                
                Task { @MainActor in
                    self.smoothedProgressValue = startProgress + progressDelta * easedT
                    self.updateProgressUI(estimatedTotalSize: estimatedTotalSize)
                }
            }
        }
    }
    
    private func updateProgressUI(estimatedTotalSize: Int64) {
        
        downloadProgress = smoothedProgressValue
        
        
        let totalBytes = estimatedTotalSize
        let bytesDownloaded = Int64(Double(estimatedTotalSize) * Double(smoothedProgressValue))
        
        
        let downloadedMB = Double(bytesDownloaded) / (1024 * 1024)
        let totalGB = Double(totalBytes) / (1024 * 1024 * 1024)
        
        
        let progressPercent = Int(smoothedProgressValue * 100)
        if progressPercent < 10 {
            downloadStatus = String(localized: "Gathering sacred texts...")
        } else if progressPercent < 30 {
            downloadStatus = String(localized: "Channeling divine wisdom...")
        } else if progressPercent < 50 {
            downloadStatus = String(localized: "Deciphering ancient knowledge...")
        } else if progressPercent < 70 {
            downloadStatus = String(localized: "Binding ethereal essence...")
        } else if progressPercent < 90 {
            downloadStatus = String(localized: "Preparing the Oracle...")
        } else {
            downloadStatus = String(localized: "Finalizing divine connection...")
        }
        
        
        downloadStage = String(format: "%.0f MB / %.1f GB", downloadedMB, totalGB)
        
        
        if smoothedProgressValue >= 0.99 && lastReportedProgress >= 1.0 {
            progressAnimator?.invalidate()
            progressAnimator = nil
            downloadProgress = 1.0
            downloadStatus = String(localized: "Download complete! Awakening the oracle...")
            downloadStage = ""
        }
    }
}
