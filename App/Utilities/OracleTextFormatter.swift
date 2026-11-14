import UIKit

/// Renders the light Markdown the on-device model writes — bold, italics, inline code, headings
/// and bullets — as styled text, so a reply never shows raw asterisks or hashes.
enum OracleTextFormatter {
    static func attributedText(from text: String, font: UIFont, color: UIColor, paragraphStyle: NSParagraphStyle? = nil) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        for (index, rawLine) in lines.enumerated() {
            let line = normalizedLine(rawLine)
            let lineFont = line.isHeading ? font.adding(.traitBold) : font
            result.append(inlineStyled(line.text, font: lineFont, color: color))
            if index < lines.count - 1 {
                let breakFont = line.text.isEmpty ? font.withSize(font.pointSize * blankLineScale) : font
                result.append(NSAttributedString(string: "\n", attributes: [.font: breakFont, .foregroundColor: color]))
            }
        }
        if let paragraphStyle {
            result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        }
        return result
    }

    /// A blank line between paragraphs is drawn at half height, so paragraphs read as one text rather than as islands.
    private static let blankLineScale: CGFloat = 0.5

    /// Text still being written can stop inside `**bold**`, `*italics*` or `` `code` ``. This closes what the last
    /// line left open and drops markers that open nothing yet, so a streaming reply shows its emphasis as it arrives
    /// instead of flashing raw asterisks that vanish a moment later.
    static func streamingSafe(_ text: String) -> String {
        let lineStart = text.lastIndex(of: "\n").map { text.index(after: $0) } ?? text.startIndex
        let line = droppingDanglingMarkers(from: String(text[lineStart...]))
        return String(text[..<lineStart]) + line + closingMarkers(for: line)
    }

    /// A run of `*` or `` ` `` at the end of the line that follows a space opens a span with nothing in it yet.
    private static func droppingDanglingMarkers(from line: String) -> String {
        let kept = line.reversed().drop(while: { $0 == "*" || $0 == "`" })
        guard kept.count < line.count else { return line }
        guard let before = kept.first else { return "" }
        return before.isWhitespace ? String(kept.reversed()) : line
    }

    /// The markers that close every span still open on `line`, innermost first.
    private static func closingMarkers(for line: String) -> String {
        let body = line.drop(while: { $0 == " " || $0 == "\t" })
        let inline = body.hasPrefix("* ") ? body.dropFirst(2) : body
        var open: [String] = []
        var inCode = false
        var index = inline.startIndex
        while index < inline.endIndex {
            let character = inline[index]
            if character == "`" {
                inCode.toggle()
                toggle("`", in: &open)
            } else if character == "*", !inCode {
                let next = inline.index(after: index)
                let isDouble = next < inline.endIndex && inline[next] == "*"
                let runEnd = isDouble ? inline.index(after: next) : next
                if !isFreeStanding(inline, from: index, to: runEnd) {
                    toggle(isDouble ? "**" : "*", in: &open)
                }
                if isDouble {
                    index = next
                }
            }
            index = inline.index(after: index)
        }
        return open.reversed().joined()
    }

    /// An asterisk with space on both sides, as in `5 * 3`, is arithmetic, not emphasis.
    private static func isFreeStanding(_ text: Substring, from start: Substring.Index, to end: Substring.Index) -> Bool {
        let before = start > text.startIndex ? text[text.index(before: start)] : nil
        let after = end < text.endIndex ? text[end] : nil
        return (before?.isWhitespace ?? true) && (after?.isWhitespace ?? false)
    }

    private static func toggle(_ marker: String, in open: inout [String]) {
        if let position = open.lastIndex(of: marker) {
            open.remove(at: position)
        } else {
            open.append(marker)
        }
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
        attributedText = Self.oracleBodyText(text)
    }

    /// A reveal that writes streamed model output into this view in the same style, a few letters at a time, keeping
    /// the newest line in view while the text is taller than the view.
    func makeOracleReveal() -> OracleStreamReveal {
        let reveal = OracleStreamReveal(format: Self.oracleBodyText)
        reveal.onUpdate = { [weak self] text in self?.showRevealedOracleText(text) }
        return reveal
    }

    private func showRevealedOracleText(_ text: NSAttributedString) {
        attributedText = text
        guard contentSize.height > bounds.height else { return }
        let bottom = CGPoint(x: 0, y: contentSize.height - bounds.height + adjustedContentInset.bottom)
        setContentOffset(bottom, animated: false)
    }

    private static func oracleBodyText(_ text: String) -> NSAttributedString {
        OracleTextFormatter.attributedText(
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
