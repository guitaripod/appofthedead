import UIKit

/// The balance of the Hall of Two Truths: a heart in one pan, the feather of Ma'at in the other. `weigh` swings the
/// beam with a tick of haptics on every pass and settles it at the verdict's tilt.
final class ScaleOfMaatView: UIView {

    /// How the beam settles: negative raises the heart (lighter than the feather), positive sinks it.
    enum Settle {
        case lighter, balanced, heavier

        var angle: CGFloat {
            switch self {
            case .lighter: return -0.12
            case .balanced: return 0
            case .heavier: return 0.2
            }
        }
    }

    private let pillar = CAShapeLayer()
    private let beamPivot = CALayer()
    private let beam = CAShapeLayer()
    private let leftPan = PanLayer()
    private let rightPan = PanLayer()
    private let heartView = UIImageView(image: UIImage(systemName: "heart.fill"))
    private let featherLayer = CAShapeLayer()
    private var currentAngle: CGFloat = 0
    private var displayLink: CADisplayLink?
    private var swingStart: CFTimeInterval = 0
    private var swingTarget: CGFloat = 0
    private var completion: (() -> Void)?
    private var lastSwingSign: CGFloat = 0
    private let ticker = UIImpactFeedbackGenerator(style: .soft)

    private let gold = PapyrusDesignSystem.Colors.Core.goldLeaf
    private let swingDuration: CFTimeInterval = 3.4

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Your heart is weighed against the feather of Ma'at")
        pillar.strokeColor = gold.cgColor
        pillar.fillColor = gold.withAlphaComponent(0.12).cgColor
        pillar.lineWidth = 2.5
        pillar.lineCap = .round
        layer.addSublayer(pillar)
        layer.addSublayer(beamPivot)
        beam.strokeColor = gold.cgColor
        beam.lineWidth = 3
        beam.lineCap = .round
        beam.fillColor = UIColor.clear.cgColor
        beamPivot.addSublayer(beam)
        [leftPan, rightPan].forEach {
            $0.strokeColor = gold
            beamPivot.addSublayer($0)
        }
        heartView.tintColor = UIColor(hex: 0xE0604E)
        heartView.contentMode = .scaleAspectFit
        leftPan.content.addSublayer(heartView.layer)
        featherLayer.fillColor = PapyrusDesignSystem.Colors.Core.parchment.cgColor
        featherLayer.strokeColor = gold.cgColor
        featherLayer.lineWidth = 1.2
        rightPan.content.addSublayer(featherLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 300, height: 230)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let angle = currentAngle
        applyAngle(0)
        let width = bounds.width, height = bounds.height
        let pivot = CGPoint(x: width / 2, y: height * 0.22)
        let base = UIBezierPath()
        base.move(to: CGPoint(x: pivot.x, y: pivot.y - 8))
        base.addLine(to: CGPoint(x: pivot.x, y: height - 14))
        base.move(to: CGPoint(x: pivot.x - 46, y: height - 6))
        base.addQuadCurve(to: CGPoint(x: pivot.x + 46, y: height - 6), controlPoint: CGPoint(x: pivot.x, y: height - 26))
        base.close()
        base.append(UIBezierPath(ovalIn: CGRect(x: pivot.x - 7, y: pivot.y - 15, width: 14, height: 14)))
        pillar.path = base.cgPath
        pillar.frame = bounds

        let armLength = min(width * 0.42, 150)
        beamPivot.bounds = CGRect(x: 0, y: 0, width: armLength * 2, height: height)
        beamPivot.position = pivot
        beamPivot.anchorPoint = CGPoint(x: 0.5, y: 0)
        let beamPath = UIBezierPath()
        beamPath.move(to: CGPoint(x: 0, y: 0))
        beamPath.addLine(to: CGPoint(x: armLength * 2, y: 0))
        beam.path = beamPath.cgPath

        let panSize = CGSize(width: 96, height: height * 0.52)
        leftPan.frame = CGRect(x: -panSize.width / 2, y: 0, width: panSize.width, height: panSize.height)
        rightPan.frame = CGRect(x: armLength * 2 - panSize.width / 2, y: 0, width: panSize.width, height: panSize.height)
        leftPan.layoutPan()
        rightPan.layoutPan()

        heartView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        heartView.layer.position = CGPoint(x: leftPan.content.bounds.midX, y: leftPan.content.bounds.midY)
        featherLayer.path = Self.featherPath(in: CGRect(x: 0, y: 0, width: 48, height: 22)).cgPath
        featherLayer.frame = CGRect(x: rightPan.content.bounds.midX - 24, y: rightPan.content.bounds.midY - 11, width: 48, height: 22)
        applyAngle(angle)
    }

    /// Swings the beam and settles it, then calls `completion`.
    func weigh(settling settle: Settle, completion: @escaping () -> Void) {
        self.completion = completion
        swingTarget = settle.angle
        guard !UIAccessibility.isReduceMotionEnabled else {
            applyAngle(swingTarget)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.finish() }
            return
        }
        ticker.prepare()
        swingStart = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func step() {
        let elapsed = CACurrentMediaTime() - swingStart
        let progress = min(1, elapsed / swingDuration)
        let damping = CGFloat(pow(1 - progress, 1.6))
        let swing = CGFloat(sin(elapsed * 5.2)) * 0.32 * damping
        let angle = swing + swingTarget * CGFloat(progress)
        applyAngle(angle)
        let sign: CGFloat = swing >= 0 ? 1 : -1
        if sign != lastSwingSign, damping > 0.08 {
            ticker.impactOccurred(intensity: max(0.3, damping))
            lastSwingSign = sign
        }
        if progress >= 1 {
            displayLink?.invalidate()
            displayLink = nil
            applyAngle(swingTarget)
            finish()
        }
    }

    private func finish() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        completion?()
        completion = nil
    }

    /// Rotates the beam and keeps both pans hanging straight down.
    private func applyAngle(_ angle: CGFloat) {
        currentAngle = angle
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        beamPivot.setAffineTransform(CGAffineTransform(rotationAngle: angle))
        leftPan.setAffineTransform(CGAffineTransform(rotationAngle: -angle))
        rightPan.setAffineTransform(CGAffineTransform(rotationAngle: -angle))
        CATransaction.commit()
    }

    override func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        super.removeFromSuperview()
    }

    /// A quill feather lying on its side: a curved vane around a central shaft.
    static func featherPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let tip = CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.15)
        let base = CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY + rect.height * 0.1)
        path.move(to: base)
        path.addCurve(
            to: tip,
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY - rect.height * 0.15),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.8, y: rect.minY)
        )
        path.addCurve(
            to: base,
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY + rect.height * 0.1)
        )
        path.close()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.22))
        path.addQuadCurve(to: tip, controlPoint: CGPoint(x: rect.midX, y: rect.midY))
        return path
    }
}

/// One pan of the balance: three chains from the beam's end down to a shallow bowl that holds `content`.
nonisolated private final class PanLayer: CALayer {
    let content = CALayer()
    private let chains = CAShapeLayer()
    private let bowl = CAShapeLayer()

    var strokeColor: UIColor = .white {
        didSet {
            chains.strokeColor = strokeColor.withAlphaComponent(0.7).cgColor
            bowl.strokeColor = strokeColor.cgColor
            bowl.fillColor = strokeColor.withAlphaComponent(0.14).cgColor
        }
    }

    override init() {
        super.init()
        anchorPoint = CGPoint(x: 0.5, y: 0)
        chains.lineWidth = 1.2
        chains.fillColor = UIColor.clear.cgColor
        bowl.lineWidth = 2
        addSublayer(chains)
        addSublayer(bowl)
        addSublayer(content)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutPan() {
        let width = bounds.width, height = bounds.height
        let bowlTop = height - 22
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: 4, y: bowlTop))
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width / 2, y: bowlTop))
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width - 4, y: bowlTop))
        chains.path = path.cgPath
        chains.frame = bounds
        let bowlPath = UIBezierPath()
        bowlPath.move(to: CGPoint(x: 0, y: bowlTop))
        bowlPath.addQuadCurve(to: CGPoint(x: width, y: bowlTop), controlPoint: CGPoint(x: width / 2, y: height + 10))
        bowlPath.close()
        bowl.path = bowlPath.cgPath
        bowl.frame = bounds
        content.frame = CGRect(x: 0, y: bowlTop - 40, width: width, height: 40)
    }
}
