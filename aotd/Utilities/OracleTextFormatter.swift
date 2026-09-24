import UIKit

/// Renders the light Markdown the on-device model writes — bold, italics, inline code, headings
/// and bullets — as styled text, so a reply never shows raw asterisks or hashes.
enum OracleTextFormatter {
    static func attributedText(from text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        for (index, rawLine) in lines.enumerated() {
            let line = normalizedLine(rawLine)
            let lineFont = line.isHeading ? font.adding(.traitBold) : font
            result.append(inlineStyled(line.text, font: lineFont, color: color))
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: [.font: font, .foregroundColor: color]))
            }
        }
        return result
    }

    /// Turns `## Heading` into a bold line without its hashes and `- item`, `* item` or `+ item`
    /// into a bullet, keeping the line's indentation.
    private static func normalizedLine(_ line: String) -> (text: String, isHeading: Bool) {
        let body = line.drop(while: { $0 == " " || $0 == "\t" })
        let indent = String(line.prefix(line.count - body.count))
        if body.hasPrefix("#") {
            let heading = body.drop(while: { $0 == "#" })
            if heading.isEmpty || heading.first == " " {
                return (heading.trimmingCharacters(in: .whitespaces), true)
            }
        }
        for marker in ["- ", "* ", "+ "] where body.hasPrefix(marker) {
            return (indent + "• " + body.dropFirst(marker.count), false)
        }
        return (line, false)
    }

    private static func inlineStyled(_ line: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let parsed = try? AttributedString(markdown: line, options: options) else {
            return NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: color])
        }
        let styled = NSMutableAttributedString()
        for run in parsed.runs {
            let intent = run.inlinePresentationIntent ?? []
            var runFont = font
            if intent.contains(.code) {
                runFont = .monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
            }
            if intent.contains(.stronglyEmphasized) {
                runFont = runFont.adding(.traitBold)
            }
            if intent.contains(.emphasized) {
                runFont = runFont.adding(.traitItalic)
            }
            styled.append(NSAttributedString(
                string: String(parsed[run.range].characters),
                attributes: [.font: runFont, .foregroundColor: color]
            ))
        }
        return styled
    }
}

extension UITextView {
    /// Shows on-device model output in the Papyrus body style with its Markdown rendered.
    func setOracleText(_ text: String) {
        attributedText = OracleTextFormatter.attributedText(
            from: text,
            font: PapyrusDesignSystem.Typography.body(),
            color: PapyrusDesignSystem.Colors.foreground
        )
    }
}

private extension UIFont {
    func adding(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(trait)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
