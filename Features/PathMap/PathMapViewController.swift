import UIKit
import MidgarCore
import AppOfTheDeadCore

/// A tradition as a winding path of lessons under its glow, ending at the mastery crown. Done lessons replay, the next
/// one glows, the ones ahead wait.
final class PathMapViewController: UIViewController {

    private let viewModel: PathMapViewModel
    var onLessonSelected: ((Int) -> Void)?
    var onMasteryTest: (() -> Void)?
    var onClose: (() -> Void)?

    private let backdrop = UnderworldBackdropView(seed: 29)
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let summaryLabel = UILabel()
    private lazy var canvas = PathMapCanvasView(accent: accent)
    private var hasScrolledToFocus = false

    private var accent: UIColor {
        PapyrusDesignSystem.Colors.tradition(viewModel.beliefSystem.color)
    }

    init(viewModel: PathMapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.night
        backdrop.glowColor = accent
        backdrop.glowCenter = CGPoint(x: 0.5, y: -0.05)
        backdrop.glowIntensity = 0.3
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        close.tintColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        close.accessibilityLabel = String(localized: "Close")
        navigationItem.leftBarButtonItem = close
        setupLayout()
        canvas.onSelectLesson = { [weak self] index in self?.selectLesson(index) }
        canvas.onSelectCrown = { [weak self] in self?.selectCrown() }
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
        render()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasScrolledToFocus, canvas.bounds.height > 0 else { return }
        hasScrolledToFocus = true
        scrollToFocus(animated: false)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let glyph = GlowingGlyphView(symbol: IconProvider.symbolName(for: viewModel.beliefSystem.icon) ?? "sparkles", color: accent, diameter: 84, pointSize: 34)
        let title = makeSerifLabel(viewModel.beliefSystem.name, size: 32, weight: .bold)
        title.accessibilityTraits = .header
        let description = makeBodyLabel(viewModel.beliefSystem.description, size: 15)
        summaryLabel.font = PapyrusDesignSystem.Typography.sans(13, weight: .semibold, textStyle: .footnote)
        summaryLabel.adjustsFontForContentSizeCategory = true
        summaryLabel.textColor = accent
        summaryLabel.textAlignment = .center
        [glyph, title, description, summaryLabel, canvas].forEach(stack.addArrangedSubview)
        stack.setCustomSpacing(18, after: glyph)
        stack.setCustomSpacing(12, after: description)
        stack.setCustomSpacing(20, after: summaryLabel)

        let preferredWidth = stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        preferredWidth.priority = .init(999)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -120),
            stack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            stack.widthAnchor.constraint(lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            preferredWidth,
        ])
    }

    private func render() {
        summaryLabel.text = viewModel.summary
        canvas.configure(nodes: viewModel.nodes, crown: viewModel.crown)
    }

    private func scrollToFocus(animated: Bool) {
        guard let frame = canvas.focusFrame() else { return }
        let target = canvas.convert(frame, to: scrollView)
        let offset = max(0, min(target.midY - scrollView.bounds.height * 0.45, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom))
        guard offset > 0 else { return }
        scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
    }

    private func selectLesson(_ index: Int) {
        guard let node = viewModel.nodes.first(where: { $0.index == index }) else { return }
        guard viewModel.canOpen(node) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            canvas.shake(lessonAt: index)
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Diagnostics.logUserAction("pathMapLessonOpened", parameters: ["pathId": viewModel.beliefSystem.id, "lesson": index], category: .learning)
        onLessonSelected?(index)
    }

    private func selectCrown() {
        switch viewModel.crown {
        case .sealed(let left):
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            PapyrusAlert.showSimpleAlert(
                title: String(localized: "The crown is sealed"),
                message: String(localized: "Finish \(left) more lessons to face the mastery test."),
                from: self
            )
        case .ready, .mastered:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            onMasteryTest?()
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

/// The winding path itself: a dashed trail through the lesson nodes, lit up to the next lesson, and the crown at the
/// end.
final class PathMapCanvasView: UIView {
    var onSelectLesson: ((Int) -> Void)?
    var onSelectCrown: (() -> Void)?

    private let accent: UIColor
    private let trailLayer = CAShapeLayer()
    private let litTrailLayer = CAShapeLayer()
    private var nodeViews: [PathMapNodeView] = []
    private var crownView: PathMapNodeView?
    private var nodes: [PathMapViewModel.Node] = []
    private let spacing: CGFloat = 132
    private let topInset: CGFloat = 56

    init(accent: UIColor) {
        self.accent = accent
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        trailLayer.strokeColor = UIColor.white.withAlphaComponent(0.14).cgColor
        trailLayer.fillColor = UIColor.clear.cgColor
        trailLayer.lineWidth = 5
        trailLayer.lineDashPattern = [2, 12]
        trailLayer.lineCap = .round
        litTrailLayer.strokeColor = accent.withAlphaComponent(0.7).cgColor
        litTrailLayer.fillColor = UIColor.clear.cgColor
        litTrailLayer.lineWidth = 5
        litTrailLayer.lineCap = .round
        layer.addSublayer(trailLayer)
        layer.addSublayer(litTrailLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: topInset + CGFloat(nodes.count + 1) * spacing + 40)
    }

    func configure(nodes: [PathMapViewModel.Node], crown: PathMapViewModel.CrownState) {
        self.nodes = nodes
        nodeViews.forEach { $0.removeFromSuperview() }
        crownView?.removeFromSuperview()
        nodeViews = nodes.map { node in
            let view = PathMapNodeView(lesson: node, accent: accent)
            view.addAction(UIAction { [weak self] _ in self?.onSelectLesson?(node.index) }, for: .touchUpInside)
            addSubview(view)
            return view
        }
        let crownNode = PathMapNodeView(crown: crown, accent: accent)
        crownNode.addAction(UIAction { [weak self] _ in self?.onSelectCrown?() }, for: .touchUpInside)
        addSubview(crownNode)
        crownView = crownNode
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let points = centers()
        for (view, point) in zip(nodeViews + [crownView].compactMap { $0 }, points) {
            view.sizeToFitNode()
            view.center = CGPoint(x: point.x, y: point.y + view.labelOffset)
        }
        trailLayer.path = trail(through: points).cgPath
        let litCount = (nodes.lastIndex { $0.state == .completed }.map { $0 + 2 }) ?? 1
        litTrailLayer.path = trail(through: Array(points.prefix(max(1, min(litCount, points.count))))).cgPath
    }

    /// Node centres swinging left and right down the canvas.
    private func centers() -> [CGPoint] {
        let amplitude = min(bounds.width * 0.26, 130)
        return (0...nodes.count).map { index in
            CGPoint(x: bounds.midX + amplitude * CGFloat(sin(Double(index) * 0.95)), y: topInset + CGFloat(index) * spacing)
        }
    }

    private func trail(through points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for (previous, next) in zip(points, points.dropFirst()) {
            let midY = (previous.y + next.y) / 2
            path.addCurve(to: next, controlPoint1: CGPoint(x: previous.x, y: midY), controlPoint2: CGPoint(x: next.x, y: midY))
        }
        return path
    }

    func focusFrame() -> CGRect? {
        if let current = nodes.first(where: { $0.state == .current }) {
            return nodeViews[current.index].frame
        }
        return crownView?.frame
    }

    func shake(lessonAt index: Int) {
        guard nodeViews.indices.contains(index) else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -8, 8, -5, 5, 0]
        animation.duration = 0.4
        nodeViews[index].layer.add(animation, forKey: "shake")
    }
}

/// One stop on the path: a round node with the lesson's glyph or the crown, and its title beneath.
final class PathMapNodeView: UIControl {
    private let circle = UIView()
    private let icon = UIImageView()
    private let titleLabel = UILabel()
    private let badge = UILabel()
    private static let diameter: CGFloat = 72
    private static let labelWidth: CGFloat = 170

    /// How far below the node's centre point the view's centre sits, because the title hangs under the circle.
    private(set) var labelOffset: CGFloat = 0

    convenience init(lesson node: PathMapViewModel.Node, accent: UIColor) {
        self.init(frame: .zero)
        let symbol: String
        switch node.state {
        case .completed: symbol = "checkmark"
        case .current: symbol = "book.fill"
        case .ahead: symbol = "lock.fill"
        }
        style(state: node.state, accent: accent, symbol: symbol)
        titleLabel.text = node.title
        if node.state == .current {
            badge.text = node.index == 0 ? String(localized: "Start").uppercased(with: .current) : String(localized: "Next").uppercased(with: .current)
        }
        accessibilityLabel = "\(String(localized: "Lesson \(node.index + 1)")): \(node.title)"
        switch node.state {
        case .completed: accessibilityValue = String(localized: "Completed")
        case .current: accessibilityValue = String(localized: "Up next")
        case .ahead: accessibilityValue = String(localized: "Locked until the lessons before it are done")
        }
    }

    convenience init(crown: PathMapViewModel.CrownState, accent: UIColor) {
        self.init(frame: .zero)
        let gold = PapyrusDesignSystem.Colors.Core.goldLeaf
        switch crown {
        case .mastered(let score):
            style(state: .completed, accent: gold, symbol: "crown.fill")
            titleLabel.text = score.map { String(localized: "Mastered · \($0)%") } ?? String(localized: "Mastered")
        case .ready:
            style(state: .current, accent: gold, symbol: "crown.fill")
            titleLabel.text = String(localized: "Mastery Test")
            badge.text = String(localized: "Ready").uppercased(with: .current)
        case .sealed:
            style(state: .ahead, accent: gold, symbol: "crown")
            titleLabel.text = String(localized: "Mastery Test")
        }
        accessibilityLabel = String(localized: "Mastery Test")
        accessibilityValue = titleLabel.text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        circle.isUserInteractionEnabled = false
        circle.layer.cornerRadius = Self.diameter / 2
        icon.contentMode = .center
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        titleLabel.font = PapyrusDesignSystem.Typography.sans(13, weight: .semibold, textStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.backgroundColor = PapyrusDesignSystem.Colors.Core.night.withAlphaComponent(0.88)
        titleLabel.layer.cornerRadius = 8
        titleLabel.layer.masksToBounds = true
        badge.font = PapyrusDesignSystem.Typography.sans(11, weight: .bold, textStyle: .caption2)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 10
        badge.layer.masksToBounds = true
        [circle, titleLabel, badge].forEach(addSubview)
        circle.addSubview(icon)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func style(state: PathMapViewModel.NodeState, accent: UIColor, symbol: String) {
        icon.image = UIImage(systemName: symbol)
        switch state {
        case .completed:
            circle.backgroundColor = accent
            icon.tintColor = PapyrusDesignSystem.Colors.Core.ink
        case .current:
            circle.backgroundColor = accent.withAlphaComponent(0.2)
            circle.layer.borderWidth = 3
            circle.layer.borderColor = accent.cgColor
            icon.tintColor = accent
            circle.layer.shadowColor = accent.cgColor
            circle.layer.shadowOpacity = 0.7
            circle.layer.shadowRadius = 18
            circle.layer.shadowOffset = .zero
            titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
            badge.backgroundColor = accent
            badge.textColor = PapyrusDesignSystem.Colors.Core.ink
            pulse()
        case .ahead:
            circle.backgroundColor = PapyrusDesignSystem.Colors.Core.surfaceRaised
            circle.layer.borderWidth = 1
            circle.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
            icon.tintColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
            titleLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        }
    }

    private func pulse() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.07
        animation.duration = 1.1
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        circle.layer.add(animation, forKey: "pulse")
    }

    /// Sizes the view around the circle, the badge above it and the title under it.
    func sizeToFitNode() {
        let diameter = Self.diameter
        let titleSize = titleLabel.sizeThatFits(CGSize(width: Self.labelWidth - 12, height: .greatestFiniteMagnitude))
        let badgeHeight: CGFloat = badge.text == nil ? 0 : 20
        let width = max(Self.labelWidth, diameter)
        let height = badgeHeight + (badgeHeight > 0 ? 6 : 0) + diameter + 8 + titleSize.height + 4
        bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let circleTop = badgeHeight > 0 ? badgeHeight + 6 : 0
        circle.frame = CGRect(x: (width - diameter) / 2, y: circleTop, width: diameter, height: diameter)
        icon.frame = circle.bounds
        if badgeHeight > 0 {
            let badgeWidth = badge.intrinsicContentSize.width + 20
            badge.frame = CGRect(x: (width - badgeWidth) / 2, y: 0, width: badgeWidth, height: badgeHeight)
        }
        let titleWidth = min(Self.labelWidth, titleSize.width + 12)
        titleLabel.frame = CGRect(x: (width - titleWidth) / 2, y: circle.frame.maxY + 8, width: titleWidth, height: titleSize.height + 4)
        labelOffset = height / 2 - circle.frame.midY
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.circle.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
            }
        }
    }
}
