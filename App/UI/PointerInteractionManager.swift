import UIKit
@available(iOS 13.4, *)
final class PointerInteractionManager: NSObject {
    static let shared = PointerInteractionManager()
    private override init() {
        super.init()
    }
    func addPointerInteraction(to button: UIButton, style: PointerStyle = .lift) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let interaction = UIPointerInteraction(delegate: self)
        button.addInteraction(interaction)
        button.tag = style.rawValue
    }
    func addPointerInteraction(to view: UIView, style: PointerStyle = .hover) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let interaction = UIPointerInteraction(delegate: self)
        view.addInteraction(interaction)
        view.tag = style.rawValue
    }
    func addCardPointerInteraction(to view: UIView) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let interaction = UIPointerInteraction(delegate: self)
        view.addInteraction(interaction)
        view.tag = PointerStyle.card.rawValue
    }
    enum PointerStyle: Int {
        case lift = 1
        case hover = 2
        case highlight = 3
        case card = 4
        case custom = 5
    }
}
@available(iOS 13.4, *)
extension PointerInteractionManager: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        guard let view = interaction.view else { return nil }
        if view is UICollectionViewCell {
            let frame = view.bounds.insetBy(dx: -8, dy: -8)
            return UIPointerRegion(rect: frame, identifier: view.description)
        }
        return UIPointerRegion(rect: view.bounds, identifier: view.description)
    }
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let view = interaction.view else { return nil }
        let style = PointerStyle(rawValue: view.tag) ?? .hover
        switch style {
        case .lift:
            let parameters = UIPreviewParameters()
            parameters.visiblePath = UIBezierPath(
                roundedRect: view.bounds,
                cornerRadius: view.layer.cornerRadius
            )
            let targetedPreview = UITargetedPreview(view: view, parameters: parameters)
            return UIPointerStyle(effect: .lift(targetedPreview))
        case .hover:
            let parameters = UIPreviewParameters()
            parameters.visiblePath = UIBezierPath(
                roundedRect: view.bounds,
                cornerRadius: view.layer.cornerRadius
            )
            let targetedPreview = UITargetedPreview(view: view, parameters: parameters)
            return UIPointerStyle(effect: .hover(
                targetedPreview,
                preferredTintMode: .overlay,
                prefersShadow: true,
                prefersScaledContent: true
            ))
        case .highlight:
            let parameters = UIPreviewParameters()
            if view.layer.cornerRadius > 0 {
                parameters.visiblePath = UIBezierPath(
                    roundedRect: view.bounds,
                    cornerRadius: view.layer.cornerRadius
                )
            }
            let targetedPreview = UITargetedPreview(view: view, parameters: parameters)
            return UIPointerStyle(effect: .highlight(targetedPreview))
        case .card:
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = UIColor.clear
            parameters.visiblePath = UIBezierPath(
                roundedRect: view.bounds,
                cornerRadius: PapyrusDesignSystem.CornerRadius.large
            )
            parameters.shadowPath = UIBezierPath(
                roundedRect: view.bounds.insetBy(dx: -4, dy: -4),
                cornerRadius: PapyrusDesignSystem.CornerRadius.large
            )
            let targetedPreview = UITargetedPreview(view: view, parameters: parameters)
            let pointerShape = UIPointerShape.roundedRect(
                view.bounds.insetBy(dx: -8, dy: -8),
                radius: PapyrusDesignSystem.CornerRadius.large
            )
            return UIPointerStyle(shape: pointerShape, constrainedAxes: [])
        case .custom:
            if view is UITextField || view is UITextView {
                let rect = view.bounds.insetBy(dx: -4, dy: -4)
                return UIPointerStyle(shape: .roundedRect(rect, radius: 8))
            } else {
                let parameters = UIPreviewParameters()
                let targetedPreview = UITargetedPreview(view: view, parameters: parameters)
                return UIPointerStyle(effect: .hover(targetedPreview))
            }
        }
    }
    func pointerInteraction(_ interaction: UIPointerInteraction, willEnter region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
        guard let view = interaction.view else { return }
        animator.addAnimations {
            if view is UICollectionViewCell || view.tag == PointerStyle.card.rawValue {
                view.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                view.layer.shadowOpacity = 0.2
                view.layer.shadowRadius = 12
            }
            if view is UIButton {
                view.alpha = 0.9
            }
        }
    }
    func pointerInteraction(_ interaction: UIPointerInteraction, willExit region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
        guard let view = interaction.view else { return }
        animator.addAnimations {
            view.transform = .identity
            if view is UICollectionViewCell || view.tag == PointerStyle.card.rawValue {
                view.layer.shadowOpacity = 0.1
                view.layer.shadowRadius = 8
            }
            if view is UIButton {
                view.alpha = 1.0
            }
        }
    }
}
extension UIButton {
    func addButtonPointerInteraction(style: PointerInteractionManager.PointerStyle = .lift) {
        if #available(iOS 13.4, *) {
            PointerInteractionManager.shared.addPointerInteraction(to: self, style: style)
        }
    }
}
extension UIView {
    func addAdaptivePointerInteraction(style: PointerInteractionManager.PointerStyle = .hover) {
        if #available(iOS 13.4, *) {
            PointerInteractionManager.shared.addPointerInteraction(to: self, style: style)
        }
    }
    func addCardPointerInteraction() {
        if #available(iOS 13.4, *) {
            PointerInteractionManager.shared.addCardPointerInteraction(to: self)
        }
    }
}
extension UIView {
    func addContextMenu(
        provider: @escaping () -> UIMenu?,
        previewProvider: (() -> UIViewController?)? = nil
    ) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let interaction = UIContextMenuInteraction(delegate: ContextMenuDelegate(
            menuProvider: provider,
            previewProvider: previewProvider
        ))
        self.addInteraction(interaction)
    }
}
private class ContextMenuDelegate: NSObject, UIContextMenuInteractionDelegate {
    let menuProvider: () -> UIMenu?
    let previewProvider: (() -> UIViewController?)?
    init(menuProvider: @escaping () -> UIMenu?, previewProvider: (() -> UIViewController?)? = nil) {
        self.menuProvider = menuProvider
        self.previewProvider = previewProvider
        super.init()
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: previewProvider,
            actionProvider: { [weak self] _ in
                return self?.menuProvider()
            }
        )
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
        }
    }
}
extension UIViewController {
    func addIPadKeyboardShortcuts() {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
    }
}
