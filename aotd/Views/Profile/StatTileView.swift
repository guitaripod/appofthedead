import UIKit

final class StatTileView: UIView {

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()
    private let captionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isAccessibilityElement = true

        iconContainer.backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 16
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor.Papyrus.gold
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        valueLabel.font = PapyrusDesignSystem.Typography.title2()
        valueLabel.textColor = UIColor.Papyrus.gold
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        valueLabel.textAlignment = .center

        captionLabel.font = PapyrusDesignSystem.Typography.footnote()
        captionLabel.textColor = UIColor.Papyrus.secondaryText
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [iconContainer, valueLabel, captionLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 32),
            iconContainer.heightAnchor.constraint(equalToConstant: 32),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 84)
        ])
    }

    func configure(systemIcon: String, value: String, caption: String) {
        iconView.image = UIImage(systemName: systemIcon)
        valueLabel.text = value
        captionLabel.text = caption
        accessibilityLabel = "\(caption), \(value)"
    }
}
