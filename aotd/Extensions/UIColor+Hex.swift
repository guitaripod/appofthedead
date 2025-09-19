import UIKit



extension UIColor {
    
    
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if hexSanitized.count == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}



extension UIColor {
    
    
    struct Papyrus {
        
        static let beige = PapyrusDesignSystem.Colors.Core.beige
        static let ink = PapyrusDesignSystem.Colors.Core.ancientInk
        static let gold = PapyrusDesignSystem.Colors.Core.goldLeaf
        static let hieroglyphBlue = PapyrusDesignSystem.Colors.Core.hieroglyphBlue
        static let tombRed = PapyrusDesignSystem.Colors.Core.tombRed
        static let sandstone = PapyrusDesignSystem.Colors.Core.sandstone
        static let aged = PapyrusDesignSystem.Colors.Core.aged
        static let burnishedGold = PapyrusDesignSystem.Colors.Core.burnishedGold
        static let mysticPurple = PapyrusDesignSystem.Colors.Core.mysticPurple
        static let scarabGreen = PapyrusDesignSystem.Colors.Core.scarabGreen
        
        
        static var primaryText: UIColor { PapyrusDesignSystem.Colors.Dynamic.primaryText }
        static var secondaryText: UIColor { PapyrusDesignSystem.Colors.Dynamic.secondaryText }
        static var tertiaryText: UIColor { PapyrusDesignSystem.Colors.Dynamic.tertiaryText }
        static var background: UIColor { PapyrusDesignSystem.Colors.Dynamic.background }
        static var foreground: UIColor { PapyrusDesignSystem.Colors.Dynamic.primaryText }
        static var cardBackground: UIColor { PapyrusDesignSystem.Colors.Dynamic.cardBackground }
        static var separator: UIColor { PapyrusDesignSystem.Colors.Dynamic.separator }
    }
}