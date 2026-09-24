import Foundation

/// Append-only diagnostics file in `Library/Logs`, rotated to a single previous file once it
/// passes `maxBytes`, so logs can be pulled off a device without Xcode attached.
final class LogFileWriter: @unchecked Sendable {
    static let shared = LogFileWriter(maxBytes: 2 * 1024 * 1024)

    private let queue = DispatchQueue(label: "aotd.LogFileWriter", qos: .utility)
    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let pid = ProcessInfo.processInfo.processIdentifier
    private let maxBytes: UInt64
    let currentURL: URL
    let previousURL: URL
    private var handle: FileHandle?

    init(maxBytes: UInt64, directory: URL? = nil) {
        self.maxBytes = maxBytes
        let logsDir = directory ?? Self.defaultDirectory()
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        self.currentURL = logsDir.appendingPathComponent("aotd.log")
        self.previousURL = logsDir.appendingPathComponent("aotd.previous.log")
    }

    func append(level: String, category: String, message: String) {
        let stamp = dateFormatter.string(from: Date())
        let lvl = level.padding(toLength: 5, withPad: " ", startingAt: 0)
        let cat = category.padding(toLength: 12, withPad: " ", startingAt: 0)
        let line = "\(stamp) [\(pid)] [\(lvl)] [\(cat)] \(message)\n"
        queue.async { [weak self] in self?.write(line) }
    }

    func snapshot() -> URL? {
        FileManager.default.fileExists(atPath: currentURL.path) ? currentURL : nil
    }

    /// Blocks until every line appended so far has reached the file.
    func flush() {
        queue.sync {}
    }

    func clear() {
        queue.async { [weak self] in
            guard let self else { return }
            try? self.handle?.close()
            self.handle = nil
            try? FileManager.default.removeItem(at: self.currentURL)
            try? FileManager.default.removeItem(at: self.previousURL)
        }
    }

    private static func defaultDirectory() -> URL {
        let libDir = (try? FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory
        return libDir.appendingPathComponent("Logs", isDirectory: true)
    }

    private func write(_ line: String) {
        if handle == nil {
            if !FileManager.default.fileExists(atPath: currentURL.path) {
                FileManager.default.createFile(atPath: currentURL.path, contents: nil)
            }
            handle = try? FileHandle(forWritingTo: currentURL)
            _ = try? handle?.seekToEnd()
        }
        guard let handle, let data = line.data(using: .utf8) else { return }
        try? handle.write(contentsOf: data)
        if let size = try? FileManager.default.attributesOfItem(atPath: currentURL.path)[.size] as? UInt64,
           size > maxBytes {
            rotate()
        }
    }

    private func rotate() {
        try? handle?.close()
        handle = nil
        try? FileManager.default.removeItem(at: previousURL)
        try? FileManager.default.moveItem(at: currentURL, to: previousURL)
    }
}
