import UIKit

/// The night sky behind the 2.0 screens: a deep gradient, a glow in the tradition's color rising from below, and a
/// field of faint stars that twinkle unless Reduce Motion is on.
final class UnderworldBackdropView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let starLayer = CALayer()
    private var starsDrawnForSize: CGSize = .zero
    private let starSeed: UInt64

    /// The color the glow takes. Gold by default.
    var glowColor: UIColor = PapyrusDesignSystem.Colors.Core.goldLeaf {
        didSet { applyGlowColor() }
    }

    /// Where the glow sits, in unit coordinates of the view.
    var glowCenter = CGPoint(x: 0.5, y: 1.05) {
        didSet { setNeedsLayout() }
    }

    var glowIntensity: CGFloat = 0.28 {
        didSet { applyGlowColor() }
    }

    init(seed: UInt64 = 7) {
        starSeed = seed
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = PapyrusDesignSystem.Colors.Core.night
        gradientLayer.colors = [
            UIColor(hex: 0x0C0A11).cgColor,
            UIColor(hex: 0x120E1C).cgColor,
            UIColor(hex: 0x1A1326).cgColor,
        ]
        gradientLayer.locations = [0, 0.55, 1]
        layer.addSublayer(gradientLayer)
        glowLayer.type = .radial
        layer.addSublayer(glowLayer)
        layer.addSublayer(starLayer)
        applyGlowColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        let radius = max(bounds.width, bounds.height) * 0.75
        glowLayer.frame = CGRect(
            x: bounds.width * glowCenter.x - radius,
            y: bounds.height * glowCenter.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        starLayer.frame = bounds
        if bounds.size != starsDrawnForSize, bounds.width > 0 {
            starsDrawnForSize = bounds.size
            drawStars()
        }
    }

    private func applyGlowColor() {
        glowLayer.colors = [
            glowColor.withAlphaComponent(glowIntensity).cgColor,
            glowColor.withAlphaComponent(glowIntensity * 0.35).cgColor,
            glowColor.withAlphaComponent(0).cgColor,
        ]
        glowLayer.locations = [0, 0.45, 1]
    }

    /// Scatters stars with a fixed seed so the sky does not jump between layouts.
    private func drawStars() {
        starLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        var generator = SeededGenerator(seed: starSeed)
        let count = Int(bounds.width * bounds.height / 5200)
        let animates = !UIAccessibility.isReduceMotionEnabled
        for index in 0..<count {
            let star = CALayer()
            let size = CGFloat.random(in: 0.8...2.0, using: &generator)
            star.frame = CGRect(
                x: CGFloat.random(in: 0...bounds.width, using: &generator),
                y: CGFloat.random(in: 0...(bounds.height * 0.8), using: &generator),
                width: size,
                height: size
            )
            star.cornerRadius = size / 2
            star.backgroundColor = UIColor(hex: 0xF3EAD8).cgColor
            let opacity = Float.random(in: 0.15...0.65, using: &generator)
            star.opacity = opacity
            if animates && index % 3 == 0 {
                let twinkle = CABasicAnimation(keyPath: "opacity")
                twinkle.fromValue = opacity
                twinkle.toValue = opacity * 0.25
                twinkle.duration = Double.random(in: 1.8...4.2, using: &generator)
                twinkle.autoreverses = true
                twinkle.repeatCount = .infinity
                twinkle.beginTime = CACurrentMediaTime() + Double.random(in: 0...3, using: &generator)
                star.add(twinkle, forKey: "twinkle")
            }
            starLayer.addSublayer(star)
        }
    }
}

/// A small deterministic generator (SplitMix64) for layouts that must look random but never change.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
