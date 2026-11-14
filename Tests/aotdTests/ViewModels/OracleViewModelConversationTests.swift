import XCTest
@testable import aotd

@MainActor final class ScriptedOracleVoice: OracleVoicing {
    var chunks: [String] = []
    var failure: Error?
    var holdsOpen = false
    private(set) var prompts: [String] = []

    var engine: OracleVoice.Engine { .apple }
    var isReady: Bool { true }

    func stream(instructions: String, prompt: String, temperature: Double, maxTokens: Int) -> AsyncThrowingStream<String, Error> {
        prompts.append(prompt)
        let chunks = chunks
        let failure = failure
        let holdsOpen = holdsOpen
        return AsyncThrowingStream { continuation in
            for chunk in chunks {
                continuation.yield(chunk)
            }
            if let failure {
                continuation.finish(throwing: failure)
            } else if !holdsOpen {
                continuation.finish()
            }
        }
    }
}

@MainActor final class OracleViewModelConversationTests: XCTestCase {
    private struct Outage: Error {}

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(condition(), "condition never held")
    }

    func testAnswerArrivesAndTheOracleFallsQuiet() async {
        let voice = ScriptedOracleVoice()
        voice.chunks = ["The heart ", "is **weighed**."]
        let viewModel = OracleViewModel(voice: voice)

        await viewModel.sendMessage("What happens to my heart?")

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertTrue(viewModel.messages[0].isUser)
        XCTAssertEqual(viewModel.messages[1].text, "The heart is **weighed**.")
        XCTAssertEqual(viewModel.messages[1].kind, .conversation)
        XCTAssertNil(viewModel.writingMessageID)
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testTheReplyBeingWrittenIsNamedWhileItIsWritten() async throws {
        let voice = ScriptedOracleVoice()
        voice.chunks = ["Osiris waits"]
        voice.holdsOpen = true
        let viewModel = OracleViewModel(voice: voice)

        let asking = Task { await viewModel.sendMessage("Who judges me?") }
        try await waitUntil { viewModel.messages.last?.text == "Osiris waits" }

        XCTAssertEqual(viewModel.writingMessageID, viewModel.messages.last?.id)
        XCTAssertTrue(viewModel.isGenerating)
        viewModel.stopGenerating()
        await asking.value
    }

    func testStoppingKeepsWhatWasWritten() async throws {
        let voice = ScriptedOracleVoice()
        voice.chunks = ["Osiris ", "waits "]
        voice.holdsOpen = true
        let viewModel = OracleViewModel(voice: voice)

        let asking = Task { await viewModel.sendMessage("Who judges me?") }
        try await waitUntil { viewModel.messages.last?.text.hasPrefix("Osiris waits") == true }
        viewModel.stopGenerating()
        await asking.value

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.last?.text, "Osiris waits")
        XCTAssertEqual(viewModel.messages.last?.kind, .conversation)
        XCTAssertNil(viewModel.writingMessageID)
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testStoppingInsideEmphasisClosesIt() async throws {
        let voice = ScriptedOracleVoice()
        voice.chunks = ["Osiris weighs **the"]
        voice.holdsOpen = true
        let viewModel = OracleViewModel(voice: voice)

        let asking = Task { await viewModel.sendMessage("Who judges me?") }
        try await waitUntil { viewModel.messages.last?.text == "Osiris weighs **the" }
        viewModel.stopGenerating()
        await asking.value

        XCTAssertEqual(viewModel.messages.last?.text, "Osiris weighs **the**")
    }

    func testStoppingBeforeAWordTakesTheReplyAway() async throws {
        let voice = ScriptedOracleVoice()
        voice.holdsOpen = true
        let viewModel = OracleViewModel(voice: voice)

        let asking = Task { await viewModel.sendMessage("Who judges me?") }
        try await waitUntil { viewModel.writingMessageID != nil }
        viewModel.stopGenerating()
        await asking.value

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertTrue(viewModel.messages[0].isUser)
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testAFailedAnswerCanBeAskedAgain() async throws {
        let voice = ScriptedOracleVoice()
        voice.failure = Outage()
        let viewModel = OracleViewModel(voice: voice)

        await viewModel.sendMessage("Where do the dead go?")
        let failure = try XCTUnwrap(viewModel.messages.last)
        XCTAssertEqual(failure.kind, .failure)
        XCTAssertNil(viewModel.modelError)

        voice.failure = nil
        voice.chunks = ["Westward, to the Duat."]
        await viewModel.retry(failureID: failure.id)

        XCTAssertEqual(viewModel.messages.map(\.text), ["Where do the dead go?", "Westward, to the Duat."])
        XCTAssertEqual(voice.prompts.count, 2)
    }

    func testANewConversationStartsEmpty() async {
        let voice = ScriptedOracleVoice()
        voice.chunks = ["Yes."]
        let viewModel = OracleViewModel(voice: voice)
        await viewModel.sendMessage("Is the scale fair?")

        viewModel.startNewConversation()

        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.writingMessageID)
    }
}
