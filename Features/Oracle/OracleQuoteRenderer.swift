import UIKit

/// Draws a reply of the Oracle as a 1080 × 1350 card: the deity under its glyph, the question asked, and the answer
/// in large serif type. Fixed sizes, so every card looks the same wherever it is posted.
enum OracleQuoteRenderer {

    static let size = CGSize(width: 1080, height: 1350)
    private static let answerLimit = 420

    @MainActor
    static func render(reply: String, question: String?, deity: OracleViewModel.Deity) -> UIImage {
        let card = makeCard(reply: reply, question: question, deity: deity)
        card.frame = CGRect(origin: .zero, size: size)
        card.setNeedsLayout()
        card.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            card.layer.render(in: context.cgContext)
        }
    }

    /// The reply without Markdown, cut at a sentence end before `answerLimit` characters where one exists.
    static func trimmed(_ reply: String) -> String {
        let plain = reply
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard plain.count > answerLimit else { return plain }
        let head = String(plain.prefix(answerLimit))
        if let end = head.lastIndex(where: { ".!?。！？".contains($0) }), head.distance(from: head.startIndex, to: end) > answerLimit / 2 {
            return String(head[...end])
        }
        return head.trimmingCharacters(in: .whitespaces) + "…"
    }

    @MainActor
    private static func makeCard(reply: String, question: String?, deity: OracleViewModel.Deity) -> UIView {
        let color = PapyrusDesignSystem.Colors.tradition(deity.color)
        let parchment = PapyrusDesignSystem.Colors.Core.parchment
        let card = UIView()
        card.overrideUserInterfaceStyle = .dark
        let backdrop = UnderworldBackdropView(seed: 31)
        backdrop.glowColor = color
        backdrop.glowIntensity = 0.4
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(backdrop)

        let glyph = GlowingGlyphView(symbol: UIImage(systemName: deity.avatar) == nil ? "sparkles" : deity.avatar, color: color, diameter: 150, pointSize: 64)
        let eyebrow = label("\(deity.tradition) · \(deity.role)".uppercased(with: .current), font: .systemFont(ofSize: 26, weight: .bold), color: color, kern: 4)
        let name = label(deity.name, font: serif(64, weight: .bold), color: PapyrusDesignSystem.Colors.Core.goldLeaf)
        var views: [UIView] = [glyph, eyebrow, name]
        if let question, !question.isEmpty {
            let asked = label("“\(question.count > 140 ? String(question.prefix(140)) + "…" : question)”", font: italic(32), color: parchment.withAlphaComponent(0.65))
            views.append(asked)
        }
        let answer = label(trimmed(reply), font: serif(trimmed(reply).count > 280 ? 40 : 46, weight: .regular), color: parchment)
        answer.textAlignment = .natural
        views.append(answer)
        let footer = label(String(localized: "Ask the gods yourself in App of the Dead").uppercased(with: .current), font: .systemFont(ofSize: 24, weight: .semibold), color: PapyrusDesignSystem.Colors.Core.goldLeaf, kern: 3)
        views.append(footer)

        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 18
        stack.setCustomSpacing(36, after: glyph)
        stack.setCustomSpacing(40, after: name)
        if views.count == 6 { stack.setCustomSpacing(30, after: views[3]) }
        stack.setCustomSpacing(56, after: answer)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let frame = UIView()
        frame.translatesAutoresizingMaskIntoConstraints = false
        frame.layer.borderWidth = 2
        frame.layer.borderColor = color.withAlphaComponent(0.4).cgColor
        frame.layer.cornerRadius = 40
        frame.layer.cornerCurve = .continuous
        card.addSubview(frame)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: card.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            frame.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
            frame.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -40),
            frame.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 40),
            frame.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -40),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 100),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -100),
        ])
        return card
    }

    private static func serif(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFont(descriptor: base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor, size: size)
    }

    private static func italic(_ size: CGFloat) -> UIFont {
        let base = serif(size, weight: .regular)
        return UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(.traitItalic) ?? base.fontDescriptor, size: size)
    }

    @MainActor
    private static func label(_ text: String, font: UIFont, color: UIColor, kern: CGFloat = 0) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .kern: kern])
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}
