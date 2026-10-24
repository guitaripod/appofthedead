import Foundation

/// Reads the public HuggingFace model API with the shared URL session. Only a 200 response yields data; any other status throws ``HFModelManifestError/badResponse(_:)``.
nonisolated struct HuggingFaceClient: Sendable {
    func modelInfo(repo: String) async throws -> Data {
        try await get(URL(string: "https://huggingface.co/api/models/\(repo)")!)
    }

    func modelTree(repo: String, commit: String) async throws -> Data {
        try await get(URL(string: "https://huggingface.co/api/models/\(repo)/tree/\(commit)?recursive=true&expand=true")!)
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else { throw HFModelManifestError.badResponse(code) }
        return data
    }
}
