import Foundation
import UIKit
import os.log



final class AppLogger {

  

  private static let subsystem = "com.appofthedead"

  

  
  static let database = Logger(subsystem: subsystem, category: "Database")

  
  static let content = Logger(subsystem: subsystem, category: "Content")

  
  static let learning = Logger(subsystem: subsystem, category: "Learning")

  
  static let gamification = Logger(subsystem: subsystem, category: "Gamification")

  
  static let purchases = Logger(subsystem: subsystem, category: "Purchases")

  
  static let ui = Logger(subsystem: subsystem, category: "UI")

  
  static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")

  
  static let mlx = Logger(subsystem: subsystem, category: "MLX")

  
  static let performance = Logger(subsystem: subsystem, category: "Performance")

  
  static let general = Logger(subsystem: subsystem, category: "General")

  

  
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

  
  static func logViewControllerLifecycle(_ viewController: String, event: String) {
    ui.debug("\(viewController) - \(event)")
  }

  
  static func beginActivity(_ name: StaticString, logger: Logger = performance) -> OSSignpostID {
    
    return OSSignpostID(log: .default)
  }

  
  static func endActivity(
    _ name: StaticString, id: OSSignpostID, logger: Logger = performance,
    metadata: [String: Any] = [:]
  ) {
    
    if metadata.isEmpty {
      logger.debug("Activity ended: \(name)")
    } else {
      let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
      logger.debug("Activity ended: \(name) | \(metadataString)")
    }
  }

  

  
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

    
    if let nsError = error as NSError? {
      metadataComponents.append("domain: \(nsError.domain)")
      metadataComponents.append("code: \(nsError.code)")

      
      for (key, value) in nsError.userInfo {
        let privacyValue = shouldRedactValue(key: key) ? "<redacted>" : "\(value)"
        metadataComponents.append("userInfo.\(key): \(privacyValue)")
      }
    }

    
    for (key, value) in additionalInfo {
      metadataComponents.append("\(key): \(value)")
    }

    let metadata = metadataComponents.joined(separator: ", ")
    logger.error("Error in \(context): \(error.localizedDescription) | \(metadata)")
  }

  
  private static func shouldRedactValue(key: String) -> Bool {
    let sensitiveKeys = ["password", "token", "key", "secret", "email", "userId", "appleId"]
    return sensitiveKeys.contains { key.lowercased().contains($0) }
  }

  

  
  static func logNetworkRequest(url: String, method: String, logger: Logger = general) {
    logger.debug("Network Request | method: \(method), url: \(url, privacy: .private)")
  }

  
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

  

  
  static func logUserAction(
    _ action: String,
    parameters: [String: Any] = [:],
    logger: Logger = ui
  ) {
    var metadataComponents: [String] = ["action: \(action)"]

    for (key, value) in parameters {
      
      let privacyValue = shouldRedactValue(key: key) ? "<redacted>" : "\(value)"
      metadataComponents.append("\(key): \(privacyValue)")
    }

    let metadata = metadataComponents.joined(separator: ", ")
    logger.info("User Action: \(action) | \(metadata)")
  }

  

  
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

  

  
  static func logAchievementUnlock(_ achievementId: String, xpEarned: Int) {
    gamification.info(
      "Achievement Unlocked! | achievementId: \(achievementId), xpEarned: \(xpEarned)")
  }

  

  
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



extension Logger {
  
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
