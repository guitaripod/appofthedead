import XCTest
@testable import aotd

final class HFModelManifestTests: XCTestCase {

    func testParseFiltersToGlobAndExtractsLFSsha() {
        let entries: [[String: Any]] = [
            ["type": "file", "path": "model.safetensors", "size": 100, "lfs": ["oid": "abc123", "size": NSNumber(value: 3_581_101_896 as Int64)]],
            ["type": "file", "path": "config.json", "size": 42],
            ["type": "file", "path": "tokenizer.json", "size": 10, "lfs": ["oid": "def456", "size": NSNumber(value: 32_169_626 as Int64)]],
            ["type": "file", "path": "chat_template.jinja", "size": 5],
            ["type": "file", "path": "README.md", "size": 999],
            ["type": "file", "path": ".gitattributes", "size": 3],
            ["type": "directory", "path": "subdir"]
        ]
        let files = HFModelManifest.parse(entries: entries)
        XCTAssertEqual(Set(files.map(\.path)), ["model.safetensors", "config.json", "tokenizer.json", "chat_template.jinja"])

        let safetensors = files.first { $0.path == "model.safetensors" }!
        XCTAssertEqual(safetensors.sha256, "abc123")
        XCTAssertEqual(safetensors.size, 3_581_101_896)
        XCTAssertTrue(safetensors.isLFS)

        let config = files.first { $0.path == "config.json" }!
        XCTAssertNil(config.sha256)
        XCTAssertFalse(config.isLFS)
    }

    func testManifestTotalBytesSumsAllFiles() {
        let files = [
            HFFile(path: "a.safetensors", size: 1000, sha256: "x"),
            HFFile(path: "b.json", size: 24, sha256: nil)
        ]
        let manifest = HFManifest(repo: "mlx-community/gemma-4-e2b-it-4bit", commit: "c", files: files)
        XCTAssertEqual(manifest.totalBytes, 1024)
    }

    func testResolveURLIsCommitPinned() {
        let manifest = HFManifest(repo: "mlx-community/gemma-4-e2b-it-4bit", commit: "2c3e507", files: [])
        let url = manifest.resolveURL(for: HFFile(path: "model.safetensors", size: 1, sha256: nil))
        XCTAssertEqual(url?.absoluteString,
                       "https://huggingface.co/mlx-community/gemma-4-e2b-it-4bit/resolve/2c3e507/model.safetensors")
    }

    func testSHA256MatchesKnownVector() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("abc".utf8).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let digest = try BackgroundModelDownloader.sha256(of: tmp)
        XCTAssertEqual(digest, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testSafetensorsHeaderValidationAcceptsValid() throws {
        let header = Data("{\"__metadata__\":{}}".utf8)
        var len = UInt64(header.count).littleEndian
        var data = Data(bytes: &len, count: 8)
        data.append(header)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".safetensors")
        try data.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }
        XCTAssertNoThrow(try BackgroundModelDownloader.validateSafetensorsHeader(at: tmp))
    }

    func testSafetensorsHeaderValidationRejectsTruncated() throws {
        var len = UInt64(100_000).littleEndian
        let data = Data(bytes: &len, count: 8)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".safetensors")
        try data.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }
        XCTAssertThrowsError(try BackgroundModelDownloader.validateSafetensorsHeader(at: tmp))
    }
}
