import UIKit

/// The part of a full-screen view that stays clear of the fold. It equals the safe area while the
/// device is flat and becomes the half beside the fold's far edge while the device is half open
/// with a vertical fold, so a screen with centred controls never has one cross the fold.
final class FoldAvoidingLayout {
    let guide = UILayoutGuide()
    private var leadingConstraint: NSLayoutConstraint?

    func install(in view: UIView) {
        view.addLayoutGuide(guide)
        let safeArea = view.safeAreaLayoutGuide
        let leading = guide.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor)
        leadingConstraint = leading
        NSLayoutConstraint.activate([
            leading,
            guide.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            guide.topAnchor.constraint(equalTo: safeArea.topAnchor),
            guide.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    /// Call from `viewDidLayoutSubviews`: the system reports the fold after the first layout pass.
    func update(in view: UIView) {
        let target = leadingInset(in: view)
        guard let leadingConstraint, abs(leadingConstraint.constant - target) > 0.5 else { return }
        leadingConstraint.constant = target
        view.setNeedsLayout()
    }

    private func leadingInset(in view: UIView) -> CGFloat {
        guard let fold = FoldRegion.activeFrame(in: view), fold.height > fold.width else { return 0 }
        return max(0, fold.maxX - view.safeAreaInsets.left)
    }
}
