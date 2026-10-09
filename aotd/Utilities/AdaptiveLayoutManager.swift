import UIKit

/// Decides between the phone and the tablet arrangement of a screen from the width it is given.
/// The inner display of a folding iPhone is regular width and gets the tablet arrangement, as
/// does every iPad window, so nothing here asks which device the app runs on.
final class AdaptiveLayoutManager {
    static let shared = AdaptiveLayoutManager()
    private init() {}

    private static let splitViewMinimumWidth: CGFloat = 800
    private static let evenGridColumnWidth: CGFloat = 250

    /// Only input hardware features (pointer, drag and drop, keyboard shortcuts) follow the device class.
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad // duo-audit:ignore input hardware features follow the device class, never layout
    }

    func isRegularWidth(_ traitCollection: UITraitCollection) -> Bool {
        traitCollection.horizontalSizeClass == .regular
    }

    func isRegularHeight(_ traitCollection: UITraitCollection) -> Bool {
        traitCollection.verticalSizeClass == .regular
    }

    /// True on every iPad window and on any regular-width iPhone window.
    func usesTabletLayout(_ traitCollection: UITraitCollection) -> Bool {
        isIPad || isRegularWidth(traitCollection)
    }

    /// iPad keeps its sidebar at any regular width. A regular-width iPhone window needs room for
    /// the sidebar and a readable content column, so a narrow tall window keeps the tab bar.
    func shouldUseSplitView(for traitCollection: UITraitCollection, windowWidth: CGFloat) -> Bool {
        if isIPad { return isRegularWidth(traitCollection) }
        return isRegularWidth(traitCollection) && windowWidth >= Self.splitViewMinimumWidth
    }

    /// iPad columns follow the window width. Elsewhere the count follows the column the grid
    /// sits in and is always even, so no column straddles a fold.
    func gridColumnCount(for traitCollection: UITraitCollection, windowWidth: CGFloat, containerWidth: CGFloat) -> Int {
        guard isIPad else { return Self.evenColumnCount(for: containerWidth) }
        if isRegularWidth(traitCollection) && isRegularHeight(traitCollection) {
            if windowWidth > 1366 {
                return 5
            } else if windowWidth > 1024 {
                return 4
            } else if windowWidth > 834 {
                return 3
            } else {
                return 2
            }
        } else if isRegularWidth(traitCollection) {
            return windowWidth > 500 ? 2 : 1
        } else {
            return 1
        }
    }

    static func evenColumnCount(for containerWidth: CGFloat) -> Int {
        let fitted = max(2, Int(containerWidth / evenGridColumnWidth))
        return fitted + fitted % 2
    }

    func fontSizeMultiplier(for traitCollection: UITraitCollection) -> CGFloat {
        guard usesTabletLayout(traitCollection) else { return 1.0 }
        if isRegularWidth(traitCollection) && isRegularHeight(traitCollection) {
            return 1.2
        } else {
            return 1.1
        }
    }

    func spacing(for type: SpacingType, traitCollection: UITraitCollection) -> CGFloat {
        let baseSpacing: CGFloat
        switch type {
        case .small:
            baseSpacing = 8
        case .medium:
            baseSpacing = 16
        case .large:
            baseSpacing = 24
        case .extraLarge:
            baseSpacing = 32
        }
        if usesTabletLayout(traitCollection) && isRegularWidth(traitCollection) {
            return baseSpacing * 1.25
        } else {
            return baseSpacing
        }
    }

    enum SpacingType {
        case small, medium, large, extraLarge
    }

    func contentInsets(for traitCollection: UITraitCollection) -> UIEdgeInsets {
        if usesTabletLayout(traitCollection) {
            if isRegularWidth(traitCollection) && isRegularHeight(traitCollection) {
                return UIEdgeInsets(top: 24, left: 32, bottom: 24, right: 32)
            } else if isRegularWidth(traitCollection) {
                return UIEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
            } else {
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            }
        } else {
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
    }

    func touchTargetSize(for traitCollection: UITraitCollection) -> CGFloat {
        if usesTabletLayout(traitCollection) {
            return isRegularWidth(traitCollection) ? 52 : 48
        } else {
            return 44
        }
    }
}
