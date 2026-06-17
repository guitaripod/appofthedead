import Foundation

struct HFFile: Sendable, Equatable {
    let path: String
    let size: Int64
    /// The Git-LFS object id, which for HuggingFace LFS files is the SHA-256 of the
    /// content — used for integrity verification. `nil` for small non-LFS files (JSON).
    let sha256: String?

    var isLFS: Bool { sha256 != nil }
}

struct HFManifest: Sendable {
    let repo: String
    let commit: String
    let files: [HFFile]

    var totalBytes: Int64 { files.reduce(0) { $0 + $1.size } }

    func resolveURL(for file: HFFile) -> URL? {
        let encoded = file.path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "https://huggingface.co/\(repo)/resolve/\(commit)/\(encoded)")
    }
}

enum HFModelManifestError: LocalizedError {
    case badResponse(Int)
    case noCommit
    case emptyManifest

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "HuggingFace returned HTTP \(code)."
        case .noCommit: return "Could not resolve the model revision."
        case .emptyManifest: return "The model manifest was empty."
        }
    }
}

/// Resolves a HuggingFace model repo to a commit-pinned manifest of the files an
/// MLX model needs (matching mlx-swift-lm's `*.safetensors / *.json / *.jinja` glob),
/// with exact sizes (for true progress) and SHA-256 (for integrity).
enum HFModelManifest {
    static let keepSuffixes = [".safetensors", ".json", ".jinja"]

    static func fetch(repo: String) async throws -> HFManifest {
        let commit = try await resolveCommit(repo: repo)
        let files = try await fetchTree(repo: repo, commit: commit)
        guard !files.isEmpty else { throw HFModelManifestError.emptyManifest }
        return HFManifest(repo: repo, commit: commit, files: files)
    }

    static func resolveCommit(repo: String) async throws -> String {
        let url = URL(string: "https://huggingface.co/api/models/\(repo)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else { throw HFModelManifestError.badResponse(code) }
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let sha = object?["sha"] as? String, !sha.isEmpty else { throw HFModelManifestError.noCommit }
        return sha
    }

    static func fetchTree(repo: String, commit: String) async throws -> [HFFile] {
        let url = URL(string: "https://huggingface.co/api/models/\(repo)/tree/\(commit)?recursive=true&expand=true")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else { throw HFModelManifestError.badResponse(code) }
        let entries = (try JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return parse(entries: entries)
    }

    static func parse(entries: [[String: Any]]) -> [HFFile] {
        var files: [HFFile] = []
        for entry in entries {
            guard (entry["type"] as? String) == "file",
                  let path = entry["path"] as? String,
                  keepSuffixes.contains(where: { path.hasSuffix($0) }) else { continue }

            var size = (entry["size"] as? NSNumber)?.int64Value ?? 0
            var sha: String?
            if let lfs = entry["lfs"] as? [String: Any] {
                sha = (lfs["oid"] as? String) ?? (lfs["sha256"] as? String)
                if let lfsSize = (lfs["size"] as? NSNumber)?.int64Value, lfsSize > 0 { size = lfsSize }
            }
            files.append(HFFile(path: path, size: size, sha256: sha))
        }
        return files
    }
}
