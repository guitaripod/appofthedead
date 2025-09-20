import Foundation
import UIKit
enum ViewLayoutPreference: String, CaseIterable {
    case grid
    case list
    case compactGrid  
    case wideGrid     
    case sidebarList  
    var title: String {
        switch self {
        case .grid:
            return "Grid View"
        case .list:
            return "List View"
        case .compactGrid:
            return "Compact Grid"
        case .wideGrid:
            return "Wide Grid"
        case .sidebarList:
            return "Sidebar View"
        }
    }
    var iconName: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        case .compactGrid:
            return "square.grid.2x2"
        case .wideGrid:
            return "square.grid.3x3"
        case .sidebarList:
            return "sidebar.left"
        }
    }
    var columnCount: Int {
        switch self {
        case .grid:
            return 2
        case .list, .sidebarList:
            return 1
        case .compactGrid:
            return 2
        case .wideGrid:
            return UIDevice.current.userInterfaceIdiom == .pad && 
                   UIScreen.main.bounds.width > 1024 ? 4 : 3
        }
    }
    static func preferredLayout(for traitCollection: UITraitCollection) -> ViewLayoutPreference {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isRegularWidth = traitCollection.horizontalSizeClass == .regular
        let isRegularHeight = traitCollection.verticalSizeClass == .regular
        let screenWidth = UIScreen.main.bounds.width
        if isIPad {
            if isRegularWidth && isRegularHeight {
                return .wideGrid
            } else if isRegularWidth {
                return .compactGrid
            } else {
                return .grid
            }
        } else {
            return .grid
        }
    }
}
protocol ViewLayoutConfigurable: AnyObject {
    var currentLayoutPreference: ViewLayoutPreference { get set }
    func switchToLayout(_ layout: ViewLayoutPreference)
    func setupLayout(for preference: ViewLayoutPreference)
}
extension Notification.Name {
    static let viewLayoutPreferenceChanged = Notification.Name("viewLayoutPreferenceChanged")
}