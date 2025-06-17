import UIKit

// MARK: - Papyrus Design System
// A comprehensive design framework inspired by ancient papyrus manuscripts
// while maintaining iOS Human Interface Guidelines

enum PapyrusDesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // Primary Papyrus Colors
        static let beige = UIColor(red: 243/255, green: 237/255, blue: 214/255, alpha: 1.0)
        static let ancientInk = UIColor(red: 42/255, green: 32/255, blue: 24/255, alpha: 1.0)
        static let goldLeaf = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
        static let hieroglyphBlue = UIColor(red: 45/255, green: 85/255, blue: 125/255, alpha: 1.0)
        static let tombRed = UIColor(red: 139/255, green: 35/255, blue: 35/255, alpha: 1.0)
        
        // Secondary Colors
        static let sandstone = UIColor(red: 226/255, green: 218/255, blue: 196/255, alpha: 1.0)
        static let aged = UIColor(red: 209/255, green: 196/255, blue: 162/255, alpha: 1.0)
        static let burnishedGold = UIColor(red: 184/255, green: 134/255, blue: 11/255, alpha: 1.0)
        static let mysticPurple = UIColor(red: 102/255, green: 51/255, blue: 153/255, alpha: 1.0)
        static let scarabGreen = UIColor(red: 60/255, green: 110/255, blue: 60/255, alpha: 1.0)
        
        // Background Colors
        static let primaryBackground = beige
        static let secondaryBackground = sandstone
        static let tertiaryBackground = aged
        
        // Text Colors
        static let primaryText = ancientInk
        static let secondaryText = UIColor(red: 92/255, green: 72/255, blue: 54/255, alpha: 1.0)
        static let tertiaryText = UIColor(red: 142/255, green: 122/255, blue: 104/255, alpha: 1.0)
        
        // Semantic Colors (Success, Error, etc.)
        static let success = scarabGreen
        static let error = tombRed
        static let warning = burnishedGold
        static let info = hieroglyphBlue
        
        // Dynamic Colors for Dark Mode
        static var background: UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 28/255, green: 24/255, blue: 20/255, alpha: 1.0) : beige
            }
        }
        
        static var foreground: UIColor {
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? beige : ancientInk
            }
        }
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Custom font names (will use system fonts as fallback)
        static let papyrusFont = "Papyrus" // Will use if available
        static let hieroglyphicFont = "American Typewriter" // Alternative ancient feel
        
        // Font Styles
        static func largeTitle(weight: UIFont.Weight = .bold) -> UIFont {
            if let font = UIFont(name: papyrusFont, size: 34) {
                return font
            }
            return UIFont.systemFont(ofSize: 34, weight: weight)
        }
        
        static func title1(weight: UIFont.Weight = .bold) -> UIFont {
            if let font = UIFont(name: papyrusFont, size: 28) {
                return font
            }
            return UIFont.systemFont(ofSize: 28, weight: weight)
        }
        
        static func title2(weight: UIFont.Weight = .semibold) -> UIFont {
            if let font = UIFont(name: papyrusFont, size: 22) {
                return font
            }
            return UIFont.systemFont(ofSize: 22, weight: weight)
        }
        
        static func title3(weight: UIFont.Weight = .semibold) -> UIFont {
            if let font = UIFont(name: papyrusFont, size: 20) {
                return font
            }
            return UIFont.systemFont(ofSize: 20, weight: weight)
        }
        
        static func headline(weight: UIFont.Weight = .semibold) -> UIFont {
            return UIFont.systemFont(ofSize: 17, weight: weight)
        }
        
        static func body(weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: 17, weight: weight)
        }
        
        static func callout(weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: 16, weight: weight)
        }
        
        static func subheadline(weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: 15, weight: weight)
        }
        
        static func footnote(weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: 13, weight: weight)
        }
        
        static func caption1(weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: 12, weight: weight)
        }
        
        static func caption2(weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: 11, weight: weight)
        }
    }
    
    // MARK: - Spacing & Layout
    
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let rounded: CGFloat = 9999 // For circular elements
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static func papyrus(color: UIColor = .black) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            return (color: color.cgColor, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 8)
        }
        
        static func elevated(color: UIColor = .black) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            return (color: color.cgColor, opacity: 0.2, offset: CGSize(width: 0, height: 4), radius: 12)
        }
        
        static func floating(color: UIColor = .black) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            return (color: color.cgColor, opacity: 0.25, offset: CGSize(width: 0, height: 8), radius: 16)
        }
    }
    
    // MARK: - Borders
    
    enum Border {
        static let width: CGFloat = 1.5
        static let accentWidth: CGFloat = 2.5
        
        static func ancient(width: CGFloat = Border.width) -> (width: CGFloat, color: CGColor) {
            return (width: width, color: Colors.aged.cgColor)
        }
        
        static func gold(width: CGFloat = Border.accentWidth) -> (width: CGFloat, color: CGColor) {
            return (width: width, color: Colors.goldLeaf.cgColor)
        }
    }
    
    // MARK: - Animations
    
    enum Animation {
        static let quick: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.5
        static let reveal: TimeInterval = 0.8
        
        static let springDamping: CGFloat = 0.7
        static let springVelocity: CGFloat = 0.5
    }
    
    // MARK: - Textures & Patterns
    
    enum Texture {
        static func papyrusPattern() -> UIColor {
            // Create a subtle papyrus texture pattern
            UIColor(patternImage: createPapyrusTexture())
        }
        
        private static func createPapyrusTexture() -> UIImage {
            let size = CGSize(width: 100, height: 100)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            
            // Base papyrus color
            Colors.beige.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            
            // Add subtle texture lines
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(Colors.aged.withAlphaComponent(0.1).cgColor)
            context.setLineWidth(0.5)
            
            // Random papyrus fibers
            for _ in 0..<20 {
                let startX = CGFloat.random(in: 0...size.width)
                let startY = CGFloat.random(in: 0...size.height)
                let endX = startX + CGFloat.random(in: -20...20)
                let endY = startY + CGFloat.random(in: -20...20)
                
                context.move(to: CGPoint(x: startX, y: startY))
                context.addLine(to: CGPoint(x: endX, y: endY))
                context.strokePath()
            }
            
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            return image
        }
    }
    
    // MARK: - Component Styles
    
    enum ComponentStyle {
        // Card Style
        static func applyPapyrusCard(to view: UIView, elevated: Bool = false) {
            view.backgroundColor = Colors.secondaryBackground
            view.layer.cornerRadius = CornerRadius.large
            
            let border = Border.ancient()
            view.layer.borderWidth = border.width
            view.layer.borderColor = border.color
            
            if elevated {
                let shadow = Shadow.elevated()
                view.layer.shadowColor = shadow.color
                view.layer.shadowOpacity = shadow.opacity
                view.layer.shadowOffset = shadow.offset
                view.layer.shadowRadius = shadow.radius
            }
        }
        
        // Button Style
        static func applyPapyrusButton(to button: UIButton, style: ButtonStyle = .primary) {
            var config = UIButton.Configuration.filled()
            
            switch style {
            case .primary:
                config.baseBackgroundColor = Colors.goldLeaf
                config.baseForegroundColor = Colors.ancientInk
            case .secondary:
                config.baseBackgroundColor = Colors.hieroglyphBlue
                config.baseForegroundColor = Colors.beige
            case .tertiary:
                config.baseBackgroundColor = Colors.aged
                config.baseForegroundColor = Colors.ancientInk
            case .destructive:
                config.baseBackgroundColor = Colors.tombRed
                config.baseForegroundColor = Colors.beige
            }
            
            config.cornerStyle = .medium
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = Typography.headline(weight: .semibold)
                return outgoing
            }
            
            button.configuration = config
        }
        
        enum ButtonStyle {
            case primary, secondary, tertiary, destructive
        }
    }
}

// MARK: - UIView Extensions

extension UIView {
    func applyPapyrusBackground() {
        backgroundColor = PapyrusDesignSystem.Colors.background
    }
    
    func applyPapyrusCard(elevated: Bool = false) {
        PapyrusDesignSystem.ComponentStyle.applyPapyrusCard(to: self, elevated: elevated)
    }
    
    func addPapyrusBorder(style: BorderStyle = .ancient) {
        switch style {
        case .ancient:
            let border = PapyrusDesignSystem.Border.ancient()
            layer.borderWidth = border.width
            layer.borderColor = border.color
        case .gold:
            let border = PapyrusDesignSystem.Border.gold()
            layer.borderWidth = border.width
            layer.borderColor = border.color
        }
    }
    
    enum BorderStyle {
        case ancient, gold
    }
}

// MARK: - UILabel Extensions

extension UILabel {
    func applyPapyrusStyle(_ style: TextStyle) {
        switch style {
        case .largeTitle:
            font = PapyrusDesignSystem.Typography.largeTitle()
            textColor = PapyrusDesignSystem.Colors.primaryText
        case .title1:
            font = PapyrusDesignSystem.Typography.title1()
            textColor = PapyrusDesignSystem.Colors.primaryText
        case .title2:
            font = PapyrusDesignSystem.Typography.title2()
            textColor = PapyrusDesignSystem.Colors.primaryText
        case .title3:
            font = PapyrusDesignSystem.Typography.title3()
            textColor = PapyrusDesignSystem.Colors.primaryText
        case .headline:
            font = PapyrusDesignSystem.Typography.headline()
            textColor = PapyrusDesignSystem.Colors.primaryText
        case .body:
            font = PapyrusDesignSystem.Typography.body()
            textColor = PapyrusDesignSystem.Colors.primaryText
        case .callout:
            font = PapyrusDesignSystem.Typography.callout()
            textColor = PapyrusDesignSystem.Colors.secondaryText
        case .subheadline:
            font = PapyrusDesignSystem.Typography.subheadline()
            textColor = PapyrusDesignSystem.Colors.secondaryText
        case .footnote:
            font = PapyrusDesignSystem.Typography.footnote()
            textColor = PapyrusDesignSystem.Colors.tertiaryText
        case .caption:
            font = PapyrusDesignSystem.Typography.caption1()
            textColor = PapyrusDesignSystem.Colors.tertiaryText
        }
    }
    
    enum TextStyle {
        case largeTitle, title1, title2, title3, headline, body, callout, subheadline, footnote, caption
    }
}