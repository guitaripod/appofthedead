import UIKit
import LinkPresentation
import AppOfTheDeadCore

/// Draws the Soul Card: a story-sized (1080 × 1920) image of the verdict, made to be posted. It uses fixed type
/// sizes, never Dynamic Type, so every card looks the same wherever it lands.
enum SoulCardRenderer {

    static let size = CGSize(width: 1080, height: 1920)

    @MainActor
    static func render(_ verdict: Verdict) -> UIImage {
        let card = makeCard(for: verdict)
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

    @MainActor
    private static func makeCard(for verdict: Verdict) -> UIView {
        let card = UIView()
        card.overrideUserInterfaceStyle = .dark
        let backdrop = UnderworldBackdropView(seed: 23)
        backdrop.glowColor = JudgmentCopy.color(for: verdict.leadingTradition)
        backdrop.glowIntensity = 0.42
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(backdrop)

        let gold = PapyrusDesignSystem.Colors.Core.goldLeaf
        let parchment = PapyrusDesignSystem.Colors.Core.parchment

        let brand = label(String(localized: "App of the Dead · The Judgment").uppercased(with: .current), font: .systemFont(ofSize: 28, weight: .semibold), color: gold, kern: 5)
        let glyph = GlowingGlyphView(symbol: JudgmentCopy.archetypeSymbol(verdict.archetype), color: gold, diameter: 190, pointSize: 84)
        let lead = label(String(localized: "My soul is").uppercased(with: .current), font: .systemFont(ofSize: 30, weight: .semibold), color: parchment.withAlphaComponent(0.7), kern: 4)
        let name = label(JudgmentCopy.archetypeName(verdict.archetype), font: serif(86, weight: .bold), color: gold)
        let blurb = label(JudgmentCopy.archetypeDescription(verdict.archetype), font: .systemFont(ofSize: 36, weight: .regular), color: parchment.withAlphaComponent(0.82))

        let rows = UIStackView(arrangedSubviews: verdict.realms.map(row(for:)))
        rows.axis = .vertical
        rows.spacing = 28

        let question = label(String(localized: "Where will your soul go?"), font: serif(50, weight: .semibold), color: parchment)
        let cta = label(String(localized: "Face the Judgment in App of the Dead, free on the App Store"), font: .systemFont(ofSize: 30, weight: .medium), color: gold)

        let frame = UIView()
        frame.translatesAutoresizingMaskIntoConstraints = false
        frame.layer.borderWidth = 2
        frame.layer.borderColor = gold.withAlphaComponent(0.35).cgColor
        frame.layer.cornerRadius = 44
        frame.layer.cornerCurve = .continuous
        card.addSubview(frame)
        NSLayoutConstraint.activate([
            frame.topAnchor.constraint(equalTo: card.topAnchor, constant: 44),
            frame.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -44),
            frame.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 44),
            frame.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -44),
        ])

        let stack = UIStackView(arrangedSubviews: [brand, glyph, lead, name, blurb, rows, question, cta])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 18
        stack.setCustomSpacing(70, after: brand)
        stack.setCustomSpacing(46, after: glyph)
        stack.setCustomSpacing(12, after: lead)
        stack.setCustomSpacing(26, after: name)
        stack.setCustomSpacing(64, after: blurb)
        stack.setCustomSpacing(70, after: rows)
        stack.setCustomSpacing(14, after: question)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: card.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 90),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -90),
        ])
        return card
    }

    @MainActor
    private static func row(for realm: Realm) -> UIView {
        let color = JudgmentCopy.color(for: realm.tradition)
        let icon = UIImageView(image: UIImage(systemName: JudgmentCopy.realmSymbol(realm)))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        let well = UIView()
        well.backgroundColor = color.withAlphaComponent(0.15)
        well.layer.cornerRadius = 44
        well.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        well.addSubview(icon)
        NSLayoutConstraint.activate([
            well.widthAnchor.constraint(equalToConstant: 88),
            well.heightAnchor.constraint(equalToConstant: 88),
            icon.centerXAnchor.constraint(equalTo: well.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: well.centerYAnchor),
        ])
        let tradition = label(JudgmentCopy.tradition(realm.tradition).uppercased(with: .current), font: .systemFont(ofSize: 24, weight: .bold), color: color, kern: 3, alignment: .natural)
        let name = label(JudgmentCopy.realmName(realm), font: serif(48, weight: .semibold), color: PapyrusDesignSystem.Colors.Core.parchment, alignment: .natural)
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.7
        name.numberOfLines = 1
        let text = UIStackView(arrangedSubviews: [tradition, name])
        text.axis = .vertical
        text.spacing = 2
        let row = UIStackView(arrangedSubviews: [well, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 30
        return row
    }

    private static func serif(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFont(descriptor: base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor, size: size)
    }

    @MainActor
    private static func label(_ text: String, font: UIFont, color: UIColor, kern: CGFloat = 0, alignment: NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .kern: kern])
        label.textAlignment = alignment
        label.numberOfLines = 0
        return label
    }
}

/// The card as a share item: the image for apps that take images, with a titled preview in the share sheet.
final class SoulCardShareItem: NSObject, UIActivityItemSource {
    private let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = String(localized: "My Soul Card")
        metadata.imageProvider = NSItemProvider(object: image)
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}
