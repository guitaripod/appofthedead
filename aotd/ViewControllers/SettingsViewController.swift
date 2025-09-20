import UIKit
final class SettingsViewController: UIViewController {
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = UIColor.Papyrus.background
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 52
        return table
    }()
    private enum Section: Int, CaseIterable {
        case learning
        case experience
        case about
        var title: String {
            switch self {
            case .learning: return "Learning"
            case .experience: return "Experience"
            case .about: return "About"
            }
        }
    }
    private enum LearningRow: Int, CaseIterable {
        case notifications
        case dailyReminder
        var title: String {
            switch self {
            case .notifications: return "Notifications"
            case .dailyReminder: return "Daily Reminder"
            }
        }
    }
    private enum ExperienceRow: Int, CaseIterable {
        case streamingHaptics
        var title: String {
            switch self {
            case .streamingHaptics: return "AI Streaming Haptics"
            }
        }
    }
    private enum AboutRow: Int, CaseIterable {
        case version
        case privacyPolicy
        case termsOfService
        var title: String {
            switch self {
            case .version: return "Version"
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfService: return "Terms of Service"
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.register(ExpandableLayoutCell.self, forCellReuseIdentifier: "ExpandableLayoutCell")
        tableView.register(TransparentCardCell.self, forCellReuseIdentifier: "TransparentCardCell")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "Settings"
    }
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    private func showComingSoon(feature: String) {
        PapyrusAlert.showSimpleAlert(
            title: feature,
            message: "This feature is coming soon!",
            from: self
        )
    }
}
extension SettingsViewController: UITableViewDataSource {
    private func visibleSections() -> [Section] {
        var sections: [Section] = [.learning]
        if DeviceUtility.supportsTapticEngine {
            sections.append(.experience)
        }
        sections.append(.about)
        return sections
    }
    private func sectionType(for section: Int) -> Section? {
        let sections = visibleSections()
        guard section < sections.count else { return nil }
        return sections[section]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return visibleSections().count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = sectionType(for: section) else { return 0 }
        switch sectionType {
        case .learning:
            return LearningRow.allCases.count
        case .experience:
            return ExperienceRow.allCases.count
        case .about:
            return AboutRow.allCases.count
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = sectionType(for: section) else { return nil }
        let headerView = TransparentSectionHeaderView(title: sectionType.title)
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = sectionType(for: indexPath.section) else { 
            return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
        }
        switch sectionType {
        case .learning:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransparentCardCell", for: indexPath) as! TransparentCardCell
            if let row = LearningRow(rawValue: indexPath.row) {
                cell.configure(text: row.title, accessoryType: .disclosureIndicator)
            }
            return cell
        case .experience:
            if let row = ExperienceRow(rawValue: indexPath.row) {
                switch row {
                case .streamingHaptics:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TransparentCardCell", for: indexPath) as! TransparentCardCell
                    cell.configure(text: row.title)
                    let isOn = UserDefaults.standard.object(forKey: "StreamingHapticsEnabled") as? Bool ?? true
                    cell.addSwitch(isOn: isOn) { isOn in
                        UserDefaults.standard.set(isOn, forKey: "StreamingHapticsEnabled")
                    }
                    return cell
                }
            }
        case .about:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransparentCardCell", for: indexPath) as! TransparentCardCell
            if let row = AboutRow(rawValue: indexPath.row) {
                if row == .version {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    cell.configure(text: row.title, detailText: "\(version) (\(build))")
                } else {
                    cell.configure(text: row.title, accessoryType: .disclosureIndicator)
                }
            }
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    }
}
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sectionType = sectionType(for: indexPath.section) else { return }
        switch sectionType {
        case .learning:
            if let row = LearningRow(rawValue: indexPath.row) {
                showComingSoon(feature: row.title)
            }
        case .experience:
            if let row = ExperienceRow(rawValue: indexPath.row) {
                switch row {
                case .streamingHaptics:
                    break
                }
            }
        case .about:
            if let row = AboutRow(rawValue: indexPath.row) {
                switch row {
                case .version:
                    break 
                case .privacyPolicy, .termsOfService:
                    showComingSoon(feature: row.title)
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}
private class SwitchTableViewCell: UITableViewCell {
    let switchControl = UISwitch()
    var onSwitchToggled: ((Bool) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        selectionStyle = .none
        switchControl.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        switchControl.onTintColor = UIColor.Papyrus.gold
        accessoryView = switchControl
    }
    @objc private func switchToggled() {
        onSwitchToggled?(switchControl.isOn)
    }
}
