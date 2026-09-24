import XCTest
@testable import aotd

final class DeepLinkTests: XCTestCase {

    private func link(_ string: String) -> DeepLink? {
        DeepLink(url: URL(string: string)!)
    }

    func testPathLinkParsesTheBeliefSystemId() {
        XCTAssertEqual(link("appofthedead://path/aztec-mictlan"), .path(beliefSystemId: "aztec-mictlan"))
    }

    func testSchemeAndHostAreCaseInsensitive() {
        XCTAssertEqual(link("AppOfTheDead://PATH/norse"), .path(beliefSystemId: "norse"))
    }

    func testTrailingSlashIsIgnored() {
        XCTAssertEqual(link("appofthedead://path/judaism/"), .path(beliefSystemId: "judaism"))
    }

    func testPathWithoutIdIsRejected() {
        XCTAssertNil(link("appofthedead://path"))
        XCTAssertNil(link("appofthedead://path/"))
    }

    func testUnknownHostIsRejected() {
        XCTAssertNil(link("appofthedead://oracle/anubis"))
    }

    func testOtherSchemesAreRejected() {
        XCTAssertNil(link("https://apps.apple.com/app/id6746733380"))
    }
}
