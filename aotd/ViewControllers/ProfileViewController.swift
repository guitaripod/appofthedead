import UIKit

final class ProfileViewController: UIViewController {

    private let viewModel: ProfileViewModel

    let scrollView = UIScrollView()
    let contentStackView = UIStackView()

    let profileHeaderView = UIView()
    let xpRingView = XPRingView()
    let avatarImageView = UIImageView()
    let nameLabel = UILabel()
    let levelLabel = UILabel()
    let xpLabel = UILabel()
    private let rankChipView = UIView()
    private let renameButton = UIButton(type: .system)
    private let heroGradientLayer = CAGradientLayer()

    let streakCard = StreakFlameCard()

    let statsContainerView = UIView()
    let statsStackView = UIStackView()
    private let accuracyTile = StatTileView()
    private let studyTimeTile = StatTileView()
    private let masteredTile = StatTileView()
    private let awakenedTile = StatTileView()

    private let hallsCountPill = CountPillView()
    private let hallsSummaryLabel = UILabel()
    lazy var pathTrophyCollectionView = createPathTrophyCollectionView()

    let achievementsHeaderLabel = UILabel()
    private let honorsCountPill = CountPillView()
    lazy var achievementsCollectionView = createAchievementsCollectionView()

    private let ascendCard = UIView()

    var ringWidthConstraint: NSLayoutConstraint?
    var ringHeightConstraint: NSLayoutConstraint?
    var avatarWidthConstraint: NSLayoutConstraint?
    var avatarHeightConstraint: NSLayoutConstraint?
    var contentMaxWidthConstraint: NSLayoutConstraint?

    private var hasAnimatedStreak = false
    static let uncappedContentWidth: CGFloat = 100000

    private static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGameCenterButton()
        bindViewModel()

        updateLayoutForIPad()

        viewModel.loadData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdate),
            name: Notification.Name("UserDataDidUpdate"),
            object: nil
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
           traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            updateLayoutForIPad()
        }

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            refreshDynamicColors()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradientLayer.frame = profileHeaderView.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "Profile"
        hasAnimatedStreak = false
        viewModel.loadData()
    }

    private func setupGameCenterButton() {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "trophy.fill"),
            style: .plain,
            target: self,
            action: #selector(showGameCenter)
        )
        button.tintColor = UIColor.Papyrus.gold
        button.accessibilityLabel = "Game Center"
        button.accessibilityHint = "Opens leaderboards and honors"
        navigationItem.rightBarButtonItem = button
    }

    @objc private func showGameCenter() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        GameCenterManager.shared.presentDashboard(from: self)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background

        setupScrollView()
        setupProfileHeader()
        setupStreakSection()
        setupStatsSection()
        setupHallsSection()
        setupAchievementsSection()
        setupUpgradeSection()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.alignment = .fill
        scrollView.addSubview(contentStackView)

        let pageWidth = contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        pageWidth.priority = .defaultHigh
        let maxWidth = contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: Self.uncappedContentWidth)
        contentMaxWidthConstraint = maxWidth

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            pageWidth,
            maxWidth
        ])
    }

    private func setupProfileHeader() {
        profileHeaderView.applyPapyrusCard(elevated: true)
        profileHeaderView.layer.cornerCurve = .continuous

        heroGradientLayer.colors = heroGradientColors()
        heroGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        heroGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        heroGradientLayer.cornerRadius = PapyrusDesignSystem.CornerRadius.large
        heroGradientLayer.masksToBounds = true
        profileHeaderView.layer.insertSublayer(heroGradientLayer, at: 0)
        contentStackView.addArrangedSubview(profileHeaderView)

        avatarImageView.backgroundColor = UIColor.Papyrus.hieroglyphBlue
        avatarImageView.layer.cornerRadius = 32
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: "person.fill")
        avatarImageView.tintColor = UIColor.Papyrus.beige
        avatarImageView.isAccessibilityElement = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        xpRingView.translatesAutoresizingMaskIntoConstraints = false
        xpRingView.isAccessibilityElement = true
        xpRingView.accessibilityLabel = "Experience progress"
        xpRingView.addSubview(avatarImageView)

        nameLabel.font = UIFont(name: "Papyrus", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = UIColor.Papyrus.primaryText
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.6
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        renameButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        renameButton.tintColor = UIColor.Papyrus.secondaryText
        renameButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        renameButton.accessibilityLabel = "Edit name"
        renameButton.accessibilityHint = "Changes your Seeker name"
        renameButton.setContentHuggingPriority(.required, for: .horizontal)
        renameButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        renameButton.addTarget(self, action: #selector(renameTapped), for: .touchUpInside)

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, renameButton])
        nameRow.axis = .horizontal
        nameRow.spacing = 6
        nameRow.alignment = .center

        levelLabel.font = PapyrusDesignSystem.Typography.subheadline(weight: .semibold)
        levelLabel.textColor = UIColor.Papyrus.gold
        levelLabel.numberOfLines = 1
        levelLabel.adjustsFontSizeToFitWidth = true
        levelLabel.minimumScaleFactor = 0.7
        levelLabel.translatesAutoresizingMaskIntoConstraints = false

        rankChipView.backgroundColor = UIColor.Papyrus.gold.withAlphaComponent(0.15)
        rankChipView.layer.cornerRadius = 12
        rankChipView.layer.borderWidth = 1
        rankChipView.layer.borderColor = UIColor.Papyrus.gold.cgColor
        rankChipView.addSubview(levelLabel)

        xpLabel.font = PapyrusDesignSystem.Typography.footnote()
        xpLabel.textColor = UIColor.Papyrus.secondaryText

        let textStack = UIStackView(arrangedSubviews: [nameRow, rankChipView, xpLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 8

        let heroStack = UIStackView(arrangedSubviews: [xpRingView, textStack])
        heroStack.axis = .horizontal
        heroStack.alignment = .center
        heroStack.spacing = 16
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(heroStack)

        let ringWidth = xpRingView.widthAnchor.constraint(equalToConstant: 96)
        let ringHeight = xpRingView.heightAnchor.constraint(equalToConstant: 96)
        let avatarWidth = avatarImageView.widthAnchor.constraint(equalToConstant: 64)
        let avatarHeight = avatarImageView.heightAnchor.constraint(equalToConstant: 64)
        ringWidthConstraint = ringWidth
        ringHeightConstraint = ringHeight
        avatarWidthConstraint = avatarWidth
        avatarHeightConstraint = avatarHeight

        NSLayoutConstraint.activate([
            heroStack.topAnchor.constraint(equalTo: profileHeaderView.topAnchor, constant: 20),
            heroStack.bottomAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: -20),
            heroStack.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: 20),
            heroStack.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -20),

            ringWidth, ringHeight, avatarWidth, avatarHeight,
            avatarImageView.centerXAnchor.constraint(equalTo: xpRingView.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: xpRingView.centerYAnchor),

            levelLabel.topAnchor.constraint(equalTo: rankChipView.topAnchor, constant: 4),
            levelLabel.bottomAnchor.constraint(equalTo: rankChipView.bottomAnchor, constant: -4),
            levelLabel.leadingAnchor.constraint(equalTo: rankChipView.leadingAnchor, constant: 12),
            levelLabel.trailingAnchor.constraint(equalTo: rankChipView.trailingAnchor, constant: -12)
        ])
    }

    private func setupStreakSection() {
        streakCard.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(streakCard)
    }

    private func setupStatsSection() {
        statsContainerView.applyPapyrusCard()
        statsContainerView.layer.cornerCurve = .continuous
        contentStackView.addArrangedSubview(statsContainerView)

        let titleLabel = UILabel()
        titleLabel.text = "The Scribe's Ledger"
        titleLabel.font = PapyrusDesignSystem.Typography.title2()
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        statsContainerView.addSubview(titleLabel)

        statsStackView.axis = .vertical
        statsStackView.spacing = 12
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsContainerView.addSubview(statsStackView)

        let firstRow = UIStackView(arrangedSubviews: [accuracyTile, studyTimeTile])
        let secondRow = UIStackView(arrangedSubviews: [masteredTile, awakenedTile])
        for row in [firstRow, secondRow] {
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 12
            statsStackView.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: statsContainerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor, constant: -20),

            statsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor, constant: -16),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: -16)
        ])
    }

    private func setupHallsSection() {
        let titleLabel = UILabel()
        titleLabel.text = "Halls of the Dead"
        titleLabel.font = PapyrusDesignSystem.Typography.title2()
        titleLabel.textColor = UIColor.Papyrus.primaryText

        let headerRow = makeHeaderRow(titleLabel: titleLabel, pill: hallsCountPill)

        hallsSummaryLabel.font = PapyrusDesignSystem.Typography.footnote()
        hallsSummaryLabel.textColor = UIColor.Papyrus.secondaryText
        hallsSummaryLabel.numberOfLines = 0

        let section = UIStackView(arrangedSubviews: [headerRow, pathTrophyCollectionView, hallsSummaryLabel])
        section.axis = .vertical
        section.spacing = 12
        contentStackView.addArrangedSubview(section)

        pathTrophyCollectionView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }

    private func setupAchievementsSection() {
        achievementsHeaderLabel.text = "Hall of Honors"
        achievementsHeaderLabel.font = PapyrusDesignSystem.Typography.title2()
        achievementsHeaderLabel.textColor = UIColor.Papyrus.primaryText

        let headerRow = makeHeaderRow(titleLabel: achievementsHeaderLabel, pill: honorsCountPill)

        let section = UIStackView(arrangedSubviews: [headerRow, achievementsCollectionView])
        section.axis = .vertical
        section.spacing = 12
        contentStackView.addArrangedSubview(section)

        achievementsCollectionView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }

    private func makeHeaderRow(titleLabel: UILabel, pill: CountPillView) -> UIStackView {
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [titleLabel, pill])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        return row
    }

    private func setupUpgradeSection() {
        ascendCard.applyPapyrusCard()
        ascendCard.layer.cornerCurve = .continuous
        ascendCard.layer.borderWidth = 2
        ascendCard.layer.borderColor = UIColor.Papyrus.gold.cgColor
        ascendCard.isHidden = true

        let iconView = UIImageView(image: UIImage(systemName: "infinity.circle.fill"))
        iconView.tintColor = UIColor.Papyrus.mysticPurple
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Ascend to The Eternal"
        titleLabel.font = PapyrusDesignSystem.Typography.headline(weight: .semibold)
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.text = "Unlock every path, unlimited Oracle, and the full Hall of Mastery"
        descriptionLabel.font = PapyrusDesignSystem.Typography.footnote()
        descriptionLabel.textColor = UIColor.Papyrus.secondaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        let upgradeButton = UIButton(type: .system)
        upgradeButton.setTitle("View Paths to Ascension", for: .normal)
        PapyrusDesignSystem.ComponentStyle.applyPapyrusButton(to: upgradeButton, style: .primary)
        upgradeButton.accessibilityLabel = "Ascend to The Eternal, view subscription options"
        upgradeButton.addTarget(self, action: #selector(showPaywall), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, descriptionLabel, upgradeButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        ascendCard.addSubview(stack)

        contentStackView.addArrangedSubview(ascendCard)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 40),
            upgradeButton.heightAnchor.constraint(equalToConstant: 48),
            stack.topAnchor.constraint(equalTo: ascendCard.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: ascendCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: ascendCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: ascendCard.bottomAnchor, constant: -20)
        ])
    }

    @objc private func showPaywall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let paywall = PaywallViewController(reason: .generalUpgrade)
        present(paywall, animated: true)
    }

    @objc private func renameTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        let alert = UIAlertController(title: "Your Seeker Name", message: "How shall the scrolls record you?", preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            textField.text = self?.viewModel.displayName
            textField.placeholder = ProfileViewModel.defaultDisplayName
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let name = alert?.textFields?.first?.text else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.viewModel.updateDisplayName(name)
        })
        present(alert, animated: true)
    }

    private func createPathTrophyCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 130, height: 150)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PathTrophyCell.self, forCellWithReuseIdentifier: "PathTrophyCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }

    private func createAchievementsCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AchievementBadgeCell.self, forCellWithReuseIdentifier: "AchievementBadgeCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }

    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
    }

    private func updateUI() {
        guard let user = viewModel.user else { return }

        nameLabel.text = viewModel.displayName
        levelLabel.text = "Level \(user.currentLevel) · \(viewModel.rankTitle)"

        let xpIntoLevel = user.totalXP % 100
        xpRingView.setProgress(CGFloat(xpIntoLevel) / 100.0, animated: true)
        xpLabel.text = "\(xpIntoLevel) / 100 XP to ascend"
        xpRingView.accessibilityValue = "Level \(user.currentLevel), \(xpIntoLevel) of 100 XP to next level"

        let memberSince = Self.memberSinceFormatter.string(from: user.createdAt)
        streakCard.configure(streakDays: user.streakDays, multiplier: viewModel.streakMultiplier, memberSince: memberSince)
        if user.streakDays > 0 && !hasAnimatedStreak {
            hasAnimatedStreak = true
            streakCard.pulse()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        updateStatsTiles(user: user, memberSince: memberSince)
        updateHallsSection()
        updateHonorsSection()

        ascendCard.isHidden = user.hasUltimateAccess()

        pathTrophyCollectionView.reloadData()
        achievementsCollectionView.reloadData()
    }

    private func updateStatsTiles(user: User, memberSince: String) {
        if let accuracy = viewModel.accuracy {
            accuracyTile.configure(systemIcon: "checkmark.seal.fill", value: "\(Int((accuracy * 100).rounded()))%", caption: "Accuracy")
        } else {
            accuracyTile.configure(systemIcon: "checkmark.seal.fill", value: "—", caption: "Accuracy")
        }
        studyTimeTile.configure(systemIcon: "hourglass", value: Self.studyTimeString(viewModel.totalStudyTime), caption: "Time in the Duat")
        masteredTile.configure(systemIcon: "crown.fill", value: "\(viewModel.masteredPathsCount)", caption: "Realms Mastered")
        awakenedTile.configure(systemIcon: "sun.max.fill", value: memberSince, caption: "Awakened")
    }

    private func updateHallsSection() {
        let summary = viewModel.journeySummary
        hallsCountPill.setText("\(summary.gatesWalked) of \(summary.gatesTotal)")

        if viewModel.pathJourney.isEmpty {
            pathTrophyCollectionView.isHidden = true
            hallsSummaryLabel.text = "Begin your first path to walk the gates of the Duat."
        } else {
            pathTrophyCollectionView.isHidden = false
            hallsSummaryLabel.text = "You have walked \(summary.gatesWalked) of \(summary.gatesTotal) gates · \(summary.mastered) mastered"
        }
    }

    private func updateHonorsSection() {
        let earned = viewModel.userAchievements.filter { $0.isCompleted }.count
        honorsCountPill.setText("\(earned) / \(viewModel.achievements.count) earned")
    }

    private func refreshDynamicColors() {
        heroGradientLayer.colors = heroGradientColors()
        xpRingView.updateColors()
        streakCard.updateColors()
        hallsCountPill.updateColors()
        honorsCountPill.updateColors()
        profileHeaderView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        statsContainerView.layer.borderColor = PapyrusDesignSystem.Colors.Dynamic.border.cgColor
        pathTrophyCollectionView.reloadData()
        achievementsCollectionView.reloadData()
    }

    private func heroGradientColors() -> [CGColor] {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let start = UIColor.Papyrus.gold.withAlphaComponent(isDark ? 0.28 : 0.16)
        let end = UIColor.Papyrus.burnishedGold.withAlphaComponent(isDark ? 0.10 : 0.05)
        return [start.cgColor, end.cgColor]
    }

    private static func studyTimeString(_ interval: TimeInterval) -> String {
        guard interval >= 60 else { return interval > 0 ? "<1m" : "0m" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: interval) ?? "0m"
    }

    @objc private func handleDataUpdate() {
        viewModel.loadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === pathTrophyCollectionView {
            return viewModel.pathJourney.count
        }
        return viewModel.sortedUserAchievements.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === pathTrophyCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PathTrophyCell", for: indexPath) as! PathTrophyCell
            cell.configure(with: viewModel.pathJourney[indexPath.item])
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementBadgeCell", for: indexPath) as! AchievementBadgeCell
        let userAchievement = viewModel.sortedUserAchievements[indexPath.item]
        if let achievement = viewModel.achievements.first(where: { $0.id == userAchievement.achievementId }) {
            cell.configure(with: achievement, userAchievement: userAchievement)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if collectionView === pathTrophyCollectionView {
            showPathDetail(viewModel.pathJourney[indexPath.item])
            return
        }

        let userAchievement = viewModel.sortedUserAchievements[indexPath.item]
        if let achievement = viewModel.achievements.first(where: { $0.id == userAchievement.achievementId }) {
            showAchievementDetail(achievement: achievement, userAchievement: userAchievement)
        }
    }

    private func showPathDetail(_ item: PathJourneyItem) {
        let percent = Int((item.progressFraction * 100).rounded())
        var lines = [
            "Status: \(item.statusLabel)",
            "\(item.earnedXP) / \(item.totalXP) XP · \(percent)%",
            "Attempts: \(item.totalAttempts)"
        ]
        if let completedAt = item.completedAt {
            lines.append("Sealed \(Self.memberSinceFormatter.string(from: completedAt))")
        }
        PapyrusAlert.showSimpleAlert(title: item.name, message: lines.joined(separator: "\n"), from: self)
    }

    private func showAchievementDetail(achievement: Achievement, userAchievement: UserAchievement) {
        let progressText = userAchievement.isCompleted ? "Completed!" : "Progress: \(Int(userAchievement.progress * 100))%"
        PapyrusAlert.showSimpleAlert(
            title: achievement.name,
            message: "\(achievement.description)\n\n\(progressText)",
            from: self
        )
    }
}
