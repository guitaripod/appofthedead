import Foundation

// MARK: - ViewLayoutPreference

enum ViewLayoutPreference: String, CaseIterable {
    case grid
    case list
    
    var title: String {
        switch self {
        case .grid:
            return "Grid View"
        case .list:
            return "List View"
        }
    }
    
    var iconName: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private enum Keys {
        static let viewLayoutPreference = "viewLayoutPreference"
    }
    
    var viewLayoutPreference: ViewLayoutPreference {
        get {
            guard let rawValue = string(forKey: Keys.viewLayoutPreference),
                  let preference = ViewLayoutPreference(rawValue: rawValue) else {
                return .grid // Default to grid view
            }
            return preference
        }
        set {
            set(newValue.rawValue, forKey: Keys.viewLayoutPreference)
        }
    }
}

// MARK: - ViewLayoutConfigurable Protocol

protocol ViewLayoutConfigurable: AnyObject {
    var currentLayoutPreference: ViewLayoutPreference { get set }
    func switchToLayout(_ layout: ViewLayoutPreference)
    func setupLayout(for preference: ViewLayoutPreference)
}

// MARK: - Notification

extension Notification.Name {
    static let viewLayoutPreferenceChanged = Notification.Name("viewLayoutPreferenceChanged")
}