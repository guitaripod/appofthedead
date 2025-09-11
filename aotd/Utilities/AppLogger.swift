import Foundation
import UIKit
import os.log

/// Centralized logging system for App of the Dead
/// Provides structured, performant, and privacy-conscious logging with proper categorization
final class AppLogger {

  // MARK: - Subsystem

  private static let subsystem = "com.appofthedead"

  // MARK: - Log Categories

  /// Database operations and data persistence
  static let database = Logger(subsystem: subsystem, category: "Database")

  /// Content loading and JSON parsing
  static let content = Logger(subsystem: subsystem, category: "Content")

  /// Learning path navigation and progress
  static let learning = Logger(subsystem: subsystem, category: "Learning")

  /// Gamification, achievements, and XP
  static let gamification = Logger(subsystem: subsystem, category: "Gamification")

  /// In-app purchases and RevenueCat
  static let purchases = Logger(subsystem: subsystem, category: "Purchases")

  /// User interface and navigation
  static let ui = Logger(subsystem: subsystem, category: "UI")

  /// View model operations and business logic
  static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")

  /// Machine learning and MLX operations
  static let mlx = Logger(subsystem: subsystem, category: "MLX")

  /// Performance monitoring and metrics
  static let performance = Logger(subsystem: subsystem, category: "Performance")

  /// General app lifecycle and configuration
  static let general = Logger(subsystem: subsystem, category: "General")

  // MARK: - Convenience Methods

  /// Log app launch with metadata
  static func logAppLaunch() {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let device = UIDevice.current.model
    let os = UIDevice.current.systemVersion
    let simulator = DeviceUtility.isSimulator

    general.info(
      "App launched | version: \(version), build: \(build), device: \(device), os: \(os), simulator: \(simulator)"
    )
  }

  /// Log view controller lifecycle
  static func logViewControllerLifecycle(_ viewController: String, event: String) {
    ui.debug("\(viewController) - \(event)")
  }

  /// Create a signpost for performance measurement
  static func beginActivity(_ name: StaticString, logger: Logger = performance) -> OSSignpostID {
    // For now, return a dummy ID since os_signpost requires OSLog, not Logger
    return OSSignpostID(log: .default)
  }

  /// End a signpost for performance measurement
  static func endActivity(
    _ name: StaticString, id: OSSignpostID, logger: Logger = performance,
    metadata: [String: Any] = [:]
  ) {
    // Log the activity end as a regular log message instead
    if metadata.isEmpty {
      logger.debug("Activity ended: \(name)")
    } else {
      let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
      logger.debug("Activity ended: \(name) | \(metadataString)")
    }
  }

  // MARK: - Error Logging Helpers

  /// Log an error with proper context and privacy
  static func logError(
    _ error: Error,
    context: String,
    logger: Logger = general,
    additionalInfo: [String: Any] = [:]
  ) {
    var metadataComponents: [String] = []

    metadataComponents.append("context: \(context)")
    metadataComponents.append("error: \(error.localizedDescription)")
    metadataComponents.append("errorType: \(String(describing: type(of: error)))")

    // Handle different error types with appropriate privacy
    if let nsError = error as NSError? {
      metadataComponents.append("domain: \(nsError.domain)")
      metadataComponents.append("code: \(nsError.code)")

      // Log user info with privacy considerations
      for (key, value) in nsError.userInfo {
        let privacyValue = shouldRedactValue(key: key) ? "<redacted>" : "\(value)"
        metadataComponents.append("userInfo.\(key): \(privacyValue)")
      }
    }

    // Add additional info
    for (key, value) in additionalInfo {
      metadataComponents.append("\(key): \(value)")
    }

    let metadata = metadataComponents.joined(separator: ", ")
    logger.error("Error in \(context): \(error.localizedDescription) | \(metadata)")
  }

  /// Check if a value should be redacted for privacy
  private static func shouldRedactValue(key: String) -> Bool {
    let sensitiveKeys = ["password", "token", "key", "secret", "email", "userId", "appleId"]
    return sensitiveKeys.contains { key.lowercased().contains($0) }
  }

  // MARK: - Network Request Logging

  /// Log network request with privacy-conscious URL handling
  static func logNetworkRequest(url: String, method: String, logger: Logger = general) {
    logger.debug("Network Request | method: \(method), url: \(url, privacy: .private)")
  }

  /// Log network response
  static func logNetworkResponse(
    url: String,
    statusCode: Int,
    duration: TimeInterval,
    logger: Logger = general
  ) {
    let success = statusCode < 400
    let durationStr = String(format: "%.3f", duration)

    if success {
      logger.debug(
        "Network Response | url: \(url, privacy: .private), statusCode: \(statusCode), duration: \(durationStr)s, success: \(success)"
      )
    } else {
      logger.error(
        "Network Response | url: \(url, privacy: .private), statusCode: \(statusCode), duration: \(durationStr)s, success: \(success)"
      )
    }
  }

  // MARK: - User Action Logging

  /// Log user interactions with proper privacy
  static func logUserAction(
    _ action: String,
    parameters: [String: Any] = [:],
    logger: Logger = ui
  ) {
    var metadataComponents: [String] = ["action: \(action)"]

    for (key, value) in parameters {
      // Apply privacy based on parameter type
      let privacyValue = shouldRedactValue(key: key) ? "<redacted>" : "\(value)"
      metadataComponents.append("\(key): \(privacyValue)")
    }

    let metadata = metadataComponents.joined(separator: ", ")
    logger.info("User Action: \(action) | \(metadata)")
  }

  // MARK: - Database Operation Logging

  /// Log database operations with performance tracking
  static func logDatabaseOperation(
    _ operation: String,
    table: String? = nil,
    count: Int? = nil,
    duration: TimeInterval? = nil
  ) {
    var metadataComponents: [String] = ["operation: \(operation)"]

    if let table = table {
      metadataComponents.append("table: \(table)")
    }
    if let count = count {
      metadataComponents.append("count: \(count)")
    }
    if let duration = duration {
      metadataComponents.append("duration: \(String(format: "%.3f", duration))s")
    }

    let metadata = metadataComponents.joined(separator: ", ")
    database.debug("Database: \(operation) | \(metadata)")
  }

  // MARK: - Achievement Logging

  /// Log achievement unlock with celebration
  static func logAchievementUnlock(_ achievementId: String, xpEarned: Int) {
    gamification.info(
      "Achievement Unlocked! | achievementId: \(achievementId), xpEarned: \(xpEarned)")
  }

  // MARK: - Memory Warning

  /// Log memory warnings with current usage
  static func logMemoryWarning() {
    let memoryUsage = getMemoryUsage()
    performance.warning(
      "Memory Warning | usedMemory: \(memoryUsage.used)MB, totalMemory: \(memoryUsage.total)MB, percentage: \(memoryUsage.percentage)%"
    )
  }

  private static func getMemoryUsage() -> (used: Int, total: Int, percentage: Int) {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count)
      }
    }

    if result == KERN_SUCCESS {
      let usedMB = Int(info.resident_size) / 1024 / 1024
      let totalMB = Int(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
      let percentage = Int((Double(usedMB) / Double(totalMB)) * 100)
      return (usedMB, totalMB, percentage)
    }

    return (0, 0, 0)
  }
}

// MARK: - Logger Extension for Metadata Support

extension Logger {
  /// Log with metadata dictionary
  func debug(_ message: String, metadata: [String: Any]) {
    let formattedMetadata = formatMetadata(metadata)
    self.debug("\(message) | \(formattedMetadata)")
  }

  func info(_ message: String, metadata: [String: Any]) {
    let formattedMetadata = formatMetadata(metadata)
    self.info("\(message) | \(formattedMetadata)")
  }

  func warning(_ message: String, metadata: [String: Any]) {
    let formattedMetadata = formatMetadata(metadata)
    self.warning("\(message) | \(formattedMetadata)")
  }

  func error(_ message: String, metadata: [String: Any]) {
    let formattedMetadata = formatMetadata(metadata)
    self.error("\(message) | \(formattedMetadata)")
  }

  func log(level: OSLogType, _ message: String, metadata: [String: Any]) {
    let formattedMetadata = formatMetadata(metadata)
    self.log(level: level, "\(message) | \(formattedMetadata)")
  }

  private func formatMetadata(_ metadata: [String: Any]) -> String {
    metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
  }
}
