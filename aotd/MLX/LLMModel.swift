import Foundation
import MLX
import MLXNN

// MARK: - LLM Model Configuration

struct LLMModelConfiguration: Codable {
    let modelType: String
    let vocabSize: Int
    let hiddenSize: Int
    let numHiddenLayers: Int
    let numAttentionHeads: Int
    let intermediateSize: Int
    let maxPositionEmbeddings: Int
    let rmsNormEps: Float
    let ropeTheta: Float
    let tieWordEmbeddings: Bool
    
    enum CodingKeys: String, CodingKey {
        case modelType = "model_type"
        case vocabSize = "vocab_size"
        case hiddenSize = "hidden_size"
        case numHiddenLayers = "num_hidden_layers"
        case numAttentionHeads = "num_attention_heads"
        case intermediateSize = "intermediate_size"
        case maxPositionEmbeddings = "max_position_embeddings"
        case rmsNormEps = "rms_norm_eps"
        case ropeTheta = "rope_theta"
        case tieWordEmbeddings = "tie_word_embeddings"
    }
}

// MARK: - LLM Model

class LLMModel {
    private let embedTokens: Embedding
    private let layers: [TransformerBlock]
    private let norm: RMSNorm
    private let lmHead: Linear?
    
    private let config: LLMModelConfiguration
    
    init(configuration: LLMModelConfiguration) throws {
        self.config = configuration
        
        // Token embeddings
        self.embedTokens = Embedding(
            embeddingCount: configuration.vocabSize,
            dimensions: configuration.hiddenSize
        )
        
        // Transformer layers
        self.layers = (0..<configuration.numHiddenLayers).map { _ in
            TransformerBlock(
                dimensions: configuration.hiddenSize,
                numHeads: configuration.numAttentionHeads,
                mlpDimensions: configuration.intermediateSize,
                rmsNormEps: configuration.rmsNormEps
            )
        }
        
        // Final normalization
        self.norm = RMSNorm(
            dimensions: configuration.hiddenSize,
            eps: configuration.rmsNormEps
        )
        
        // Language modeling head
        if !configuration.tieWordEmbeddings {
            self.lmHead = Linear(
                configuration.hiddenSize,
                configuration.vocabSize,
                bias: false
            )
        } else {
            self.lmHead = nil
        }
    }
    
    func callAsFunction(_ input: MLXArray) -> MLXArray {
        // Token embeddings
        var hidden = embedTokens(input)
        
        // Pass through transformer layers
        for layer in layers {
            hidden = layer(hidden)
        }
        
        // Final norm
        hidden = norm(hidden)
        
        // Language modeling head
        if let lmHead = lmHead {
            return lmHead(hidden)
        } else {
            // Tied embeddings - use embedding matrix as output
            // In a real implementation, this would properly handle tied embeddings
            return hidden
        }
    }
    
    func loadWeights(from directory: URL) throws {
        // In a real implementation, this would load the weights
        // For demo purposes, we'll skip this
    }
    
    // MARK: - Generation
    
    func generate(
        prompt: String,
        parameters: GenerateParameters
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // For demonstration, generate contextual responses
                    let responses = self.generateDemoResponse(for: prompt)
                    
                    // Stream tokens with realistic timing
                    for token in responses {
                        continuation.yield(token)
                        // Variable delay for more natural feel
                        let delay = UInt64.random(in: 20_000_000...80_000_000)
                        try await Task.sleep(nanoseconds: delay)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func generateDemoResponse(for prompt: String) -> [String] {
        // Generate contextual demo responses based on the full prompt including system message
        print("[LLMModel] Generating demo response for prompt: \(prompt.prefix(100))...")
        
        let lowercasedPrompt = prompt.lowercased()
        
        // Parse deity from system prompt to customize response
        var responseStyle = "general"
        if lowercasedPrompt.contains("anubis") {
            responseStyle = "egyptian"
        } else if lowercasedPrompt.contains("hermes") {
            responseStyle = "greek"
        } else if lowercasedPrompt.contains("gabriel") {
            responseStyle = "abrahamic"
        } else if lowercasedPrompt.contains("yama") {
            responseStyle = "hindu"
        } else if lowercasedPrompt.contains("baron samedi") {
            responseStyle = "vodou"
        } else if lowercasedPrompt.contains("odin") {
            responseStyle = "norse"
        }
        
        // Extract user message (after "<|im_start|>user")
        let userPart = prompt.components(separatedBy: "<|im_start|>user").last ?? prompt
        let userMessage = userPart.components(separatedBy: "<|im_end|>").first ?? userPart
        let userLower = userMessage.lowercased()
        
        print("[LLMModel] User message: \(userMessage)")
        print("[LLMModel] Response style: \(responseStyle)")
        
        // Generate contextual responses
        if userLower.contains("hello") || userLower.contains("hi") || userLower.contains("greetings") {
            switch responseStyle {
            case "egyptian":
                return tokenize("Welcome, living one. I am the guardian who weighs hearts against the feather of Ma'at. Your ka has guided you well to seek wisdom here. What questions about the journey through the Duat trouble your ba?")
            case "greek":
                return tokenize("Ah, a living soul seeks the messenger! Swift as thought, I travel between Olympus and Hades. I've guided countless souls across the river Styx. What news from the mortal realm do you bring, or what mysteries of the underworld intrigue you?")
            case "vodou":
                return tokenize("*laughs deeply* Well, well! Another soul finds their way to Baron Samedi! You smell of life, child - that's good rum and cigars to me! The crossroads brought you here for a reason. What's on your mind about the other side, hmm?")
            default:
                return tokenize("Greetings, seeker. The veil between worlds grows thin when mortals seek divine wisdom. I sense questions within your heart about the mysteries beyond. Share what weighs upon your soul.")
            }
        } else if userLower.contains("afterlife") || userLower.contains("death") || userLower.contains("die") {
            switch responseStyle {
            case "egyptian":
                return tokenize("The afterlife is not a single destination but a journey through the Duat. Your heart will be weighed, your deeds measured. Those who lived in accordance with Ma'at find their way to the Field of Reeds, where eternal peace awaits. The journey requires passwords, spells from the Book of the Dead, and courage to face the trials.")
            case "hindu":
                return tokenize("Death is but a door, not a wall. The atman - your eternal soul - sheds the body like worn clothing. Based on your karma, you may ascend to higher lokas, return to earthly form, or achieve moksha - liberation from the cycle entirely. Each life is a classroom, each death a graduation.")
            case "norse":
                return tokenize("The afterlife depends on how you meet your end. Warriors who die bravely in battle are chosen by my Valkyries for Valhalla, where they feast and fight until Ragnarok. Those who die of age or illness go to Helheim - not a place of punishment, but of rest. The manner of death matters as much as the manner of life.")
            default:
                return tokenize("Death is transformation, not termination. Each tradition sees it differently - some as judgment, others as liberation, many as continuation. The soul's journey beyond depends on beliefs held, deeds done, and the love shared. What aspect of this transition concerns you most?")
            }
        } else if userLower.contains("fear") || userLower.contains("afraid") || userLower.contains("scared") {
            switch responseStyle {
            case "egyptian":
                return tokenize("Fear of death is fear of judgment, but remember - I do not judge alone. Your own heart testifies for or against you. Live with Ma'at - truth, justice, harmony - and you need not fear the scales. The truly terrifying fate is to be devoured by Ammit and cease to exist. But this befalls only those whose hearts are heavy with unrepented evil.")
            case "vodou":
                return tokenize("*chuckles* Afraid of old Baron? That's wise and foolish both! Death is my realm, yes, but I'm also the life of the party! Fear keeps you respectful, but too much fear makes you forget to live. The dead I watch over - they're not suffering. They dance with the Gede, they guide their families. Death is just moving to a different neighborhood, child.")
            default:
                return tokenize("Fear serves as a teacher, pointing to what we value most. The fear of death often masks the fear of an unlived life. In my eternal perspective, I see that those who embrace mortality's lessons live most fully. What specifically about the transition frightens you? Let us examine it together.")
            }
        } else if userLower.contains("loved one") || userLower.contains("family") || userLower.contains("miss") || userLower.contains("grief") {
            switch responseStyle {
            case "egyptian":
                return tokenize("Those who have crossed into the West are not lost. In the Field of Reeds, they exist in perfection, their ka sustained by offerings and remembrance. When you speak their names, they live. When you leave offerings, they receive them. The bond between the living and the justified dead remains strong across the veil.")
            case "abrahamic":
                return tokenize("I have carried many messages between the grieving and the departed. Know that love is eternal - it exists beyond physical presence. Those who rest in divine grace watch over you still. Your prayers reach them, and their love surrounds you like light. Reunion awaits in the fullness of time, when all tears shall be wiped away.")
            default:
                return tokenize("Grief is love with nowhere to go, but the departed are closer than you think. They exist in memories shared, in values passed down, in the love that continues to shape your life. Different traditions promise different reunions, but all agree - the bonds of love transcend death's boundary.")
            }
        } else {
            // Default responses for other topics
            switch responseStyle {
            case "egyptian":
                return tokenize("Speak freely, living one. I have stood at the threshold between life and death since time immemorial. Whether you seek to understand the weighing of hearts, the journey through the Duat, or the mysteries of eternal existence, I shall guide you with the wisdom of ancient Kemet.")
            case "greek":
                return tokenize("Interesting question! As one who flies between all realms, I've seen much. The gods have their secrets, the dead their stories, and mortals their concerns. I'm here to bridge these worlds. Tell me more about what you seek to understand.")
            case "hindu":
                return tokenize("Your question opens many paths of understanding. As the first to die and thus lord over all who follow, I've witnessed the great wheel of samsara turn countless times. Share more of your thoughts, and I shall illuminate the dharmic wisdom you seek.")
            default:
                return tokenize("Your words carry the weight of genuine seeking. In my realm beyond mortal time, I've gathered wisdom from countless souls and traditions. Please, elaborate on your thoughts, and I shall share what insights the eternal perspective can offer.")
            }
        }
    }
    
    private func tokenize(_ text: String) -> [String] {
        // Simple word-level tokenization for demo
        var tokens: [String] = []
        let words = text.components(separatedBy: .whitespaces)
        
        for word in words {
            // Split punctuation for more natural streaming
            if let lastChar = word.last,
               [".", ",", "?", "!", ":", ";"].contains(lastChar) {
                tokens.append(String(word.dropLast()))
                tokens.append(String(lastChar))
            } else {
                tokens.append(word)
            }
            tokens.append(" ")
        }
        
        // Remove last space
        if tokens.last == " " {
            tokens.removeLast()
        }
        
        return tokens
    }
}

// MARK: - Transformer Block

class TransformerBlock {
    private let selfAttn: MultiHeadAttention
    private let mlp: MLP
    private let inputLayerNorm: RMSNorm
    private let postAttentionLayerNorm: RMSNorm
    
    init(
        dimensions: Int,
        numHeads: Int,
        mlpDimensions: Int,
        rmsNormEps: Float
    ) {
        self.selfAttn = MultiHeadAttention(
            dimensions: dimensions,
            numHeads: numHeads
        )
        
        self.mlp = MLP(
            dimensions: dimensions,
            hiddenDimensions: mlpDimensions
        )
        
        self.inputLayerNorm = RMSNorm(
            dimensions: dimensions,
            eps: rmsNormEps
        )
        
        self.postAttentionLayerNorm = RMSNorm(
            dimensions: dimensions,
            eps: rmsNormEps
        )
    }
    
    func callAsFunction(_ input: MLXArray) -> MLXArray {
        // Self attention with residual
        let normedInput = inputLayerNorm(input)
        let attnOutput = selfAttn(normedInput)
        var hidden = input + attnOutput
        
        // MLP with residual
        let normedHidden = postAttentionLayerNorm(hidden)
        let mlpOutput = mlp(normedHidden)
        hidden = hidden + mlpOutput
        
        return hidden
    }
}

// MARK: - Multi-Head Attention

class MultiHeadAttention {
    private let numHeads: Int
    private let dimensions: Int
    private let headDim: Int
    
    private let qProj: Linear
    private let kProj: Linear
    private let vProj: Linear
    private let oProj: Linear
    
    init(dimensions: Int, numHeads: Int) {
        self.dimensions = dimensions
        self.numHeads = numHeads
        self.headDim = dimensions / numHeads
        
        self.qProj = Linear(dimensions, dimensions, bias: false)
        self.kProj = Linear(dimensions, dimensions, bias: false)
        self.vProj = Linear(dimensions, dimensions, bias: false)
        self.oProj = Linear(dimensions, dimensions, bias: false)
    }
    
    func callAsFunction(_ input: MLXArray) -> MLXArray {
        let batchSize = input.dim(0)
        let seqLen = input.dim(1)
        
        // Project to Q, K, V
        var q = qProj(input)
        var k = kProj(input)
        var v = vProj(input)
        
        // Reshape for multi-head attention
        q = q.reshaped([batchSize, seqLen, numHeads, headDim]).transposed(1, 2)
        k = k.reshaped([batchSize, seqLen, numHeads, headDim]).transposed(1, 2)
        v = v.reshaped([batchSize, seqLen, numHeads, headDim]).transposed(1, 2)
        
        // Scaled dot-product attention
        let scale = 1.0 / sqrt(Float(headDim))
        var scores = (q.matmul(k.transposed(-2, -1))) * scale
        
        // Apply causal mask (simplified for demo)
        // In production, you would implement proper causal masking
        
        // Softmax
        let attnWeights = MLX.softmax(scores, axis: -1)
        
        // Apply attention to values
        var output = attnWeights.matmul(v)
        
        // Reshape back
        output = output.transposed(1, 2).reshaped([batchSize, seqLen, dimensions])
        
        // Output projection
        return oProj(output)
    }
}

// MARK: - MLP

class MLP {
    private let gateProj: Linear
    private let upProj: Linear
    private let downProj: Linear
    
    init(dimensions: Int, hiddenDimensions: Int) {
        self.gateProj = Linear(dimensions, hiddenDimensions, bias: false)
        self.upProj = Linear(dimensions, hiddenDimensions, bias: false)
        self.downProj = Linear(hiddenDimensions, dimensions, bias: false)
    }
    
    func callAsFunction(_ input: MLXArray) -> MLXArray {
        let gate = gateProj(input)
        let up = upProj(input)
        // SiLU activation: x * sigmoid(x)
        let sigmoid = MLX.sigmoid(gate)
        let hidden = gate * sigmoid * up
        return downProj(hidden)
    }
}

// MARK: - RMS Norm

class RMSNorm {
    private let weight: MLXArray
    private let eps: Float
    
    init(dimensions: Int, eps: Float = 1e-6) {
        self.weight = MLXArray.ones([dimensions])
        self.eps = eps
    }
    
    func callAsFunction(_ input: MLXArray) -> MLXArray {
        let variance = input.pow(2).mean(axis: -1, keepDims: true)
        let normed = input * MLX.rsqrt(variance + eps)
        return normed * weight
    }
}