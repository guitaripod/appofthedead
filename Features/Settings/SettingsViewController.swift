import UIKit
import StoreKit
import MidgarCore
import MidgarPortal
import MidgarUI

/// Settings: the membership card and the Midgar card on top, then purchases, the person's journey, the Oracle and its
/// storage, sharing and support, what the app sends and its licenses, and deleting the Midgar ID. The list is
/// MidgarUI's settings screen in App of the Dead's night theme; the rows are rebuilt from ``SettingsViewModel``
/// whenever what they show changes.
final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel
    private let membershipCard = SettingsMembershipCard()
    private lazy var list = MidgarSettingsViewController(
        title: String(localized: "Settings"),
        sections: [],
        portalCardView: makeHeader(),
        theme: .aotd
    )

    private static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6746733380?action=write-review")!
    private static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PapyrusDesignSystem.Colors.Core.night
        embedList()
        membershipCard.onSeePlans = { [weak self] in self?.presentPlans() }
        viewModel.onChange = { [weak self] in self?.render() }
        observeChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = String(localized: "Settings")
        viewModel.reload()
    }

    private func embedList() {
        addChild(list)
        list.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(list.view)
        NSLayoutConstraint.activate([
            list.view.topAnchor.constraint(equalTo: view.topAnchor),
            list.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            list.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            list.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        list.didMove(toParent: self)
    }

    private func makeHeader() -> UIView {
        let header = UIStackView(arrangedSubviews: [membershipCard, MidgarEntryView(config: AotdMidgar.shared.portalConfig)])
        header.axis = .vertical
        return header
    }

    /// Purchases, a new Premium Week, a verdict and returning from the reminder screen all change what the rows show.
    private func observeChanges() {
        let names = [
            StoreManager.entitlementsUpdatedNotification,
            PremiumWeekPass.changedNotification,
            JudgmentStore.changedNotification,
        ]
        for name in names {
            NotificationCenter.default.addObserver(self, selector: #selector(stateChanged), name: name, object: nil)
        }
    }

    @objc private func stateChanged() {
        DispatchQueue.main.async { [weak self] in self?.viewModel.reload() }
    }

    private func render() {
        membershipCard.configure(viewModel.state.membership)
        list.sections = viewModel.sections.map(section)
    }

    private func section(_ model: SettingsSectionModel) -> MidgarSettingsSection {
        MidgarSettingsSection(id: model.kind.rawValue, title: title(of: model.kind), footer: footer(of: model.kind), rows: model.items.map(row))
    }

    private func title(of kind: SettingsSectionModel.Kind) -> String? {
        switch kind {
        case .membership: return String(localized: "Purchases")
        case .journey: return String(localized: "Your Journey")
        case .oracle: return String(localized: "The Oracle")
        case .spread: return String(localized: "Share & Support")
        case .about: return String(localized: "About")
        case .account: return nil
        }
    }

    private func footer(of kind: SettingsSectionModel.Kind) -> String? {
        switch kind {
        case .membership:
            return String(localized: "Purchases belong to your Apple Account and come back on any iPhone or iPad with Restore Purchases.")
        case .oracle:
            return OracleDisclosureView.text
        case .spread:
            return String(localized: "A rating helps the next curious soul find App of the Dead.")
        case .account:
            return String(localized: "Deletes your anonymous Midgar ID and the purchase records linked to it on Midgar's server. Your purchases stay with your Apple Account and come back with Restore Purchases, and your progress on this iPhone stays.")
        case .journey, .about:
            return nil
        }
    }

    private func row(_ item: SettingsItem) -> MidgarSettingsRow {
        switch item {
        case .manageSubscription:
            return .custom(id: "manageSubscription", title: String(localized: "Manage Subscription"), systemImage: "creditcard") { [weak self] in
                await self?.showManageSubscriptions()
            }
        case .restorePurchases:
            return .restorePurchases { [weak self] in try await self?.viewModel.restorePurchases() }
        case .soulCard(let name):
            return soulCardRow(name: name)
        case .dailyReminder(let time):
            return .custom(
                id: "dailyReminder",
                title: String(localized: "Daily Reminder"),
                detail: time.map(Self.timeText) ?? String(localized: "Off"),
                systemImage: "bell"
            ) { [weak self] in
                self?.navigationController?.pushViewController(DailyReminderViewController(), animated: true)
            }
        case .gameCenter:
            return .custom(id: "gameCenter", title: String(localized: "Leaderboards & Achievements"), systemImage: "trophy") { [weak self] in
                guard let self else { return }
                GameCenterManager.shared.presentDashboard(from: self)
            }
        case .oracleVoice(let voice):
            return .info(id: "oracleVoice", title: String(localized: "Oracle Voice"), detail: Self.voiceText(voice), systemImage: "sparkles")
        case .removeModel(let bytes):
            return removeModelRow(bytes: bytes)
        case .streamingHaptics:
            return .toggle(
                id: "streamingHaptics",
                title: String(localized: "Haptics While the Oracle Speaks"),
                systemImage: "waveform",
                isOn: { MLXService.HapticConfig.isStreamingHapticsEnabled },
                setOn: { UserDefaults.standard.set($0, forKey: MLXService.HapticConfig.userDefaultsKey) }
            )
        case .rate:
            return .link(id: "rate", title: String(localized: "Rate App of the Dead"), systemImage: "star", url: Self.writeReviewURL)
        case .share:
            return .custom(id: "share", title: String(localized: "Share App of the Dead"), systemImage: "square.and.arrow.up", showsDisclosure: false) { [weak self] in
                self?.shareApp()
            }
        case .support:
            return .support(subject: "App of the Dead")
        case .usageCounts:
            return .usageCountsDetail { [weak self] in
                self?.navigationController?.pushViewController(MidgarUsageCountsViewController(theme: .aotd), animated: true)
            }
        case .licenses:
            return .custom(id: "licenses", title: String(localized: "Licenses"), systemImage: "text.book.closed") { [weak self] in
                self?.navigationController?.pushViewController(Licenses.makeViewController(), animated: true)
            }
        case .privacyPolicy:
            return .privacyPolicy(url: LegalLinks.privacyPolicy)
        case .termsOfUse:
            return .termsOfUse(url: LegalLinks.termsOfService)
        case .version:
            return .version()
        case .deleteMidgarID:
            return deleteMidgarIDRow
        }
    }

    /// The saved verdict opens the Soul Card; without one the row invites the person to face the Judgment.
    private func soulCardRow(name: String?) -> MidgarSettingsRow {
        if let name {
            return .custom(id: "soulCard", title: String(localized: "Your Soul Card"), detail: name, systemImage: "scalemass.fill") { [weak self] in
                self?.presentJudgment(reviewing: true)
            }
        }
        return .custom(
            id: "soulCard",
            title: String(localized: "Face the Judgment"),
            subtitle: String(localized: "Six traditions weigh your heart in two minutes."),
            systemImage: "scalemass"
        ) { [weak self] in
            self?.presentJudgment(reviewing: false)
        }
    }

    private func removeModelRow(bytes: Int64) -> MidgarSettingsRow {
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        return MidgarSettingsRow(
            id: "removeModel",
            title: String(localized: "Remove Downloaded Model"),
            subtitle: String(localized: "Frees \(size)"),
            systemImage: "externaldrive.badge.minus",
            role: .destructive,
            kind: .action { [weak self] in self?.viewModel.removeDownloadedModel() },
            confirmation: .init(
                title: String(localized: "Remove the Oracle Model?"),
                message: String(localized: "This frees \(size) on this iPhone. If the Oracle needs the model again, it offers the download."),
                confirmTitle: String(localized: "Remove")
            ),
            successMessage: String(localized: "Model removed")
        )
    }

    private var deleteMidgarIDRow: MidgarSettingsRow {
        MidgarSettingsRow(
            id: "deleteMidgarID",
            title: String(localized: "Delete Midgar ID"),
            systemImage: "person.crop.circle.badge.xmark",
            role: .destructive,
            kind: .action { [weak self] in try await self?.viewModel.deleteMidgarID() },
            confirmation: .init(
                title: String(localized: "Delete Your Midgar ID?"),
                message: String(localized: "Midgar's server forgets your anonymous ID and the purchase records linked to it. Your purchases stay with your Apple Account. This can't be undone."),
                confirmTitle: String(localized: "Delete")
            ),
            successMessage: String(localized: "Midgar ID deleted")
        )
    }

    private func presentPlans() {
        present(PaywallViewController(reason: .generalUpgrade), animated: true)
    }

    private func presentJudgment(reviewing: Bool) {
        (view.window?.windowScene?.delegate as? SceneDelegate)?.presentJudgment(reviewing: reviewing)
    }

    /// Apple's own subscription sheet, or the App Store's subscriptions page when the sheet cannot be shown.
    private func showManageSubscriptions() async {
        if let scene = view.window?.windowScene {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
                viewModel.reload()
                return
            } catch {
                MidgarLog.error("Manage subscriptions sheet failed: \(error.localizedDescription)", category: .purchases)
            }
        }
        await UIApplication.shared.open(Self.manageSubscriptionsURL)
    }

    private func shareApp() {
        let message = String(localized: "Where will your soul go? Find out in App of the Dead.")
        let controller = UIActivityViewController(activityItems: [message, JudgmentViewModel.appStoreURL], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        controller.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        controller.completionWithItemsHandler = { activity, completed, _, _ in
            guard completed else { return }
            Diagnostics.logUserAction("appShared", parameters: ["activity": activity?.rawValue ?? "unknown"])
        }
        present(controller, animated: true)
    }

    private static func timeText(_ time: Date) -> String {
        time.formatted(date: .omitted, time: .shortened)
    }

    private static func voiceText(_ voice: SettingsState.OracleVoiceState) -> String {
        switch voice {
        case .appleIntelligence: return String(localized: "Apple Intelligence")
        case .downloaded(let modelName): return modelName
        case .notDownloaded: return String(localized: "Not Downloaded")
        }
    }
}
