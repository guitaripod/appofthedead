import AppOfTheDeadCore
import UIKit

/// One-time first-run screen: what the app offers in three lines, and a single button that drops
/// the user straight into the free first lesson.
final class WelcomeViewController: UIViewController {

    private struct ValuePoint {
        let symbol: String
        let title: String
        let detail: String
    }

    /// The paths offered as answers to "which tradition are you most curious about", in this order.
    private static let curiosityPathIds = [
        "norse", "egyptian-afterlife", "greek-underworld", "buddhism",
        "hinduism", "christianity", "islam", "aztec-mictlan"
    ]

    private let onStart: () -> Void
    private var curiosityButtons: [(id: String, button: UIButton)] = []

    private weak var scrollView: UIScrollView!
    private let contentStack = UIStackView()

    private var valuePoints: [ValuePoint] {
        [
            ValuePoint(
                symbol: "book.pages",
                title: String(localized: "Bite-sized lessons"),
                detail: String(localized: "Learn how cultures imagine the afterlife, a few minutes at a time.")
            ),
            ValuePoint(
                symbol: "checkmark.seal",
                title: String(localized: "Quizzes that stick"),
                detail: String(localized: "Test yourself, earn XP and unlock achievements along the way.")
            ),
            ValuePoint(
                symbol: "sparkles",
                title: String(localized: "Ask the Oracle"),
                detail: String(localized: "Question a deity from each tradition. Answers are generated privately on your iPhone.")
            )
        ]
    }

    init(onStart: @escaping () -> Void) {
        self.onStart = onStart
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let foldAvoiding = FoldAvoidingLayout()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Papyrus.background
        foldAvoiding.install(in: view)
        setupContent()
        setupFooter()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        foldAvoiding.update(in: view)
    }

    private func setupContent() {
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 28
        contentStack.addArrangedSubview(makeHeader())
        valuePoints.forEach { contentStack.addArrangedSubview(makeRow(for: $0)) }
        if let curiosity = makeCuriositySection() {
            contentStack.addArrangedSubview(curiosity)
        }
        contentStack.addArrangedSubview(makeCaption())
        contentStack.setCustomSpacing(36, after: contentStack.arrangedSubviews[0])
        let scrollView = CenteredScrollView(content: contentStack)
        self.scrollView = scrollView
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: foldAvoiding.guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: foldAvoiding.guide.trailingAnchor)
        ])
    }

    private func setupFooter() {
        let startButton = UIButton(type: .system)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: startButton, style: .primary)
        var configuration = startButton.configuration
        configuration?.title = String(localized: "Start Your First Lesson")
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        startButton.configuration = configuration
        startButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self?.onStart()
        }, for: .touchUpInside)

        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

        let preferredWidth = startButton.widthAnchor.constraint(equalTo: foldAvoiding.guide.widthAnchor, constant: -56)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -12),
            startButton.centerXAnchor.constraint(equalTo: foldAvoiding.guide.centerXAnchor),
            startButton.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            preferredWidth,
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func makeCaption() -> UILabel {
        let label = UILabel()
        label.text = String(localized: "Judaism is free to explore. No account needed.")
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13))
        label.textColor = UIColor.Papyrus.tertiaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func makeHeader() -> UIView {
        let emblemView = UIImageView(image: UIImage(systemName: "moon.stars.fill"))
        emblemView.tintColor = UIColor.Papyrus.gold
        emblemView.contentMode = .scaleAspectFit
        emblemView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        emblemView.isAccessibilityElement = false

        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Welcome to App of the Dead")
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: PapyrusDesignSystem.Typography.title1())
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header

        let subtitleLabel = UILabel()
        subtitleLabel.text = String(localized: "How do the world's religions picture what comes after death?")
        subtitleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17))
        subtitleLabel.textColor = UIColor.Papyrus.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [emblemView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        return stack
    }

    /// "Which tradition are you most curious about?" with one button per path. The answer is optional and only shapes
    /// the offer after the first lesson; nil when the content has none of the paths.
    private func makeCuriositySection() -> UIView? {
        let systems = DatabaseManager.shared.loadBeliefSystems()
        let choices = Self.curiosityPathIds.compactMap { id in systems.first { $0.id == id } }
        guard !choices.isEmpty else { return nil }

        let questionLabel = UILabel()
        questionLabel.text = String(localized: "Which tradition are you most curious about?")
        questionLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        questionLabel.textColor = UIColor.Papyrus.primaryText
        questionLabel.numberOfLines = 0
        questionLabel.adjustsFontForContentSizeCategory = true
        questionLabel.accessibilityTraits = .header

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10
        for pair in stride(from: 0, to: choices.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.distribution = .fillEqually
            for system in choices[pair..<min(pair + 2, choices.count)] {
                let button = makeCuriosityButton(title: system.name, id: system.id)
                curiosityButtons.append((system.id, button))
                row.addArrangedSubview(button)
            }
            grid.addArrangedSubview(row)
        }

        let section = UIStackView(arrangedSubviews: [questionLabel, grid])
        section.axis = .vertical
        section.spacing = 12
        refreshCuriosityButtons()
        return section
    }

    private func makeCuriosityButton(title: String, id: String) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        configuration.background.cornerRadius = 14
        configuration.background.strokeWidth = 1.5
        let button = UIButton(configuration: configuration)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addAction(UIAction { [weak self] _ in
            UISelectionFeedbackGenerator().selectionChanged()
            CuriousPath.id = CuriousPath.id == id ? nil : id
            self?.refreshCuriosityButtons()
        }, for: .touchUpInside)
        return button
    }

    /// Fills the chosen button with gold and outlines the rest, and says which one is chosen to VoiceOver.
    private func refreshCuriosityButtons() {
        let chosen = CuriousPath.id
        for (id, button) in curiosityButtons {
            let isChosen = id == chosen
            var configuration = button.configuration ?? .plain()
            configuration.background.backgroundColor = isChosen ? UIColor.Papyrus.gold : UIColor.Papyrus.gold.withAlphaComponent(0.08)
            configuration.background.strokeColor = isChosen ? UIColor.Papyrus.gold : UIColor.Papyrus.gold.withAlphaComponent(0.45)
            configuration.baseForegroundColor = UIColor.Papyrus.primaryText
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = UIFontMetrics(forTextStyle: .subheadline)
                    .scaledFont(for: .systemFont(ofSize: 15, weight: isChosen ? .semibold : .regular))
                return attributes
            }
            button.configuration = configuration
            button.accessibilityTraits = isChosen ? [.button, .selected] : .button
        }
    }

    private func makeRow(for point: ValuePoint) -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: point.symbol))
        iconView.tintColor = UIColor.Papyrus.burnishedGold
        iconView.contentMode = .center
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.2)
        iconView.layer.cornerRadius = 22
        iconView.isAccessibilityElement = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = point.title
        titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        let detailLabel = UILabel()
        detailLabel.text = point.detail
        detailLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15))
        detailLabel.textColor = UIColor.Papyrus.secondaryText
        detailLabel.numberOfLines = 0
        detailLabel.adjustsFontForContentSizeCategory = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [iconView, textStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 16
        row.isAccessibilityElement = true
        row.accessibilityLabel = "\(point.title). \(point.detail)"

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44)
        ])
        return row
    }
}
