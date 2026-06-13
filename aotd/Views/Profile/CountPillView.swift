import UIKit

final class CountPillView: UIView {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.15)
        layer.borderColor = UIColor.Papyrus.gold.cgColor

        label.font = PapyrusDesignSystem.Typography.caption1(weight: .semibold)
        label.textColor = UIColor.Papyrus.gold
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }

    func setText(_ text: String) {
        label.text = text
        isAccessibilityElement = true
        accessibilityLabel = text
    }

    func updateColors() {
        backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.15)
        layer.borderColor = UIColor.Papyrus.gold.cgColor
    }
}
