import Foundation

// MARK: - Tokenizer Configuration

struct TokenizerConfig: Codable {
    let modelMaxLength: Int
    let padTokenId: Int?
    let eosTokenId: Int
    let bosTokenId: Int?
    
    enum CodingKeys: String, CodingKey {
        case modelMaxLength = "model_max_length"
        case padTokenId = "pad_token_id"
        case eosTokenId = "eos_token_id"
        case bosTokenId = "bos_token_id"
    }
    
    static func load(at directory: URL) throws -> TokenizerConfig {
        let configURL = directory.appendingPathComponent("tokenizer_config.json")
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(TokenizerConfig.self, from: data)
    }
}

// MARK: - Simple Tokenizer

class Tokenizer {
    private let config: TokenizerConfig
    private var vocabulary: [String: Int] = [:]
    private var reverseVocabulary: [Int: String] = [:]
    
    var eosTokenId: Int {
        config.eosTokenId
    }
    
    var bosTokenId: Int? {
        config.bosTokenId
    }
    
    var padTokenId: Int? {
        config.padTokenId
    }
    
    init(config: TokenizerConfig) throws {
        self.config = config
        
        // Initialize with a basic vocabulary for demonstration
        // In production, this would load from tokenizer.json
        initializeBasicVocabulary()
    }
    
    private func initializeBasicVocabulary() {
        // Special tokens
        vocabulary["<|im_start|>"] = 0
        vocabulary["<|im_end|>"] = 1
        vocabulary["<|endoftext|>"] = 2
        vocabulary["<pad>"] = 3
        
        // Common words and subwords
        let commonTokens = [
            "▁the", "▁of", "▁and", "▁to", "▁a", "▁in", "▁that", "▁is",
            "▁for", "▁it", "▁with", "▁as", "▁was", "▁on", "▁be", "▁by",
            "▁at", "▁from", "▁have", "▁or", "▁had", "▁but", "▁not", "▁are",
            "▁this", "▁which", "▁an", "▁were", "▁been", "▁their", "▁has",
            "▁would", "▁what", "▁will", "▁there", "▁can", "▁if", "▁more",
            "▁when", "▁who", "▁so", "▁no", "▁out", "▁up", "▁said", "▁than",
            "▁its", "▁about", "▁into", "▁them", "▁some", "▁time", "▁only",
            "▁new", "▁could", "▁these", "▁may", "▁then", "▁do", "▁first",
            "▁any", "▁my", "▁now", "▁such", "▁like", "▁other", "▁how",
            "▁after", "▁all", "▁should", "▁well", "▁because", "▁just",
            "▁Hello", "▁from", "▁deity", "!", ".", ",", "?", ":", ";",
            "▁I", "▁am", "▁you", "▁soul", "▁death", "▁life", "▁afterlife",
            "▁wisdom", "▁seek", "▁guide", "▁divine", "▁mortal", "▁eternal"
        ]
        
        var tokenId = 4
        for token in commonTokens {
            vocabulary[token] = tokenId
            tokenId += 1
        }
        
        // Build reverse vocabulary
        for (token, id) in vocabulary {
            reverseVocabulary[id] = token
        }
    }
    
    func encode(_ text: String) throws -> [Int] {
        // Simple whitespace tokenization with SentencePiece-style prefix
        var tokens: [Int] = []
        
        // Add BOS token if configured
        if let bosId = bosTokenId {
            tokens.append(bosId)
        }
        
        // Split by whitespace and encode
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for (index, word) in words.enumerated() {
            if word.isEmpty { continue }
            
            // Add SentencePiece prefix for non-first words
            let tokenWord = index == 0 ? word : "▁" + word
            
            if let tokenId = vocabulary[tokenWord] {
                tokens.append(tokenId)
            } else {
                // Fallback: encode character by character
                for char in word {
                    let charStr = String(char)
                    if let tokenId = vocabulary[charStr] {
                        tokens.append(tokenId)
                    } else {
                        // Unknown token - use a default
                        tokens.append(vocabulary.count)
                    }
                }
            }
        }
        
        return tokens
    }
    
    func decode(_ tokenIds: [Int]) throws -> String {
        var text = ""
        
        for tokenId in tokenIds {
            // Skip special tokens
            if tokenId == eosTokenId || tokenId == bosTokenId || tokenId == padTokenId {
                continue
            }
            
            if let token = reverseVocabulary[tokenId] {
                // Remove SentencePiece prefix and add space if needed
                if token.hasPrefix("▁") {
                    if !text.isEmpty {
                        text += " "
                    }
                    text += String(token.dropFirst())
                } else if token.hasPrefix("<|") && token.hasSuffix("|>") {
                    // Skip special tokens
                    continue
                } else {
                    text += token
                }
            }
        }
        
        return text.trimmingCharacters(in: .whitespaces)
    }
}