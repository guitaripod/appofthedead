import UIKit
final class AdaptiveLayoutManager {
    static let shared = AdaptiveLayoutManager()
    private init() {}
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape || 
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }
    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    func isRegularWidth(_ traitCollection: UITraitCollection) -> Bool {
        traitCollection.horizontalSizeClass == .regular
    }
    func isRegularHeight(_ traitCollection: UITraitCollection) -> Bool {
        traitCollection.verticalSizeClass == .regular
    }
    func isCompact(_ traitCollection: UITraitCollection) -> Bool {
        traitCollection.horizontalSizeClass == .compact || 
        traitCollection.verticalSizeClass == .compact
    }
    func gridColumnCount(for traitCollection: UITraitCollection, screenWidth: CGFloat? = nil) -> Int {
        let width = screenWidth ?? self.screenWidth
        if isIPad {
            if isRegularWidth(traitCollection) && isRegularHeight(traitCollection) {
                if width > 1366 {  
                    return 5
                } else if width > 1024 {  
                    return 4
                } else if width > 834 {  
                    return 3
                } else {  
                    return 2
                }
            } else if isRegularWidth(traitCollection) {
                return width > 500 ? 2 : 1
            } else {
                return 1
            }
        } else {
            if width > 430 {  
                return isLandscape ? 3 : 2
            } else if width > 390 {  
                return isLandscape ? 2 : 2
            } else {  
                return isLandscape ? 2 : 1
            }
        }
    }
    func calculateItemSize(
        for containerWidth: CGFloat,
        columns: Int,
        spacing: CGFloat = 16,
        aspectRatio: CGFloat = 1.0
    ) -> CGSize {
        let totalSpacing = spacing * CGFloat(columns + 1)
        let itemWidth = (containerWidth - totalSpacing) / CGFloat(columns)
        let itemHeight = itemWidth * aspectRatio
        return CGSize(width: itemWidth, height: itemHeight)
    }
    func shouldUseSplitView(for traitCollection: UITraitCollection) -> Bool {
        isIPad && isRegularWidth(traitCollection)
    }
    func shouldShowSidebar(for traitCollection: UITraitCollection) -> Bool {
        isIPad && isRegularWidth(traitCollection) && screenWidth > 768
    }
    func fontSizeMultiplier(for traitCollection: UITraitCollection) -> CGFloat {
        if isIPad {
            if isRegularWidth(traitCollection) && isRegularHeight(traitCollection) {
                return 1.2  
            } else {
                return 1.1  
            }
        } else {
            return 1.0  
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
        if isIPad && isRegularWidth(traitCollection) {
            return baseSpacing * 1.25  
        } else {
            return baseSpacing
        }
    }
    enum SpacingType {
        case small, medium, large, extraLarge
    }
    func contentInsets(for traitCollection: UITraitCollection) -> UIEdgeInsets {
        if isIPad {
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
    func isMultitasking(for window: UIWindow?) -> Bool {
        guard isIPad, let window = window else { return false }
        let screenBounds = UIScreen.main.bounds
        let windowBounds = window.bounds
        return windowBounds.width < screenBounds.width ||
               windowBounds.height < screenBounds.height
    }
    func touchTargetSize(for traitCollection: UITraitCollection) -> CGFloat {
        if isIPad {
            return isRegularWidth(traitCollection) ? 52 : 48
        } else {
            return 44
        }
    }
}
extension UITraitCollection {
    var isIPadRegular: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    var isIPadCompact: Bool {
        UIDevice.current.userInterfaceIdiom == .pad &&
        (horizontalSizeClass == .compact || verticalSizeClass == .compact)
    }
    var isIPhoneCompact: Bool {
        UIDevice.current.userInterfaceIdiom == .phone &&
        horizontalSizeClass == .compact
    }
    var layoutType: LayoutType {
        if isIPadRegular {
            return .iPadRegular
        } else if isIPadCompact {
            return .iPadCompact
        } else if isIPhoneCompact {
            return .iPhoneCompact
        } else {
            return .iPhoneRegular
        }
    }
    enum LayoutType {
        case iPadRegular    
        case iPadCompact    
        case iPhoneRegular  
        case iPhoneCompact  
        var description: String {
            switch self {
            case .iPadRegular:
                return "iPad Regular"
            case .iPadCompact:
                return "iPad Compact"
            case .iPhoneRegular:
                return "iPhone Regular"
            case .iPhoneCompact:
                return "iPhone Compact"
            }
        }
    }
}
extension UIViewController {
    var layoutManager: AdaptiveLayoutManager {
        AdaptiveLayoutManager.shared
    }
    var isInMultitasking: Bool {
        layoutManager.isMultitasking(for: view.window)
    }
    func updateLayoutForTraitCollection() {
    }
    func addAdaptiveConstraints(
        _ constraints: [NSLayoutConstraint],
        for layoutType: UITraitCollection.LayoutType
    ) {
    }
}