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

// MARK: - Papyrus Theme Colors

extension UIColor {
    struct Papyrus {
        // Primary Colors
        static let beige = UIColor(red: 243/255, green: 237/255, blue: 214/255, alpha: 1.0)
        static let ink = UIColor(red: 42/255, green: 32/255, blue: 24/255, alpha: 1.0)
        static let gold = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
        static let hieroglyphBlue = UIColor(red: 45/255, green: 85/255, blue: 125/255, alpha: 1.0)
        static let tombRed = UIColor(red: 139/255, green: 35/255, blue: 35/255, alpha: 1.0)
        
        // Secondary Colors
        static let sandstone = UIColor(red: 226/255, green: 218/255, blue: 196/255, alpha: 1.0)
        static let aged = UIColor(red: 209/255, green: 196/255, blue: 162/255, alpha: 1.0)
        static let burnishedGold = UIColor(red: 184/255, green: 134/255, blue: 11/255, alpha: 1.0)
        static let mysticPurple = UIColor(red: 102/255, green: 51/255, blue: 153/255, alpha: 1.0)
        static let scarabGreen = UIColor(red: 60/255, green: 110/255, blue: 60/255, alpha: 1.0)
        
        // Text Colors
        static let primaryText = ink
        static let secondaryText = UIColor(red: 92/255, green: 72/255, blue: 54/255, alpha: 1.0)
        static let tertiaryText = UIColor(red: 142/255, green: 122/255, blue: 104/255, alpha: 1.0)
        
        // Dynamic Colors
        static var background: UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? 
                    UIColor(red: 28/255, green: 24/255, blue: 20/255, alpha: 1.0) : beige
            }
        }
        
        static var foreground: UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? beige : ink
            }
        }
        
        static var cardBackground: UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                    UIColor(red: 38/255, green: 34/255, blue: 30/255, alpha: 1.0) : sandstone
            }
        }
        
        static var separator: UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                    aged.withAlphaComponent(0.3) : aged.withAlphaComponent(0.5)
            }
        }
    }
}