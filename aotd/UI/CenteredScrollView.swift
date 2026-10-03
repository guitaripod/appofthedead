import UIKit

/// A scroll view that centers its content in a readable column: vertically when the content is
/// shorter than the screen, and scrolling when Dynamic Type or a small screen makes it taller.
final class CenteredScrollView: UIScrollView {

    init(content: UIView, maxWidth: CGFloat = 520, horizontalInset: CGFloat = 28, verticalInset: CGFloat = 24) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        alwaysBounceVertical = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        addSubview(container)

        let preferredWidth = content.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -2 * horizontalInset)
        preferredWidth.priority = .defaultHigh
        let centeredVertically = content.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        centeredVertically.priority = .defaultHigh

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            container.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualTo: frameLayoutGuide.heightAnchor),

            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: horizontalInset),
            preferredWidth,
            centeredVertically,
            content.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: verticalInset),
            content.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -verticalInset)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
