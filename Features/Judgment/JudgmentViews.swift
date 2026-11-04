import UIKit
import AppOfTheDeadCore

/// A glyph in a softly glowing ring, the emblem every Judgment page leads with.
final class GlowingGlyphView: UIView {
    private let ring = UIView()
    private let imageView = UIImageView()

    init(symbol: String, color: UIColor, diameter: CGFloat = 92, pointSize: CGFloat = 38) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.backgroundColor = color.withAlphaComponent(0.12)
        ring.layer.cornerRadius = diameter / 2
        ring.layer.borderWidth = 1
        ring.layer.borderColor = color.withAlphaComponent(0.45).cgColor
        let glow = PapyrusDesignSystem.Shadow.glow(color: color)
        ring.layer.shadowColor = glow.color
        ring.layer.shadowOpacity = glow.opacity
        ring.layer.shadowRadius = glow.radius
        ring.layer.shadowOffset = glow.offset
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: symbol)
        imageView.tintColor = color
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        addSubview(ring)
        ring.addSubview(imageView)
        NSLayoutConstraint.activate([
            ring.widthAnchor.constraint(equalToConstant: diameter),
            ring.heightAnchor.constraint(equalToConstant: diameter),
            ring.centerXAnchor.constraint(equalTo: centerXAnchor),
            ring.topAnchor.constraint(equalTo: topAnchor),
            ring.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pulse() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CABasicAnimation(keyPath: "shadowRadius")
        animation.fromValue = 14
        animation.toValue = 30
        animation.duration = 1.6
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ring.layer.add(animation, forKey: "pulse")
    }
}

/// A small caps label in letter-spaced gold or a tradition color, for eyebrows above titles.
func makeEyebrowLabel(_ text: String, color: UIColor = PapyrusDesignSystem.Colors.Core.goldLeaf, alignment: NSTextAlignment = .center) -> UILabel {
    let label = UILabel()
    label.attributedText = NSAttributedString(string: text.uppercased(with: .current), attributes: [
        .kern: 1.6,
        .font: PapyrusDesignSystem.Typography.sans(12, weight: .semibold, textStyle: .caption1),
        .foregroundColor: color,
    ])
    label.textAlignment = alignment
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    return label
}

func makeBodyLabel(_ text: String, size: CGFloat = 17, color: UIColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText, alignment: NSTextAlignment = .center) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = PapyrusDesignSystem.Typography.sans(size, textStyle: .body)
    label.textColor = color
    label.textAlignment = alignment
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    return label
}

func makeSerifLabel(_ text: String, size: CGFloat, weight: UIFont.Weight = .semibold, color: UIColor = PapyrusDesignSystem.Colors.Dynamic.primaryText, alignment: NSTextAlignment = .center) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = PapyrusDesignSystem.Typography.serif(size, weight: weight, textStyle: .title1)
    label.textColor = color
    label.textAlignment = alignment
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    return label
}

/// One answer of a scene: a card with the answer's words that lights up gold when chosen.
final class JudgmentAnswerButton: UIControl {
    private let label = UILabel()
    private let accent: UIColor

    init(title: String, accent: UIColor) {
        self.accent = accent
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.82)
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = PapyrusDesignSystem.Typography.sans(17, weight: .medium, textStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        label.numberOfLines = 0
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
        ])
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { applyState(lit: isHighlighted || isSelected) }
    }

    override var isSelected: Bool {
        didSet { applyState(lit: isHighlighted || isSelected) }
    }

    private func applyState(lit: Bool) {
        UIView.animate(withDuration: 0.18) {
            self.layer.borderColor = (lit ? self.accent : UIColor.white.withAlphaComponent(0.12)).cgColor
            self.backgroundColor = lit
                ? self.accent.withAlphaComponent(0.18)
                : PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.82)
            self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
}

/// A thin row of segments, one per scene, lit up to the current one.
final class JudgmentProgressView: UIView {
    private let stack = UIStackView()
    private var segments: [UIView] = []

    init(count: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 5
        stack.distribution = .fillEqually
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightAnchor.constraint(equalToConstant: 4),
        ])
        for _ in 0..<count {
            let segment = UIView()
            segment.layer.cornerRadius = 2
            segment.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            stack.addArrangedSubview(segment)
            segments.append(segment)
        }
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCurrent(_ index: Int, color: UIColor) {
        for (offset, segment) in segments.enumerated() {
            segment.backgroundColor = offset <= index ? color : UIColor.white.withAlphaComponent(0.12)
        }
        accessibilityLabel = String(localized: "Question \(index + 1) of \(segments.count)")
    }
}

/// One realm of the verdict: the tradition, the place and what it means, under a glyph in the tradition's color.
final class VerdictRealmRow: UIControl {

    init(realm: Realm, verdict: Verdict) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let color = JudgmentCopy.color(for: realm.tradition)
        backgroundColor = PapyrusDesignSystem.Colors.Core.surface.withAlphaComponent(0.78)
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = color.withAlphaComponent(0.28).cgColor

        let glyph = UIImageView(image: UIImage(systemName: JudgmentCopy.realmSymbol(realm)))
        glyph.translatesAutoresizingMaskIntoConstraints = false
        glyph.tintColor = color
        glyph.contentMode = .scaleAspectFit
        glyph.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let glyphWell = UIView()
        glyphWell.translatesAutoresizingMaskIntoConstraints = false
        glyphWell.backgroundColor = color.withAlphaComponent(0.14)
        glyphWell.layer.cornerRadius = 22
        glyphWell.addSubview(glyph)

        let tradition = makeEyebrowLabel(JudgmentCopy.tradition(realm.tradition), color: color, alignment: .natural)
        let name = makeSerifLabel(JudgmentCopy.realmName(realm), size: 21, color: PapyrusDesignSystem.Colors.Dynamic.primaryText, alignment: .natural)
        let detail = makeBodyLabel(JudgmentCopy.realmDescription(realm, verdict: verdict), size: 15, alignment: .natural)
        let text = UIStackView(arrangedSubviews: [tradition, name, detail])
        text.axis = .vertical
        text.spacing = 4
        text.setCustomSpacing(6, after: name)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)

        addSubview(glyphWell)
        addSubview(text)
        addSubview(chevron)
        NSLayoutConstraint.activate([
            glyphWell.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            glyphWell.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            glyphWell.widthAnchor.constraint(equalToConstant: 44),
            glyphWell.heightAnchor.constraint(equalToConstant: 44),
            glyph.centerXAnchor.constraint(equalTo: glyphWell.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: glyphWell.centerYAnchor),
            text.leadingAnchor.constraint(equalTo: glyphWell.trailingAnchor, constant: 14),
            text.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            text.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            text.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: glyphWell.centerYAnchor),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "\(JudgmentCopy.tradition(realm.tradition)): \(JudgmentCopy.realmName(realm)). \(JudgmentCopy.realmDescription(realm, verdict: verdict))"
        accessibilityHint = String(localized: "Opens this tradition's path")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.alpha = self.isHighlighted ? 0.75 : 1
            }
        }
    }
}
