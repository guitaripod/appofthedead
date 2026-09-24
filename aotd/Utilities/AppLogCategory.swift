import Foundation
import os.log

enum AppLogPrivacy {
    case `public`
    case `private`
}

/// A log line built with string interpolation. The file copy keeps every value; the unified-log
/// copy replaces values marked `privacy: .private` with `<private>`.
struct AppLogMessage: ExpressibleByStringInterpolation {
    let fileText: String
    let systemText: String

    init(stringLiteral value: String) {
        fileText = value
        systemText = value
    }

    init(stringInterpolation: StringInterpolation) {
        fileText = stringInterpolation.fileText
        systemText = stringInterpolation.systemText
    }

    fileprivate init(fileText: String, systemText: String) {
        self.fileText = fileText
        self.systemText = systemText
    }

    struct StringInterpolation: StringInterpolationProtocol {
        var fileText = ""
        var systemText = ""

        init(literalCapacity: Int, interpolationCount: Int) {
            fileText.reserveCapacity(literalCapacity)
            systemText.reserveCapacity(literalCapacity)
        }

        mutating func appendLiteral(_ literal: String) {
            fileText += literal
            systemText += literal
        }

        mutating func appendInterpolation<T>(_ value: T) {
            appendInterpolation(value, privacy: .public)
        }

        mutating func appendInterpolation<T>(_ value: T, privacy: AppLogPrivacy) {
            let text = String(describing: value)
            fileText += text
            systemText += privacy == .private ? "<private>" : text
        }
    }
}

/// One logging category: every call goes to the unified log and to `LogFileWriter`.
struct AppLogCategory {
    let name: String
    private let logger: Logger
    private let file: LogFileWriter

    init(subsystem: String, category: String, file: LogFileWriter = .shared) {
        name = category
        logger = Logger(subsystem: subsystem, category: category)
        self.file = file
    }

    func debug(_ message: AppLogMessage) {
        logger.debug("\(message.systemText, privacy: .public)")
        file.append(level: "DEBUG", category: name, message: message.fileText)
    }

    func info(_ message: AppLogMessage) {
        logger.info("\(message.systemText, privacy: .public)")
        file.append(level: "INFO", category: name, message: message.fileText)
    }

    func warning(_ message: AppLogMessage) {
        logger.warning("\(message.systemText, privacy: .public)")
        file.append(level: "WARN", category: name, message: message.fileText)
    }

    func error(_ message: AppLogMessage) {
        logger.error("\(message.systemText, privacy: .public)")
        file.append(level: "ERROR", category: name, message: message.fileText)
    }

    func debug(_ message: AppLogMessage, metadata: [String: Any]) {
        debug(Self.attach(metadata, to: message))
    }

    func info(_ message: AppLogMessage, metadata: [String: Any]) {
        info(Self.attach(metadata, to: message))
    }

    func warning(_ message: AppLogMessage, metadata: [String: Any]) {
        warning(Self.attach(metadata, to: message))
    }

    func error(_ message: AppLogMessage, metadata: [String: Any]) {
        error(Self.attach(metadata, to: message))
    }

    private static func attach(_ metadata: [String: Any], to message: AppLogMessage) -> AppLogMessage {
        let formatted = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        return AppLogMessage(
            fileText: "\(message.fileText) | \(formatted)",
            systemText: "\(message.systemText) | \(formatted)"
        )
    }
}
