import Foundation

public struct Deity: Codable, Sendable {
    public let id: String
    public let name: String
    public let tradition: String
    public let role: String
    public let avatar: String
    public let color: String
    public let systemPrompt: String
}
