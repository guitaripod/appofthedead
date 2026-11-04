import UIKit

/// The 2.0 "Underworld" look: a night palette lit by gold leaf, New York serif for display type and SF for reading,
/// every face scaled with Dynamic Type. The app is dark by design, so the dynamic colors resolve to the night palette
/// in both appearances and the window runs in dark mode for the system chrome.
enum PapyrusDesignSystem {

    enum Colors {

        enum Core {
            static let night = UIColor(hex: 0x0C0A11)
            static let surface = UIColor(hex: 0x17141F)
            static let surfaceRaised = UIColor(hex: 0x221E2C)
            static let parchment = UIColor(hex: 0xF3EAD8)
            static let ink = UIColor(hex: 0x16110A)

            static let beige = parchment
            static let ancientInk = ink
            static let goldLeaf = UIColor(hex: 0xE5BA5C)
            static let hieroglyphBlue = UIColor(hex: 0x4A78D8)
            static let tombRed = UIColor(hex: 0xD9564A)
            static let sandstone = surface
            static let aged = UIColor(hex: 0x4A4256)
            static let burnishedGold = UIColor(hex: 0xC4923A)
            static let mysticPurple = UIColor(hex: 0x9A7BE6)
            static let scarabGreen = UIColor(hex: 0x4FB683)

            static let darkBackground = night
            static let darkCard = surface
        }

        enum Semantic {
            static let success = Core.scarabGreen
            static let error = Core.tombRed
            static let warning = Core.burnishedGold
            static let info = Core.hieroglyphBlue
            static let disabled = Core.aged.withAlphaComponent(0.6)
        }

        enum Dynamic {
            static var background: UIColor { Core.night }
            static var cardBackground: UIColor { Core.surface }
            static var raisedBackground: UIColor { Core.surfaceRaised }
            static var primaryText: UIColor { Core.parchment }
            static var secondaryText: UIColor { UIColor(hex: 0xBDB19C) }
            static var tertiaryText: UIColor { UIColor(hex: 0x8C8274) }
            static var separator: UIColor { UIColor.white.withAlphaComponent(0.08) }
            static var border: UIColor { UIColor.white.withAlphaComponent(0.11) }
        }

        enum Component {
            enum Button {
                static var primaryBackground: UIColor { Core.goldLeaf }
                static var primaryForeground: UIColor { Core.ink }
                static var secondaryBackground: UIColor { Core.hieroglyphBlue }
                static var secondaryForeground: UIColor { Core.parchment }
                static var tertiaryBackground: UIColor { Core.surfaceRaised }
                static var tertiaryForeground: UIColor { Core.parchment }
                static var destructiveBackground: UIColor { Core.tombRed }
                static var destructiveForeground: UIColor { Core.parchment }
                static var disabledBackground: UIColor { Core.aged }
                static var disabledForeground: UIColor { Dynamic.tertiaryText }
            }

            enum Progress {
                static var track: UIColor { UIColor.white.withAlphaComponent(0.09) }
                static var fill: UIColor { Core.goldLeaf }
            }

            enum Card {
                static var background: UIColor { Dynamic.cardBackground }
                static var border: UIColor { Dynamic.border }
            }
        }

        static let beige = Core.beige
        static let ancientInk = Core.ancientInk
        static let goldLeaf = Core.goldLeaf
        static let hieroglyphBlue = Core.hieroglyphBlue
        static let tombRed = Core.tombRed
        static let sandstone = Core.sandstone
        static let aged = Core.aged
        static let burnishedGold = Core.burnishedGold
        static let mysticPurple = Core.mysticPurple
        static let scarabGreen = Core.scarabGreen

        static let primaryBackground = Core.night
        static let secondaryBackground = Core.surface
        static let tertiaryBackground = Core.surfaceRaised

        static var primaryText: UIColor { Dynamic.primaryText }
        static var secondaryText: UIColor { Dynamic.secondaryText }
        static var tertiaryText: UIColor { Dynamic.tertiaryText }

        static let success = Semantic.success
        static let error = Semantic.error
        static let warning = Semantic.warning
        static let info = Semantic.info

        static var background: UIColor { Dynamic.background }
        static var foreground: UIColor { Dynamic.primaryText }

        /// A tradition's color from `aotd.json`, lifted until it reads on the night background. Several traditions are
        /// defined as deep inks (Norse is indigo, Shinto a dark red) that disappear on black; the hue is kept and only
        /// the lightness rises.
        static func tradition(_ hex: String) -> UIColor {
            guard let base = UIColor(hex: hex) else { return Core.goldLeaf }
            return luminous(base)
        }

        /// Raises the HSB brightness of `color` to at least 0.78 and caps its saturation at 0.72.
        static func luminous(_ color: UIColor) -> UIColor {
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return color }
            return UIColor(hue: hue, saturation: min(saturation, 0.72), brightness: max(brightness, 0.78), alpha: alpha)
        }
    }

    enum Typography {

        /// The maximum growth any face takes under Dynamic Type, so fixed-size chrome keeps its shape at AX sizes.
        private static let maximumScale: CGFloat = 1.6

        private static func adaptiveSize(_ baseSize: CGFloat, for traitCollection: UITraitCollection? = nil) -> CGFloat {
            let traits = traitCollection ?? UITraitCollection.current
            return baseSize * AdaptiveLayoutManager.shared.fontSizeMultiplier(for: traits)
        }

        /// New York at `size`, scaled with Dynamic Type through `textStyle`.
        static func serif(_ size: CGFloat, weight: UIFont.Weight = .semibold, textStyle: UIFont.TextStyle = .title2) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
            return scaled(UIFont(descriptor: descriptor, size: size), textStyle: textStyle, size: size)
        }

        /// SF at `size`, scaled with Dynamic Type through `textStyle`.
        static func sans(_ size: CGFloat, weight: UIFont.Weight = .regular, textStyle: UIFont.TextStyle = .body) -> UIFont {
            scaled(UIFont.systemFont(ofSize: size, weight: weight), textStyle: textStyle, size: size)
        }

        /// SF Rounded, for numbers and counters.
        static func rounded(_ size: CGFloat, weight: UIFont.Weight = .bold, textStyle: UIFont.TextStyle = .headline) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
            return scaled(UIFont(descriptor: descriptor, size: size), textStyle: textStyle, size: size)
        }

        private static func scaled(_ font: UIFont, textStyle: UIFont.TextStyle, size: CGFloat) -> UIFont {
            UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font, maximumPointSize: size * maximumScale)
        }

        static func largeTitle(weight: UIFont.Weight = .bold, for traitCollection: UITraitCollection? = nil) -> UIFont {
            serif(adaptiveSize(34, for: traitCollection), weight: weight, textStyle: .largeTitle)
        }

        static func title1(weight: UIFont.Weight = .bold, for traitCollection: UITraitCollection? = nil) -> UIFont {
            serif(adaptiveSize(28, for: traitCollection), weight: weight, textStyle: .title1)
        }

        static func title2(weight: UIFont.Weight = .semibold, for traitCollection: UITraitCollection? = nil) -> UIFont {
            serif(adaptiveSize(22, for: traitCollection), weight: weight, textStyle: .title2)
        }

        static func title3(weight: UIFont.Weight = .semibold, for traitCollection: UITraitCollection? = nil) -> UIFont {
            serif(adaptiveSize(20, for: traitCollection), weight: weight, textStyle: .title3)
        }

        static func headline(weight: UIFont.Weight = .semibold, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(17, for: traitCollection), weight: weight, textStyle: .headline)
        }

        static func body(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(17, for: traitCollection), weight: weight, textStyle: .body)
        }

        static func callout(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(16, for: traitCollection), weight: weight, textStyle: .callout)
        }

        static func subheadline(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(15, for: traitCollection), weight: weight, textStyle: .subheadline)
        }

        static func footnote(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(13, for: traitCollection), weight: weight, textStyle: .footnote)
        }

        static func caption1(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(12, for: traitCollection), weight: weight, textStyle: .caption1)
        }

        static func caption2(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            sans(adaptiveSize(11, for: traitCollection), weight: weight, textStyle: .caption2)
        }

        static func bodyItalic(weight: UIFont.Weight = .regular, for traitCollection: UITraitCollection? = nil) -> UIFont {
            let base = UIFont.systemFont(ofSize: adaptiveSize(17, for: traitCollection), weight: weight)
            let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) ?? base.fontDescriptor
            return scaled(UIFont(descriptor: descriptor, size: base.pointSize), textStyle: .body, size: base.pointSize)
        }

        static func largeTitle(weight: UIFont.Weight = .bold) -> UIFont {
            largeTitle(weight: weight, for: nil)
        }

        static func title1(weight: UIFont.Weight = .bold) -> UIFont {
            title1(weight: weight, for: nil)
        }

        static func title2(weight: UIFont.Weight = .semibold) -> UIFont {
            title2(weight: weight, for: nil)
        }

        static func title3(weight: UIFont.Weight = .semibold) -> UIFont {
            title3(weight: weight, for: nil)
        }

        static func headline(weight: UIFont.Weight = .semibold) -> UIFont {
            headline(weight: weight, for: nil)
        }

        static func body(weight: UIFont.Weight = .regular) -> UIFont {
            body(weight: weight, for: nil)
        }

        static func callout(weight: UIFont.Weight = .regular) -> UIFont {
            callout(weight: weight, for: nil)
        }

        static func subheadline(weight: UIFont.Weight = .regular) -> UIFont {
            subheadline(weight: weight, for: nil)
        }

        static func footnote(weight: UIFont.Weight = .regular) -> UIFont {
            footnote(weight: weight, for: nil)
        }

        static func caption1(weight: UIFont.Weight = .regular) -> UIFont {
            caption1(weight: weight, for: nil)
        }

        static func caption2(weight: UIFont.Weight = .regular) -> UIFont {
            caption2(weight: weight, for: nil)
        }

        static func bodyItalic(weight: UIFont.Weight = .regular) -> UIFont {
            bodyItalic(weight: weight, for: nil)
        }
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48

        static func adaptive(_ base: CGFloat, for traitCollection: UITraitCollection) -> CGFloat {
            let layoutManager = AdaptiveLayoutManager.shared
            if layoutManager.usesTabletLayout(traitCollection) && layoutManager.isRegularWidth(traitCollection) {
                return base * 1.25
            }
            return base
        }

        static func xxSmall(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(xxSmall, for: traitCollection)
        }

        static func xSmall(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(xSmall, for: traitCollection)
        }

        static func small(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(small, for: traitCollection)
        }

        static func medium(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(medium, for: traitCollection)
        }

        static func large(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(large, for: traitCollection)
        }

        static func xLarge(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(xLarge, for: traitCollection)
        }

        static func xxLarge(for traitCollection: UITraitCollection) -> CGFloat {
            adaptive(xxLarge, for: traitCollection)
        }
    }

    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 28
        static let rounded: CGFloat = 9999
    }

    enum Shadow {
        static func papyrus(color: UIColor = .black) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            (color: color.cgColor, opacity: 0.35, offset: CGSize(width: 0, height: 4), radius: 12)
        }

        static func elevated(color: UIColor = .black) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            (color: color.cgColor, opacity: 0.45, offset: CGSize(width: 0, height: 8), radius: 18)
        }

        static func floating(color: UIColor = .black) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            (color: color.cgColor, opacity: 0.55, offset: CGSize(width: 0, height: 12), radius: 24)
        }

        /// A soft halo in `color`, for things that should read as lit from within.
        static func glow(color: UIColor) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
            (color: color.cgColor, opacity: 0.55, offset: .zero, radius: 18)
        }
    }

    enum Border {
        static let width: CGFloat = 1
        static let accentWidth: CGFloat = 1.5

        static func ancient(width: CGFloat = Border.width) -> (width: CGFloat, color: CGColor) {
            (width: width, color: Colors.Dynamic.border.cgColor)
        }

        static func gold(width: CGFloat = Border.accentWidth) -> (width: CGFloat, color: CGColor) {
            (width: width, color: Colors.Core.goldLeaf.cgColor)
        }
    }

    enum Animation {
        static let quick: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.5
        static let reveal: TimeInterval = 0.8
        static let springDamping: CGFloat = 0.7
        static let springVelocity: CGFloat = 0.5
    }

    enum Glass {
        static func effect(interactive: Bool = false) -> UIVisualEffect {
            if #available(iOS 26.0, *) {
                let glass = UIGlassEffect()
                glass.isInteractive = interactive
                return glass
            }
            return UIBlurEffect(style: .systemThinMaterialDark)
        }

        static func makeCard(cornerRadius: CGFloat = CornerRadius.large, interactive: Bool = false) -> UIVisualEffectView {
            let card = UIVisualEffectView(effect: effect(interactive: interactive))
            card.layer.cornerRadius = cornerRadius
            card.layer.cornerCurve = .continuous
            card.clipsToBounds = true
            return card
        }
    }

    enum ComponentStyle {
        static func applyPapyrusCard(to view: UIView, elevated: Bool = false) {
            view.backgroundColor = Colors.Component.Card.background
            view.layer.cornerRadius = CornerRadius.large
            view.layer.cornerCurve = .continuous
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

        static func applyPapyrusButton(to button: UIButton, style: ButtonStyle = .primary) {
            var config = UIButton.Configuration.filled()
            switch style {
            case .primary:
                config.baseBackgroundColor = Colors.Component.Button.primaryBackground
                config.baseForegroundColor = Colors.Component.Button.primaryForeground
            case .secondary:
                config.baseBackgroundColor = Colors.Component.Button.secondaryBackground
                config.baseForegroundColor = Colors.Component.Button.secondaryForeground
            case .tertiary:
                config.baseBackgroundColor = Colors.Component.Button.tertiaryBackground
                config.baseForegroundColor = Colors.Component.Button.tertiaryForeground
            case .destructive:
                config.baseBackgroundColor = Colors.Component.Button.destructiveBackground
                config.baseForegroundColor = Colors.Component.Button.destructiveForeground
            }
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
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

extension UIColor {
    /// A color from a 0xRRGGBB literal.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

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

extension UILabel {
    func applyPapyrusStyle(_ style: TextStyle) {
        adjustsFontForContentSizeCategory = true
        switch style {
        case .largeTitle:
            font = PapyrusDesignSystem.Typography.largeTitle()
            textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        case .title1:
            font = PapyrusDesignSystem.Typography.title1()
            textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        case .title2:
            font = PapyrusDesignSystem.Typography.title2()
            textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        case .title3:
            font = PapyrusDesignSystem.Typography.title3()
            textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        case .headline:
            font = PapyrusDesignSystem.Typography.headline()
            textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        case .body:
            font = PapyrusDesignSystem.Typography.body()
            textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        case .callout:
            font = PapyrusDesignSystem.Typography.callout()
            textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        case .subheadline:
            font = PapyrusDesignSystem.Typography.subheadline()
            textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        case .footnote:
            font = PapyrusDesignSystem.Typography.footnote()
            textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        case .caption:
            font = PapyrusDesignSystem.Typography.caption1()
            textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        }
    }

    enum TextStyle {
        case largeTitle, title1, title2, title3, headline, body, callout, subheadline, footnote, caption
    }
}
