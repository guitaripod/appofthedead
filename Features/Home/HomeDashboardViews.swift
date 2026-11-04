import UIKit
import AppOfTheDeadCore

/// What the top of Home shows besides the paths.
struct HomeDashboard {
    var xp: Int = 0
    var streak: Int = 0
    var premiumWeekDaysLeft: Int?
    var verdict: Verdict?
    var omen: DailyOmen?
    var omenAnswer: String?
}

/// A card surface of the night look: raised, hairline-bordered, continuous corners.
class DashboardCardView: UIView {
    let content = UIStackView()

    init(accent: UIColor? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = PapyrusDesignSystem.Colors.Core.surface
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = (accent?.withAlphaComponent(0.3) ?? UIColor.white.withAlphaComponent(0.1)).cgColor
        content.axis = .vertical
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The Judgment on Home: an invitation before the first verdict, the Soul Card after it.
final class JudgmentHomeCard: DashboardCardView {
    var onOpen: (() -> Void)?
    var onRetake: (() -> Void)?

    init(verdict: Verdict?) {
        super.init(accent: PapyrusDesignSystem.Colors.Core.goldLeaf)
        if let verdict {
            buildSoulCard(verdict)
        } else {
            buildInvitation()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildInvitation() {
        let glyph = UIImageView(image: UIImage(systemName: "scalemass.fill"))
        glyph.tintColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        glyph.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        glyph.setContentHuggingPriority(.required, for: .horizontal)
        let title = makeSerifLabel(String(localized: "Where will your soul go?"), size: 21, alignment: .natural)
        let body = makeBodyLabel(String(localized: "Six traditions weigh your heart in two minutes."), size: 15, alignment: .natural)
        let text = UIStackView(arrangedSubviews: [title, body])
        text.axis = .vertical
        text.spacing = 4
        let row = UIStackView(arrangedSubviews: [glyph, text])
        row.spacing = 14
        row.alignment = .center
        content.addArrangedSubview(row)
        let button = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: button, style: .primary)
        button.configuration?.title = String(localized: "Face the Judgment")
        button.addAction(UIAction { [weak self] _ in self?.onRetake?() }, for: .touchUpInside)
        content.setCustomSpacing(16, after: row)
        content.addArrangedSubview(button)
    }

    private func buildSoulCard(_ verdict: Verdict) {
        let eyebrow = makeEyebrowLabel(String(localized: "Your Soul Card"), alignment: .natural)
        let name = makeSerifLabel(JudgmentCopy.archetypeName(verdict.archetype), size: 24, weight: .bold, color: PapyrusDesignSystem.Colors.Core.goldLeaf, alignment: .natural)
        let realms = UIStackView(arrangedSubviews: verdict.realms.map(realmChip))
        realms.axis = .horizontal
        realms.spacing = 8
        realms.distribution = .fillEqually
        content.addArrangedSubview(eyebrow)
        content.addArrangedSubview(name)
        content.setCustomSpacing(14, after: name)
        content.addArrangedSubview(realms)

        let open = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: open, style: .tertiary)
        open.configuration?.title = String(localized: "View and Share")
        open.configuration?.image = UIImage(systemName: "square.and.arrow.up")
        open.configuration?.imagePadding = 6
        open.addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
        let retake = UIButton(type: .system)
        var retakeConfiguration = UIButton.Configuration.plain()
        retakeConfiguration.title = String(localized: "Retake")
        retakeConfiguration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        retake.configuration = retakeConfiguration
        retake.addAction(UIAction { [weak self] _ in self?.onRetake?() }, for: .touchUpInside)
        retake.setContentHuggingPriority(.required, for: .horizontal)
        let buttons = UIStackView(arrangedSubviews: [open, retake])
        buttons.spacing = 8
        content.setCustomSpacing(16, after: realms)
        content.addArrangedSubview(buttons)

        isAccessibilityElement = false
        realms.isAccessibilityElement = true
        realms.accessibilityLabel = verdict.realms
            .map { "\(JudgmentCopy.tradition($0.tradition)): \(JudgmentCopy.realmName($0))" }
            .joined(separator: ", ")
    }

    private func realmChip(_ realm: Realm) -> UIView {
        let color = JudgmentCopy.color(for: realm.tradition)
        let chip = UIView()
        chip.backgroundColor = color.withAlphaComponent(0.13)
        chip.layer.cornerRadius = 12
        chip.layer.cornerCurve = .continuous
        let icon = UIImageView(image: UIImage(systemName: JudgmentCopy.realmSymbol(realm)))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        icon.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(icon)
        NSLayoutConstraint.activate([
            chip.heightAnchor.constraint(equalToConstant: 40),
            icon.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
        ])
        return chip
    }
}

/// The day's question, answered in place: the choice lights up, the right answer shows, and the explanation follows.
final class DailyOmenCard: DashboardCardView {
    var onAnswer: ((String) -> Void)?
    var onOpenPath: (() -> Void)?

    private let omen: DailyOmen
    private let color: UIColor

    init(omen: DailyOmen, answer: String?) {
        self.omen = omen
        color = PapyrusDesignSystem.Colors.tradition(omen.pathColor)
        super.init(accent: color)
        build(answer: answer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build(answer: String?) {
        let eyebrow = makeEyebrowLabel("\(String(localized: "Daily Omen")) · \(omen.pathName)", color: color, alignment: .natural)
        let question = makeSerifLabel(omen.question, size: 19, weight: .semibold, alignment: .natural)
        content.addArrangedSubview(eyebrow)
        content.addArrangedSubview(question)
        content.setCustomSpacing(14, after: question)

        let options = UIStackView()
        options.axis = omen.options.count == 2 ? .horizontal : .vertical
        options.distribution = omen.options.count == 2 ? .fillEqually : .fill
        options.spacing = 8
        for option in omen.options {
            options.addArrangedSubview(optionButton(option, answer: answer))
        }
        content.addArrangedSubview(options)

        guard let answer else { return }
        let correct = omen.isCorrect(answer)
        let verdict = makeSerifLabel(
            correct ? String(localized: "Well read. +\(DailyOmenService.xpReward) XP") : String(localized: "Not this time. Your streak lives on."),
            size: 17,
            color: correct ? PapyrusDesignSystem.Colors.Core.scarabGreen : PapyrusDesignSystem.Colors.Dynamic.secondaryText,
            alignment: .natural
        )
        let explanation = makeBodyLabel(omen.explanation, size: 15, alignment: .natural)
        let more = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Explore \(omen.pathName)")
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        configuration.baseForegroundColor = color
        configuration.contentInsets = .zero
        more.configuration = configuration
        more.contentHorizontalAlignment = .leading
        more.addAction(UIAction { [weak self] _ in self?.onOpenPath?() }, for: .touchUpInside)
        content.setCustomSpacing(14, after: options)
        content.addArrangedSubview(verdict)
        content.addArrangedSubview(explanation)
        content.setCustomSpacing(10, after: explanation)
        content.addArrangedSubview(more)
    }

    private func optionButton(_ option: String, answer: String?) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = displayText(for: option)
        configuration.titleAlignment = omen.options.count == 2 ? .center : .leading
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = PapyrusDesignSystem.Typography.sans(15, weight: .medium, textStyle: .subheadline)
            return outgoing
        }
        let base = PapyrusDesignSystem.Colors.Core.surfaceRaised
        configuration.baseBackgroundColor = base
        configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        if let answer {
            if omen.isCorrect(option) {
                configuration.baseBackgroundColor = PapyrusDesignSystem.Colors.Core.scarabGreen.withAlphaComponent(0.25)
                configuration.image = UIImage(systemName: "checkmark.circle.fill")
            } else if option == answer {
                configuration.baseBackgroundColor = PapyrusDesignSystem.Colors.Core.tombRed.withAlphaComponent(0.25)
                configuration.image = UIImage(systemName: "xmark.circle.fill")
            } else {
                configuration.baseForegroundColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
            }
            configuration.imagePadding = 8
            button.isUserInteractionEnabled = false
        }
        button.configuration = configuration
        button.contentHorizontalAlignment = omen.options.count == 2 ? .center : .leading
        button.addAction(UIAction { [weak self] _ in
            self?.onAnswer?(option)
        }, for: .touchUpInside)
        return button
    }

    private func displayText(for option: String) -> String {
        switch option {
        case "true": return String(localized: "True")
        case "false": return String(localized: "False")
        default: return option
        }
    }
}

/// The Premium Week's countdown, in gold, where the person's stats are.
final class PremiumWeekChip: UIControl {
    init(daysLeft: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.14)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = PapyrusDesignSystem.Colors.Core.goldLeaf.withAlphaComponent(0.45).cgColor
        let icon = UIImageView(image: UIImage(systemName: "door.left.hand.open"))
        icon.tintColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let label = UILabel()
        label.text = String(localized: "Premium Week · \(daysLeft) days left")
        label.font = PapyrusDesignSystem.Typography.sans(13, weight: .semibold, textStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PapyrusDesignSystem.Colors.Core.goldLeaf
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.spacing = 6
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = label.text
        accessibilityHint = String(localized: "Shows the plans")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
