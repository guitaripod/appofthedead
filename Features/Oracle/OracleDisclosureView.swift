import UIKit

/// The line above every Oracle conversation and explanation: the answers are written by an AI on the iPhone, in the voice
/// of a tradition, and are neither always right nor religious guidance.
final class OracleDisclosureView: UIView {
    static var text: String {
        String(localized: "Written by AI on this iPhone in the voice of each tradition. It can be wrong and is not religious guidance.")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.isAccessibilityElement = false
        let label = UILabel()
        label.text = Self.text
        label.font = PapyrusDesignSystem.Typography.sans(13, textStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        label.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            row.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            row.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        isAccessibilityElement = true
        accessibilityLabel = Self.text
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Fits the view to `width` and returns whether its frame changed, for a table header that does not size itself.
    @discardableResult
    func fit(toWidth width: CGFloat) -> Bool {
        let height = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let fitted = CGRect(x: 0, y: 0, width: width, height: ceil(height))
        guard frame != fitted else { return false }
        frame = fitted
        return true
    }
}
