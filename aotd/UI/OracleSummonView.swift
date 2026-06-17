import UIKit

/// A premium full-screen progress meter: a glowing hairline track (deity-accent) with a
/// comet head and four rune ticks that flash at the 25/50/75/100% milestones.
final class OracleHairlineTrack: UIView {

    private let substrate = CALayer()
    private let fill = CALayer()
    private let comet = CALayer()
    private var ticks: [CALayer] = []
    private var accent: UIColor = .white
    private var fraction: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        substrate.cornerRadius = 1.25
        fill.cornerRadius = 1.25
        comet.cornerRadius = 1.5
        layer.addSublayer(substrate)
        layer.addSublayer(fill)
        layer.addSublayer(comet)
        for _ in 0..<4 {
            let t = CALayer(); t.cornerRadius = 0.5
            ticks.append(t); layer.addSublayer(t)
        }
        setAccent(.white)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setAccent(_ color: UIColor) {
        accent = color
        substrate.backgroundColor = color.withAlphaComponent(0.14).cgColor
        fill.backgroundColor = color.cgColor
        comet.backgroundColor = color.cgColor
        comet.shadowColor = color.cgColor
        comet.shadowRadius = 6
        comet.shadowOpacity = 0.9
        comet.shadowOffset = .zero
        fill.shadowColor = color.cgColor
        fill.shadowRadius = 5
        fill.shadowOpacity = 0.8
        fill.shadowOffset = .zero
        for (i, t) in ticks.enumerated() {
            t.backgroundColor = color.withAlphaComponent(fraction >= CGFloat(i + 1) / 4 ? 0.9 : 0.3).cgColor
        }
    }

    func set(progress: Float, animated: Bool) {
        fraction = CGFloat(max(0, min(progress, 1)))
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        if animated { CATransaction.setAnimationDuration(0.3) }
        layoutFill()
        CATransaction.commit()
        for (i, t) in ticks.enumerated() where fraction >= CGFloat(i + 1) / 4 {
            t.backgroundColor = accent.withAlphaComponent(0.9).cgColor
        }
    }

    private func layoutFill() {
        let h: CGFloat = 2.5
        let y = (bounds.height - h) / 2
        substrate.frame = CGRect(x: 0, y: y, width: bounds.width, height: h)
        let w = bounds.width * fraction
        fill.frame = CGRect(x: 0, y: y, width: w, height: h)
        comet.frame = CGRect(x: max(0, w - 1.5), y: y - 0.5, width: 3, height: 3.5)
        comet.isHidden = fraction <= 0.001 || fraction >= 0.999
        for (i, t) in ticks.enumerated() {
            let fx = CGFloat(i + 1) / 4 * bounds.width
            t.frame = CGRect(x: min(fx, bounds.width - 1), y: y - 1, width: 1, height: h + 2)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        layoutFill()
        CATransaction.commit()
    }
}

/// "The Threshold" — the full-screen Oracle summon / awakening experience. The deity's
/// nebula portal fills the whole screen in every state; all copy lives in a bottom
/// "dispatch" on a forced-dark frosted slab with fixed cream text, so it is legible in
/// BOTH light and dark mode regardless of the shader's brightness.
final class OracleSummonView: UIView {

    enum State: Equatable {
        case idle
        case downloading
        case preparing
    }

    var onAwaken: (() -> Void)?
    var onWhy: (() -> Void)?

    private let isSimulator: Bool
    private(set) var awakening: OracleAwakeningView?
    private let fallbackGradient = CAGradientLayer()
    private var accent: UIColor = UIColor.Papyrus.gold
    private var modelName = "Oracle"
    private var sizeGB = 3.6

    private static let ink = UIColor(red: 245/255, green: 240/255, blue: 226/255, alpha: 1)

    private let panel = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let goldEdge = UIView()
    private let stack = UIStackView()

    private let kicker = UILabel()
    private let titleLabel = UILabel()
    private let supporting = UILabel()
    private let progressRow = UIStackView()
    private let track = OracleHairlineTrack()
    private let numeral = UILabel()
    private let status = UILabel()
    private let cta = UIButton(type: .system)
    private let whyButton = UIButton(type: .system)

    private var shadowedLabels: [UILabel] = []

    init(deityColor: UIColor?, isSimulator: Bool) {
        self.isSimulator = isSimulator
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.06, green: 0.05, blue: 0.04, alpha: 1)
        if let metal = OracleAwakeningView(deityColor: deityColor) {
            awakening = metal
            metal.translatesAutoresizingMaskIntoConstraints = false
            addSubview(metal)
            pinEdges(metal)
        } else {
            setupFallbackGradient()
        }
        if let deityColor { accent = deityColor }
        setupPanel()
        apply(.idle)
        update(progress: 0.045)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func pinEdges(_ v: UIView) {
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: topAnchor),
            v.bottomAnchor.constraint(equalTo: bottomAnchor),
            v.leadingAnchor.constraint(equalTo: leadingAnchor),
            v.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setupFallbackGradient() {
        fallbackGradient.type = .radial
        fallbackGradient.startPoint = CGPoint(x: 0.5, y: 0.42)
        fallbackGradient.endPoint = CGPoint(x: 1.1, y: 1.1)
        layer.insertSublayer(fallbackGradient, at: 0)
        refreshFallbackColors()
    }

    private func refreshFallbackColors() {
        fallbackGradient.colors = [accent.cgColor, accent.withAlphaComponent(0.15).cgColor, UIColor(red: 0.06, green: 0.05, blue: 0.04, alpha: 1).cgColor]
    }

    private func setupPanel() {
        panel.overrideUserInterfaceStyle = .dark
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.layer.cornerRadius = 28
        panel.layer.cornerCurve = .continuous
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        addSubview(panel)

        goldEdge.translatesAutoresizingMaskIntoConstraints = false
        goldEdge.backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.55)
        panel.contentView.addSubview(goldEdge)

        configureLabels()
        configureCTA()

        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 8, trailing: 20)
        panel.contentView.addSubview(stack)

        progressRow.axis = .horizontal
        progressRow.alignment = .center
        progressRow.spacing = 16
        track.translatesAutoresizingMaskIntoConstraints = false
        progressRow.addArrangedSubview(track)
        progressRow.addArrangedSubview(numeral)
        numeral.setContentHuggingPriority(.required, for: .horizontal)
        track.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(kicker)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(supporting)
        stack.addArrangedSubview(progressRow)
        stack.addArrangedSubview(status)
        stack.addArrangedSubview(cta)
        stack.addArrangedSubview(whyButton)
        stack.setCustomSpacing(20, after: supporting)
        stack.setCustomSpacing(20, after: status)
        stack.setCustomSpacing(8, after: cta)

        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            goldEdge.topAnchor.constraint(equalTo: panel.contentView.topAnchor),
            goldEdge.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            goldEdge.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),
            goldEdge.heightAnchor.constraint(equalToConstant: 0.5),
            track.heightAnchor.constraint(equalToConstant: 12),
            progressRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
            cta.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
            cta.heightAnchor.constraint(equalToConstant: 54)
        ])
        applyAccent()
    }

    private func configureLabels() {
        kicker.numberOfLines = 1
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85
        titleLabel.font = PapyrusDesignSystem.Typography.largeTitle(weight: .bold)
        titleLabel.textColor = Self.ink
        supporting.numberOfLines = 2
        supporting.font = PapyrusDesignSystem.Typography.body()
        supporting.textColor = Self.ink.withAlphaComponent(0.82)
        numeral.font = UIFont.monospacedDigitSystemFont(ofSize: 52, weight: .bold)
        numeral.textColor = accent
        numeral.adjustsFontSizeToFitWidth = true
        numeral.minimumScaleFactor = 0.6
        status.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        status.textColor = Self.ink.withAlphaComponent(0.65)
        status.numberOfLines = 1

        for label in [kicker, titleLabel, supporting, numeral, status] {
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOpacity = 0.5
            label.layer.shadowRadius = 3
            label.layer.shadowOffset = CGSize(width: 0, height: 1)
            label.layer.masksToBounds = false
            shadowedLabels.append(label)
        }
    }

    private func configureCTA() {
        var config = UIButton.Configuration.plain()
        config.title = isSimulator ? "Enter the Simulator Oracle" : "Awaken the Oracle"
        config.image = UIImage(systemName: isSimulator ? "desktopcomputer" : "sparkles")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = PapyrusDesignSystem.Typography.headline()
            return updated
        }
        cta.configuration = config
        cta.layer.cornerRadius = 14
        cta.layer.cornerCurve = .continuous
        cta.layer.borderWidth = 1
        cta.translatesAutoresizingMaskIntoConstraints = false
        cta.addTarget(self, action: #selector(awakenTapped), for: .touchUpInside)

        whyButton.setTitle("Why ~\(String(format: "%.1f", sizeGB)) GB?", for: .normal)
        whyButton.titleLabel?.font = PapyrusDesignSystem.Typography.caption1()
        whyButton.setTitleColor(Self.ink.withAlphaComponent(0.55), for: .normal)
        whyButton.contentHorizontalAlignment = .leading
        whyButton.addTarget(self, action: #selector(whyTapped), for: .touchUpInside)
    }

    private func applyAccent() {
        numeral.textColor = accent
        track.setAccent(accent)
        cta.layer.borderColor = accent.withAlphaComponent(0.6).cgColor
        cta.configuration?.baseForegroundColor = Self.ink
        cta.configuration?.baseBackgroundColor = accent.withAlphaComponent(0.12)
        cta.tintColor = accent
        refreshFallbackColors()
    }

    // MARK: - Public API

    func setDeity(color: UIColor) {
        accent = color
        awakening?.setDeity(color: color)
        applyAccent()
    }

    func configure(modelName: String, sizeGB: Double) {
        self.modelName = modelName
        self.sizeGB = sizeGB
        whyButton.setTitle("Why ~\(String(format: "%.1f", sizeGB)) GB?", for: .normal)
    }

    func update(progress: Float) {
        awakening?.update(progress: progress)
        let pct = Int((max(0, min(progress, 1)) * 100).rounded())
        numeral.attributedText = numeralAttributed(pct)
        track.set(progress: progress, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    func setStatus(_ text: String) { status.text = text }

    func apply(_ state: State) {
        let reduce = UIAccessibility.isReduceMotionEnabled
        let changes = {
            switch state {
            case .idle:
                self.kicker.attributedText = self.kickerAttributed("THE ORACLE SLEEPS")
                self.titleLabel.text = "Consult the divine."
                self.supporting.text = "\(self.modelName) runs entirely on your iPhone. About \(String(format: "%.1f", self.sizeGB)) GB, downloaded once."
                self.setHidden([self.progressRow, self.status], true)
                self.setHidden([self.cta, self.whyButton], false)
            case .downloading:
                self.kicker.attributedText = self.kickerAttributed("AWAKENING")
                self.titleLabel.text = "Consult the divine."
                self.setHidden([self.cta, self.whyButton], true)
                self.setHidden([self.progressRow, self.status, self.supporting], false)
            case .preparing:
                self.kicker.attributedText = self.kickerAttributed("CROSSING THE THRESHOLD")
                self.setStatus("Restoring the divine connection…")
                self.setHidden([self.cta, self.whyButton], true)
                self.setHidden([self.progressRow, self.status], false)
            }
        }
        if reduce { changes() } else { UIView.transition(with: stack, duration: 0.35, options: .transitionCrossDissolve, animations: changes) }
    }

    func pause() { awakening?.pauseRendering() }
    func resume() { awakening?.resumeRendering() }

    // MARK: - Helpers

    private func setHidden(_ views: [UIView], _ hidden: Bool) {
        for v in views { v.isHidden = hidden }
    }

    private func kickerAttributed(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: PapyrusDesignSystem.Typography.caption2(weight: .semibold),
            .foregroundColor: Self.ink.withAlphaComponent(0.7),
            .kern: 2.5
        ])
    }

    private func numeralAttributed(_ pct: Int) -> NSAttributedString {
        let s = NSMutableAttributedString(string: "\(pct)", attributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 52, weight: .bold),
            .foregroundColor: accent
        ])
        s.append(NSAttributedString(string: "%", attributes: [
            .font: UIFont.systemFont(ofSize: 31, weight: .bold),
            .foregroundColor: accent.withAlphaComponent(0.65)
        ]))
        return s
    }

    @objc private func awakenTapped() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        onAwaken?()
    }

    @objc private func whyTapped() { onWhy?() }

    override func layoutSubviews() {
        super.layoutSubviews()
        fallbackGradient.frame = bounds
        for label in shadowedLabels {
            label.layer.shadowPath = UIBezierPath(rect: label.bounds).cgPath
        }
    }
}
