import XCTest
@testable import aotd

final class AdaptiveLayoutManagerTests: XCTestCase {

    private let manager = AdaptiveLayoutManager.shared

    func testEvenColumnCountIsAlwaysEvenAndAtLeastTwo() {
        for width in stride(from: CGFloat(200), through: 1400, by: 37) {
            let count = AdaptiveLayoutManager.evenColumnCount(for: width)
            XCTAssertEqual(count % 2, 0, "width \(width)")
            XCTAssertGreaterThanOrEqual(count, 2, "width \(width)")
        }
    }

    func testEvenColumnCountGrowsWithTheContainer() {
        XCTAssertEqual(AdaptiveLayoutManager.evenColumnCount(for: 380), 2)
        XCTAssertEqual(AdaptiveLayoutManager.evenColumnCount(for: 669), 2)
        XCTAssertEqual(AdaptiveLayoutManager.evenColumnCount(for: 867), 4)
        XCTAssertEqual(AdaptiveLayoutManager.evenColumnCount(for: 1100), 4)
    }

    func testCompactWindowNeverUsesTheSidebar() {
        let compact = UITraitCollection(horizontalSizeClass: .compact)
        XCTAssertFalse(manager.shouldUseSplitView(for: compact, windowWidth: 466))
        XCTAssertFalse(manager.shouldUseSplitView(for: compact, windowWidth: 951))
    }

    func testRegularWindowUsesTheSidebarOnlyWhenWideEnough() {
        let regular = UITraitCollection(horizontalSizeClass: .regular)
        XCTAssertTrue(manager.shouldUseSplitView(for: regular, windowWidth: 951))
        XCTAssertFalse(manager.shouldUseSplitView(for: regular, windowWidth: 669) && !manager.isIPad)
    }

    func testRegularWidthUsesTheTabletArrangement() {
        XCTAssertTrue(manager.usesTabletLayout(UITraitCollection(horizontalSizeClass: .regular)))
        XCTAssertEqual(
            manager.usesTabletLayout(UITraitCollection(horizontalSizeClass: .compact)),
            manager.isIPad
        )
    }
}
