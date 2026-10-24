import UIKit

/// Inline, non-modal "Remind me daily" opt-in. It never presents anything itself: the owner
/// reacts to `onRemindTapped` and `onOpenSettingsTapped` and reports the outcome back via `render`.
final class ReminderOfferCardView: UIView {

    enum State: Equatable {
        case offer(time: Date)
        case enabled(time: Date)
        case denied
    }

    var onRemindTapped: (() -> Void)?
    var onOpenSettingsTapped: (() -> Void)?

    private(set) var state: State

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    init(state: State) {
        self.state = state
        super.init(frame: .zero)
        setupUI()
        render(state)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ newState: State) {
        state = newState
        switch newState {
        case .offer(let time):
            iconView.image = UIImage(systemName: "bell.badge")
            iconView.tintColor = UIColor.Papyrus.burnishedGold
            titleLabel.text = String(localized: "Remind me daily")
            detailLabel.text = String(localized: "A gentle nudge at \(Self.formatted(time)). You can change the time anytime in Settings.")
            configureAction(title: String(localized: "Remind Me"), isHidden: false)
        case .enabled(let time):
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = UIColor.Papyrus.scarabGreen
            titleLabel.text = String(localized: "You're all set")
            detailLabel.text = String(localized: "Reminder set for \(Self.formatted(time)) every day. You can change it anytime in Settings.")
            configureAction(title: nil, isHidden: true)
        case .denied:
            iconView.image = UIImage(systemName: "bell.slash")
            iconView.tintColor = UIColor.Papyrus.tombRed
            titleLabel.text = String(localized: "Notifications are off")
            detailLabel.text = String(localized: "Turn on notifications for App of the Dead in Settings to get daily reminders.")
            configureAction(title: String(localized: "Open Settings"), isHidden: false)
        }
        accessibilityLabel = [titleLabel.text, detailLabel.text].compactMap { $0 }.joined(separator: ". ")
    }

    private func configureAction(title: String?, isHidden: Bool) {
        actionButton.isHidden = isHidden
        guard let title else { return }
        var configuration = actionButton.configuration
        configuration?.title = title
        actionButton.configuration = configuration
    }

    private func setupUI() {
        backgroundColor = UIColor.Papyrus.cardBackground
        layer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        layer.borderWidth = PapyrusDesignSystem.Border.width
        layer.borderColor = UIColor.Papyrus.aged.cgColor
        isAccessibilityElement = false

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true

        titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header

        detailLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15))
        detailLabel.textColor = UIColor.Papyrus.secondaryText
        detailLabel.numberOfLines = 0
        detailLabel.adjustsFontForContentSizeCategory = true

        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: actionButton, style: .secondary)
        actionButton.addAction(UIAction { [weak self] _ in
            self?.handleActionTapped()
        }, for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let headerStack = UIStackView(arrangedSubviews: [iconView, textStack])
        headerStack.axis = .horizontal
        headerStack.alignment = .top
        headerStack.spacing = 12

        let contentStack = UIStackView(arrangedSubviews: [headerStack, actionButton])
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func handleActionTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch state {
        case .offer:
            onRemindTapped?()
        case .denied:
            onOpenSettingsTapped?()
        case .enabled:
            break
        }
    }

    private static func formatted(_ time: Date) -> String {
        time.formatted(date: .omitted, time: .shortened)
    }
}
