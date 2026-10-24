import Foundation
import MidgarCore
import UIKit

nonisolated extension MidgarLog {
    /// Logs `message` followed by `metadata` as `key: value` pairs sorted by key, so a line reads the same on every run.
    static func debug(_ message: String, metadata: [String: Any], category: Category = .general) {
        debug(Diagnostics.attach(metadata, to: message), category: category)
    }

    static func info(_ message: String, metadata: [String: Any], category: Category = .general) {
        info(Diagnostics.attach(metadata, to: message), category: category)
    }

    static func notice(_ message: String, metadata: [String: Any], category: Category = .general) {
        notice(Diagnostics.attach(metadata, to: message), category: category)
    }

    static func error(_ message: String, metadata: [String: Any], category: Category = .general) {
        error(Diagnostics.attach(metadata, to: message), category: category)
    }
}

/// The app's logging helpers on top of ``MidgarLog``: launch, memory warnings, timed setup steps, user actions and errors with context.
nonisolated enum Diagnostics {
    /// The start of a timed step, returned by ``beginActivity(_:)`` and handed back to ``endActivity(_:since:metadata:)``.
    struct Activity {
        fileprivate let start: ContinuousClock.Instant
    }

    private static let redactedKeyFragments = ["password", "token", "key", "secret", "email", "userId", "appleId"]

    @MainActor static func logAppLaunch() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let device = UIDevice.current.model
        let os = UIDevice.current.systemVersion
        let simulator = DeviceUtility.isSimulator
        MidgarLog.info("App launched | version: \(version), build: \(build), device: \(device), os: \(os), simulator: \(simulator)")
    }

    static func logViewControllerLifecycle(_ viewController: String, event: String) {
        MidgarLog.debug("\(viewController) - \(event)", category: .ui)
    }

    static func beginActivity(_ name: StaticString) -> Activity {
        Activity(start: .now)
    }

    static func endActivity(_ name: StaticString, since activity: Activity, metadata: [String: Any] = [:]) {
        let elapsed = ContinuousClock.now - activity.start
        let milliseconds = Int(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000)
        MidgarLog.debug("Activity ended: \(name) | ms: \(milliseconds)", metadata: metadata, category: .performance)
    }

    static func logError(
        _ error: Error,
        context: String,
        category: MidgarLog.Category = .general,
        additionalInfo: [String: Any] = [:]
    ) {
        var details: [String: Any] = [
            "context": context,
            "error": error.localizedDescription,
            "errorType": String(describing: type(of: error))
        ]
        let nsError = error as NSError
        details["domain"] = nsError.domain
        details["code"] = nsError.code
        for (key, value) in nsError.userInfo {
            details["userInfo.\(key)"] = shouldRedactValue(key: key) ? "<redacted>" : value
        }
        for (key, value) in additionalInfo {
            details[key] = value
        }
        MidgarLog.error("Error in \(context): \(error.localizedDescription)", metadata: details, category: category)
    }

    static func logUserAction(
        _ action: String,
        parameters: [String: Any] = [:],
        category: MidgarLog.Category = .ui
    ) {
        var details: [String: Any] = [:]
        for (key, value) in parameters {
            details[key] = shouldRedactValue(key: key) ? "<redacted>" : value
        }
        MidgarLog.info("User Action: \(action)", metadata: details, category: category)
    }

    static func logMemoryWarning() {
        let usage = memoryUsage()
        MidgarLog.notice(
            "Memory Warning | usedMemory: \(usage.used)MB, totalMemory: \(usage.total)MB, percentage: \(usage.percentage)%",
            category: .performance
        )
    }

    static func attach(_ metadata: [String: Any], to message: String) -> String {
        guard !metadata.isEmpty else { return message }
        let formatted = metadata.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        return "\(message) | \(formatted)"
    }

    private static func shouldRedactValue(key: String) -> Bool {
        redactedKeyFragments.contains { key.lowercased().contains($0.lowercased()) }
    }

    private static func memoryUsage() -> (used: Int, total: Int, percentage: Int) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0, 0) }
        let usedMB = Int(info.resident_size) / 1024 / 1024
        let totalMB = Int(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
        return (usedMB, totalMB, Int((Double(usedMB) / Double(totalMB)) * 100))
    }
}
