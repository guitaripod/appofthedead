import UIKit

final class XPRingView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let lineWidth: CGFloat = 8
    private var fraction: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        for shapeLayer in [trackLayer, progressLayer] {
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = lineWidth
            shapeLayer.lineCap = .round
            layer.addSublayer(shapeLayer)
        }
        progressLayer.strokeEnd = 0
        updateColors()
    }

    func updateColors() {
        trackLayer.strokeColor = UIColor.Papyrus.aged.withAlphaComponent(0.25).cgColor
        progressLayer.strokeColor = UIColor.Papyrus.gold.cgColor
    }

    func setProgress(_ value: CGFloat, animated: Bool) {
        let clamped = max(0, min(1, value))
        fraction = clamped
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = clamped
            animation.duration = PapyrusDesignSystem.Animation.reveal
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            progressLayer.add(animation, forKey: "strokeEnd")
        }
        progressLayer.strokeEnd = clamped
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        )
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
}
