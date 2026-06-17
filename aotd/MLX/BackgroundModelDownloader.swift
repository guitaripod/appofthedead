import Foundation
import CryptoKit
import Network
import MLXLMCommon

/// SOTA on-device model downloader: one shared **background** `URLSession` so the
/// 3.6 GB model keeps downloading while the app is suspended/killed, commit-pinned
/// HuggingFace snapshots, per-file resume, streaming SHA-256 integrity against the
/// LFS oid, and non-purgeable Application Support storage (excluded from backup).
///
/// Decoupled from model *load*: this only fetches bytes (background-safe). The Metal
/// load + inference stay foreground-only (see MLXService).
final class BackgroundModelDownloader: NSObject, @unchecked Sendable {

    static let shared = BackgroundModelDownloader()
    static let sessionIdentifier = "com.appofthedead.modeldownload"

    private let lock = NSLock()
    private let verifyQueue = DispatchQueue(label: "com.appofthedead.modeldownload.verify", qos: .utility)
    private var backgroundCompletion: (() -> Void)?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.allowsConstrainedNetworkAccess = false
        config.allowsCellularAccess = UserDefaults.standard.object(forKey: "OracleAllowCellularDownload") as? Bool ?? true
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 7 * 24 * 60 * 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private final class Job {
        let repo: String
        let manifest: HFManifest
        let dir: URL
        var taskToFile: [Int: HFFile] = [:]
        var inFlightBytes: [Int: Int64] = [:]
        var completedBytes: Int64
        var remaining: Set<String>
        let onProgress: @Sendable (Foundation.Progress) -> Void
        var continuation: CheckedContinuation<URL, Error>?
        var finished = false

        init(repo: String, manifest: HFManifest, dir: URL,
             completedBytes: Int64, remaining: Set<String>,
             onProgress: @escaping @Sendable (Foundation.Progress) -> Void,
             continuation: CheckedContinuation<URL, Error>) {
            self.repo = repo
            self.manifest = manifest
            self.dir = dir
            self.completedBytes = completedBytes
            self.remaining = remaining
            self.onProgress = onProgress
            self.continuation = continuation
        }
    }

    private var job: Job?

    // MARK: - App delegate background-event plumbing

    func ensureSessionAlive() { _ = session }

    func setBackgroundCompletion(_ handler: @escaping () -> Void) {
        lock.lock(); backgroundCompletion = handler; lock.unlock()
    }

    // MARK: - Storage layout (Application Support, non-purgeable)

    static func modelsRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("OnDeviceModels", isDirectory: true)
    }

    static func repoFolderName(_ repo: String) -> String {
        "models--" + repo.replacingOccurrences(of: "/", with: "--")
    }

    /// The directory the loader reads from for a given repo, if a fully-verified
    /// snapshot exists on disk — else `nil`.
    static func verifiedDirectory(repo: String) -> URL? {
        let repoDir = modelsRoot().appendingPathComponent(repoFolderName(repo), isDirectory: true)
        guard let commitDirs = try? FileManager.default.contentsOfDirectory(at: repoDir, includingPropertiesForKeys: nil) else { return nil }
        for dir in commitDirs where FileManager.default.fileExists(atPath: dir.appendingPathComponent(".verified").path) {
            return dir
        }
        return nil
    }

    static func diskUsageBytes() -> Int64 {
        directorySize(at: modelsRoot())
    }

    // MARK: - Public API

    /// Returns the local directory containing the verified model snapshot, downloading
    /// (in the background, resumably) whatever is missing.
    func ensureDownloaded(repo: String, onProgress: @escaping @Sendable (Foundation.Progress) -> Void) async throws -> URL {
        if let dir = Self.verifiedDirectory(repo: repo) {
            return dir
        }

        let manifest: HFManifest
        do {
            manifest = try await HFModelManifest.fetch(repo: repo)
        } catch {
            throw OnDeviceLLMError.downloadFailed(underlying: error)
        }

        let dir = Self.modelsRoot()
            .appendingPathComponent(Self.repoFolderName(repo), isDirectory: true)
            .appendingPathComponent(manifest.commit, isDirectory: true)
        try createDirectoryExcludedFromBackup(dir)

        if filesOnDiskComplete(manifest: manifest, dir: dir) {
            try await verifyAll(manifest: manifest, dir: dir)
            writeVerifiedMarker(dir: dir, commit: manifest.commit)
            return dir
        }

        try ensureSpace(for: manifest.totalBytes)

        return try await withCheckedThrowingContinuation { continuation in
            startDownloads(repo: repo, manifest: manifest, dir: dir, onProgress: onProgress, continuation: continuation)
        }
    }

    // MARK: - Download orchestration

    private func startDownloads(
        repo: String, manifest: HFManifest, dir: URL,
        onProgress: @escaping @Sendable (Foundation.Progress) -> Void,
        continuation: CheckedContinuation<URL, Error>
    ) {
        var completedBytes: Int64 = 0
        var toDownload: [HFFile] = []
        for file in manifest.files {
            let dest = dir.appendingPathComponent(file.path)
            if fileSize(dest) == file.size {
                completedBytes += file.size
            } else {
                toDownload.append(file)
            }
        }

        let job = Job(
            repo: repo, manifest: manifest, dir: dir,
            completedBytes: completedBytes,
            remaining: Set(toDownload.map(\.path)),
            onProgress: onProgress, continuation: continuation
        )

        lock.lock(); self.job = job; lock.unlock()

        if toDownload.isEmpty {
            verifyAndFinish(job: job)
            return
        }

        session.getAllTasks { [weak self] existing in
            guard let self else { return }
            let liveURLs = Set(existing.compactMap { $0.originalRequest?.url?.absoluteString })
            self.lock.lock()
            for file in toDownload {
                guard let url = manifest.resolveURL(for: file) else { continue }
                if liveURLs.contains(url.absoluteString) { continue }
                let task = self.session.downloadTask(with: url)
                task.countOfBytesClientExpectsToReceive = file.size
                job.taskToFile[task.taskIdentifier] = file
                task.resume()
            }
            for task in existing {
                if let urlString = task.originalRequest?.url?.absoluteString,
                   let file = toDownload.first(where: { manifest.resolveURL(for: $0)?.absoluteString == urlString }) {
                    job.taskToFile[task.taskIdentifier] = file
                }
            }
            self.lock.unlock()
            self.reportProgress(job)
        }
    }

    private func reportProgress(_ job: Job) {
        lock.lock()
        let inFlight = job.inFlightBytes.values.reduce(0, +)
        let done = job.completedBytes
        let total = job.manifest.totalBytes
        lock.unlock()
        let progress = Foundation.Progress(totalUnitCount: max(total, 1))
        progress.completedUnitCount = min(done + inFlight, total)
        job.onProgress(progress)
    }

    private func verifyAndFinish(job: Job) {
        verifyQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self.verifyAllSync(manifest: job.manifest, dir: job.dir)
                self.writeVerifiedMarker(dir: job.dir, commit: job.manifest.commit)
                self.complete(job: job, result: .success(job.dir))
            } catch {
                self.complete(job: job, result: .failure(OnDeviceLLMError.downloadFailed(underlying: error)))
            }
        }
    }

    private func complete(job: Job, result: Result<URL, Error>) {
        lock.lock()
        guard !job.finished, self.job === job else { lock.unlock(); return }
        job.finished = true
        let continuation = job.continuation
        job.continuation = nil
        self.job = nil
        lock.unlock()
        continuation?.resume(with: result)
    }

    // MARK: - Integrity

    private func verifyAll(manifest: HFManifest, dir: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            verifyQueue.async {
                do { try self.verifyAllSync(manifest: manifest, dir: dir); continuation.resume() }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func verifyAllSync(manifest: HFManifest, dir: URL) throws {
        for file in manifest.files {
            let dest = dir.appendingPathComponent(file.path)
            guard fileSize(dest) == file.size else {
                throw OnDeviceLLMError.downloadFailed(underlying: HFModelManifestError.badResponse(0))
            }
            if let expected = file.sha256 {
                let actual = try Self.sha256(of: dest)
                guard actual == expected else {
                    try? FileManager.default.removeItem(at: dest)
                    throw OnDeviceLLMError.downloadFailed(underlying: HFModelManifestError.badResponse(-1))
                }
            }
            if file.path.hasSuffix(".safetensors") {
                try Self.validateSafetensorsHeader(at: dest)
            }
        }
    }

    static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: 4 * 1024 * 1024)
            if chunk.isEmpty { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func validateSafetensorsHeader(at url: URL) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        guard let lenData = try handle.read(upToCount: 8), lenData.count == 8 else {
            throw HFModelManifestError.badResponse(-2)
        }
        let headerLen = UInt64(littleEndian: lenData.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) })
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let total = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        guard headerLen > 0, 8 + Int64(headerLen) <= total else {
            throw HFModelManifestError.badResponse(-3)
        }
    }

    // MARK: - Disk helpers

    private func createDirectoryExcludedFromBackup(_ dir: URL) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = dir
        try? mutable.setResourceValues(values)
    }

    private func filesOnDiskComplete(manifest: HFManifest, dir: URL) -> Bool {
        manifest.files.allSatisfy { fileSize(dir.appendingPathComponent($0.path)) == $0.size }
    }

    private func writeVerifiedMarker(dir: URL, commit: String) {
        try? commit.data(using: .utf8)?.write(to: dir.appendingPathComponent(".verified"))
    }

    private func ensureSpace(for bytes: Int64) throws {
        let required = Int64(Double(bytes) * 1.3)
        let url = Self.modelsRoot()
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let available = values.volumeAvailableCapacityForImportantUsage else { return }
        guard available >= required else {
            throw OnDeviceLLMError.insufficientStorage(requiredBytes: required, availableBytes: available)
        }
    }

    private func fileSize(_ url: URL) -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = (attrs[.size] as? NSNumber)?.int64Value else { return -1 }
        return size
    }

    private static func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            total += Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    func deleteAllModels() {
        try? FileManager.default.removeItem(at: Self.modelsRoot())
    }
}

extension BackgroundModelDownloader: Downloader {
    func download(
        id: String,
        revision: String?,
        matching patterns: [String],
        useLatest: Bool,
        progressHandler: @escaping @Sendable (Foundation.Progress) -> Void
    ) async throws -> URL {
        try await ensureDownloaded(repo: id, onProgress: progressHandler)
    }
}

extension BackgroundModelDownloader: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        lock.lock()
        guard let job, job.taskToFile[downloadTask.taskIdentifier] != nil else { lock.unlock(); return }
        job.inFlightBytes[downloadTask.taskIdentifier] = totalBytesWritten
        lock.unlock()
        reportProgress(job)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        lock.lock()
        guard let job, let file = job.taskToFile[downloadTask.taskIdentifier] else { lock.unlock(); return }
        let dest = job.dir.appendingPathComponent(file.path)
        lock.unlock()

        do {
            try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: location, to: dest)
        } catch {
            AppLogger.mlx.error("Model file move failed for \(file.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        guard let job, let file = job.taskToFile[task.taskIdentifier] else { lock.unlock(); return }
        job.inFlightBytes[task.taskIdentifier] = nil
        job.taskToFile[task.taskIdentifier] = nil

        if let error {
            let nsError = error as NSError
            let code = (task.response as? HTTPURLResponse)?.statusCode ?? -1
            lock.unlock()
            AppLogger.mlx.error("Download error for \(file.path, privacy: .public) http=\(code): \(nsError.localizedDescription, privacy: .public)")
            complete(job: job, result: .failure(OnDeviceLLMError.downloadFailed(underlying: error)))
            return
        }

        let dest = job.dir.appendingPathComponent(file.path)
        let ok = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? Int64) == file.size
        if ok {
            job.completedBytes += file.size
            job.remaining.remove(file.path)
        }
        let remainingEmpty = job.remaining.isEmpty
        lock.unlock()

        reportProgress(job)
        if remainingEmpty { verifyAndFinish(job: job) }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock(); let handler = backgroundCompletion; backgroundCompletion = nil; lock.unlock()
        if let handler { DispatchQueue.main.async { handler() } }
    }
}
