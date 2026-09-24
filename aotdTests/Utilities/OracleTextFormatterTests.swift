import XCTest
import UIKit
@testable import aotd

final class OracleTextFormatterTests: XCTestCase {

    private let font = UIFont.systemFont(ofSize: 16)
    private let color = UIColor.black

    private func render(_ text: String) -> NSAttributedString {
        OracleTextFormatter.attributedText(from: text, font: font, color: color)
    }

    private func traits(of text: NSAttributedString, at substring: String) -> UIFontDescriptor.SymbolicTraits {
        let range = (text.string as NSString).range(of: substring)
        XCTAssertNotEqual(range.location, NSNotFound, "\(substring) missing from \(text.string)")
        let font = text.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont
        return font?.fontDescriptor.symbolicTraits ?? []
    }

    func testPlainTextPassesThroughUnchanged() {
        let text = "The heart is weighed.\n\nThen the Duat opens."
        XCTAssertEqual(render(text).string, text)
    }

    func testEmphasisBecomesItalicWithoutAsterisks() {
        let rendered = render("Your *ka* endures.")
        XCTAssertEqual(rendered.string, "Your ka endures.")
        XCTAssertTrue(traits(of: rendered, at: "ka").contains(.traitItalic))
        XCTAssertFalse(traits(of: rendered, at: "Your").contains(.traitItalic))
    }

    func testStrongEmphasisBecomesBold() {
        let rendered = render("Face **the scales** of Ma'at.")
        XCTAssertEqual(rendered.string, "Face the scales of Ma'at.")
        XCTAssertTrue(traits(of: rendered, at: "the scales").contains(.traitBold))
    }

    func testHeadingLosesHashesAndIsBold() {
        let rendered = render("## The Journey\nIt begins.")
        XCTAssertEqual(rendered.string, "The Journey\nIt begins.")
        XCTAssertTrue(traits(of: rendered, at: "The Journey").contains(.traitBold))
    }

    func testListMarkersBecomeBullets() {
        XCTAssertEqual(render("- the ka\n* the ba\n  + the name").string, "• the ka\n• the ba\n  • the name")
    }

    func testHashtagWithoutSpaceIsNotAHeading() {
        XCTAssertEqual(render("#Duat").string, "#Duat")
    }

    func testUnclosedMarkerDuringStreamingStaysLiteral() {
        XCTAssertEqual(render("The **weighing").string, "The **weighing")
    }

    func testEveryRunCarriesTheRequestedColor() {
        let rendered = render("A *b* **c**\n- d")
        rendered.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: rendered.length)) { value, _, _ in
            XCTAssertEqual(value as? UIColor, color)
        }
    }
}
