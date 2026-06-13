import UIKit

final class StreakFlameCard: UIView {

    private let flameDisc = UIView()
    private let flameView = UIImageView()
    private let countLabel = UILabel()
    private let captionLabel = UILabel()
    private let multiplierBadge = CountPillView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        applyPapyrusCard()
        layer.cornerCurve = .continuous
        isAccessibilityElement = true

        flameDisc.backgroundColor = UIColor.Papyrus.tombRed.withAlphaComponent(0.12)
        flameDisc.layer.cornerRadius = 28
        flameDisc.translatesAutoresizingMaskIntoConstraints = false

        flameView.image = UIImage(systemName: "flame.fill")
        flameView.tintColor = UIColor.Papyrus.tombRed
        flameView.contentMode = .scaleAspectFit
        flameView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        flameView.translatesAutoresizingMaskIntoConstraints = false
        flameDisc.addSubview(flameView)

        countLabel.font = PapyrusDesignSystem.Typography.title1(weight: .bold)
        countLabel.textColor = UIColor.Papyrus.tombRed

        captionLabel.font = PapyrusDesignSystem.Typography.footnote()
        captionLabel.textColor = UIColor.Papyrus.secondaryText
        captionLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [countLabel, captionLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 0

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rowStack = UIStackView(arrangedSubviews: [flameDisc, textStack, spacer, multiplierBadge])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 16
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            flameDisc.widthAnchor.constraint(equalToConstant: 56),
            flameDisc.heightAnchor.constraint(equalToConstant: 56),
            flameView.centerXAnchor.constraint(equalTo: flameDisc.centerXAnchor),
            flameView.centerYAnchor.constraint(equalTo: flameDisc.centerYAnchor),

            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func configure(streakDays: Int, multiplier: Double, memberSince: String) {
        countLabel.text = "\(streakDays)"

        if streakDays > 0 {
            captionLabel.text = "Day Streak"
            layer.borderColor = UIColor.Papyrus.tombRed.cgColor
        } else {
            captionLabel.text = "Active since \(memberSince)"
            layer.borderColor = UIColor.Papyrus.aged.cgColor
        }

        if multiplier > 1.0 {
            multiplierBadge.isHidden = false
            multiplierBadge.setText(String(format: "×%g XP", multiplier))
        } else {
            multiplierBadge.isHidden = true
        }

        let multiplierSpoken = multiplier > 1.0 ? ", XP multiplier \(String(format: "%g", multiplier)) times" : ""
        accessibilityLabel = "\(streakDays) day streak\(multiplierSpoken)"
    }

    func pulse() {
        UIView.animate(withDuration: 0.3, animations: {
            self.flameView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.flameView.transform = .identity
            }
        })
    }

    func updateColors() {
        multiplierBadge.updateColors()
    }
}
