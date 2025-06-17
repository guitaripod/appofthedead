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
        // Generate contextual demo responses based on keywords
        let lowercasedPrompt = prompt.lowercased()
        
        if lowercasedPrompt.contains("hello") || lowercasedPrompt.contains("hi") {
            return tokenize("Greetings, mortal soul. Your presence here speaks of questions that weigh upon your heart. What mysteries of the eternal realm do you seek to understand?")
        } else if lowercasedPrompt.contains("afterlife") || lowercasedPrompt.contains("death") {
            return tokenize("The veil between life and death is but a threshold, not an ending. Each tradition holds its own sacred truths about what awaits beyond. The journey of the soul continues in ways both mysterious and profound.")
        } else if lowercasedPrompt.contains("fear") || lowercasedPrompt.contains("afraid") {
            return tokenize("Fear is the shadow cast by the unknown. Yet know this - death is not your enemy, but a transformation. Like the caterpillar entering the chrysalis, what seems like an ending is but the beginning of a new form of existence.")
        } else if lowercasedPrompt.contains("purpose") || lowercasedPrompt.contains("meaning") {
            return tokenize("Every soul carries a divine spark, a purpose that transcends mortal understanding. Your journey through life shapes your eternal essence. The meaning you seek is written in the very fabric of your being.")
        } else if lowercasedPrompt.contains("loved ones") || lowercasedPrompt.contains("family") {
            return tokenize("Love transcends the boundaries of mortality. Those who have passed before you are not lost - they await in realms beyond the veil. The bonds of the heart are eternal, unbroken by death's transition.")
        } else {
            return tokenize("Your question touches upon mysteries that have captivated souls throughout the ages. The divine wisdom speaks differently to each seeker. Tell me more of what troubles your spirit, and I shall illuminate the path.")
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