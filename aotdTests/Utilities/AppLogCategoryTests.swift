import XCTest
@testable import aotd

final class AppLogCategoryTests: XCTestCase {

    private var directory: URL!
    private var writer: LogFileWriter!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        writer = LogFileWriter(maxBytes: 1024 * 1024, directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func fileContents() throws -> String {
        writer.flush()
        return try String(contentsOf: writer.currentURL, encoding: .utf8)
    }

    func testPrivateValuesAreRedactedOnlyInTheUnifiedLogCopy() {
        let user = "seeker-42"
        let message: AppLogMessage = "Opened \(3) paths for \(user, privacy: .private) at \("home", privacy: .public)"

        XCTAssertEqual(message.fileText, "Opened 3 paths for seeker-42 at home")
        XCTAssertEqual(message.systemText, "Opened 3 paths for <private> at home")
    }

    func testCategoryWritesLevelCategoryAndMessageToTheFile() throws {
        let category = AppLogCategory(subsystem: "com.appofthedead.tests", category: "Learning", file: writer)

        category.info("Lesson \(2) started")
        category.error("Save failed", metadata: ["table": "progress"])

        let lines = try fileContents().split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("[INFO ] [Learning    ] Lesson 2 started"))
        XCTAssertTrue(lines[1].contains("[ERROR] [Learning    ] Save failed | table: progress"))
    }

    func testFileRotatesIntoThePreviousFileOncePastTheLimit() throws {
        writer = LogFileWriter(maxBytes: 200, directory: directory)
        let category = AppLogCategory(subsystem: "com.appofthedead.tests", category: "General", file: writer)

        for index in 0..<10 {
            category.debug("Line \(index) padded to push the file past its size limit")
        }
        writer.flush()

        XCTAssertTrue(FileManager.default.fileExists(atPath: writer.previousURL.path))
        let current = (try? String(contentsOf: writer.currentURL, encoding: .utf8)) ?? ""
        XCTAssertLessThanOrEqual(current.utf8.count, 400)
    }
}
