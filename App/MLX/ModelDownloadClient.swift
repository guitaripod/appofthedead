import Foundation

/// What ``ModelDownloadClient`` reports. Every method runs on the session's delegate queue, and `didFinishDownloadingTo` must move the file before it returns because the system deletes it afterwards.
nonisolated protocol ModelDownloadClientDelegate: AnyObject, Sendable {
    func downloadClient(taskID: Int, didWriteTotal totalBytesWritten: Int64)
    func downloadClient(taskID: Int, didFinishDownloadingTo location: URL, statusCode: Int?)
    func downloadClient(taskID: Int, didCompleteWith error: (any Error)?, statusCode: Int?)
    func downloadClientDidFinishBackgroundEvents()
}

/// One download task the background session already knows about.
nonisolated struct ModelLiveDownload: Sendable {
    let taskID: Int
    let url: URL?
}

/// Owns the shared **background** `URLSession` the multi-GB model snapshot downloads on, so it keeps going while the app is suspended, and forwards the session's delegate callbacks.
///
/// `@unchecked Sendable` is safe because `session` is assigned once in `init` before the instance is shared, and the system serialises the delegate callbacks on the session's own queue.
nonisolated final class ModelDownloadClient: NSObject, @unchecked Sendable {
    private let delegate: any ModelDownloadClientDelegate
    private var session: URLSession!

    init(identifier: String, allowsCellular: Bool, delegate: any ModelDownloadClientDelegate) {
        self.delegate = delegate
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.allowsConstrainedNetworkAccess = false
        config.allowsCellularAccess = allowsCellular
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 7 * 24 * 60 * 60
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func liveDownloads(_ completion: @escaping ([ModelLiveDownload]) -> Void) {
        session.getAllTasks { tasks in
            completion(tasks.map { ModelLiveDownload(taskID: $0.taskIdentifier, url: $0.originalRequest?.url) })
        }
    }

    /// Starts a download of `url` and returns its task identifier.
    func startDownload(from url: URL, expectedBytes: Int64) -> Int {
        let task = session.downloadTask(with: url)
        task.countOfBytesClientExpectsToReceive = expectedBytes
        task.resume()
        return task.taskIdentifier
    }
}

nonisolated extension ModelDownloadClient: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        delegate.downloadClient(taskID: downloadTask.taskIdentifier, didWriteTotal: totalBytesWritten)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        delegate.downloadClient(
            taskID: downloadTask.taskIdentifier,
            didFinishDownloadingTo: location,
            statusCode: (downloadTask.response as? HTTPURLResponse)?.statusCode
        )
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        delegate.downloadClient(
            taskID: task.taskIdentifier,
            didCompleteWith: error,
            statusCode: (task.response as? HTTPURLResponse)?.statusCode
        )
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        delegate.downloadClientDidFinishBackgroundEvents()
    }
}
