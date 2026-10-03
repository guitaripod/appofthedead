import UIKit

/// Shown once, after the very first completed lesson, so the "Remind me daily" card has a calm
/// moment of its own instead of competing with the next lesson for attention.
final class LessonCompleteViewController: UIViewController {

    struct Summary {
        let lessonTitle: String
        let correctAnswers: Int
        let totalQuestions: Int
        let xpReward: Int
    }

    private let summary: Summary
    private let reminder: DailyReminder
    private let onContinue: () -> Void
    private let onClose: () -> Void

    private weak var scrollView: UIScrollView!
    private let contentStack = UIStackView()
    private let reminderCard: ReminderOfferCardView

    init(summary: Summary, reminder: DailyReminder = .shared, onContinue: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.summary = summary
        self.reminder = reminder
        self.onContinue = onContinue
        self.onClose = onClose
        self.reminderCard = ReminderOfferCardView(state: .offer(time: reminder.time))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Papyrus.background
        setupNavigationBar()
        setupContent()
        setupFooter()
        bindReminderCard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            primaryAction: UIAction { [weak self] _ in self?.onClose() }
        )
        closeButton.tintColor = .label
        closeButton.accessibilityLabel = String(localized: "Close")
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupContent() {
        let sealView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        sealView.tintColor = UIColor.Papyrus.gold
        sealView.contentMode = .scaleAspectFit
        sealView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72, weight: .regular)
        sealView.isAccessibilityElement = false

        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Lesson Complete")
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: PapyrusDesignSystem.Typography.title1())
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header

        let lessonLabel = UILabel()
        lessonLabel.text = summary.lessonTitle
        lessonLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17))
        lessonLabel.textColor = UIColor.Papyrus.secondaryText
        lessonLabel.textAlignment = .center
        lessonLabel.numberOfLines = 0
        lessonLabel.adjustsFontForContentSizeCategory = true

        let statsStack = UIStackView(arrangedSubviews: [
            makeStatPill(String(localized: "\(summary.correctAnswers) of \(summary.totalQuestions) correct")),
            makeStatPill(String(localized: "+\(summary.xpReward) XP"))
        ])
        statsStack.axis = .horizontal
        statsStack.spacing = 10
        statsStack.alignment = .center
        statsStack.distribution = .fillProportionally

        let heroStack = UIStackView(arrangedSubviews: [sealView, titleLabel, lessonLabel, statsStack])
        heroStack.axis = .vertical
        heroStack.alignment = .center
        heroStack.spacing = 12
        heroStack.setCustomSpacing(20, after: lessonLabel)

        contentStack.axis = .vertical
        contentStack.spacing = 32
        contentStack.alignment = .fill
        contentStack.addArrangedSubview(heroStack)
        contentStack.addArrangedSubview(reminderCard)
        let scrollView = CenteredScrollView(content: contentStack)
        self.scrollView = scrollView
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupFooter() {
        let continueButton = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: continueButton, style: .primary)
        var configuration = continueButton.configuration
        configuration?.title = String(localized: "Continue")
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        continueButton.configuration = configuration
        continueButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self?.onContinue()
        }, for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)

        let preferredWidth = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            preferredWidth,
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func bindReminderCard() {
        reminderCard.onRemindTapped = { [weak self] in
            self?.enableReminder()
        }
        reminderCard.onOpenSettingsTapped = {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
    }

    private func enableReminder() {
        AppLogger.logUserAction("reminderOfferAccepted", parameters: [:], logger: AppLogger.general)
        reminder.enable { [weak self] granted in
            guard let self else { return }
            UIView.animate(withDuration: PapyrusDesignSystem.Animation.normal) {
                self.reminderCard.render(granted ? .enabled(time: self.reminder.time) : .denied)
                self.view.layoutIfNeeded()
            }
            UINotificationFeedbackGenerator().notificationOccurred(granted ? .success : .warning)
            UIAccessibility.post(notification: .layoutChanged, argument: self.reminderCard)
        }
    }

    private func makeStatPill(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        label.textColor = UIColor.Papyrus.primaryText
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.backgroundColor = UIColor.Papyrus.cardBackground
        pill.layer.cornerRadius = PapyrusDesignSystem.CornerRadius.medium
        pill.layer.borderWidth = 1
        pill.layer.borderColor = UIColor.Papyrus.aged.cgColor
        pill.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        return pill
    }
}
