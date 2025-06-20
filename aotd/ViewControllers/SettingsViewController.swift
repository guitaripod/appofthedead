import UIKit

final class SettingsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = UIColor.Papyrus.background
        table.separatorStyle = .none
        return table
    }()
    
    private enum Section: Int, CaseIterable {
        case account
        case learning
        case experience
        case about
        
        var title: String {
            switch self {
            case .account: return "Account"
            case .learning: return "Learning"
            case .experience: return "Experience"
            case .about: return "About"
            }
        }
    }
    
    private enum AccountRow: Int, CaseIterable {
        case signOut
        
        var title: String {
            switch self {
            case .signOut: return "Sign Out"
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
        case viewLayout
        case streamingHaptics
        
        var title: String {
            switch self {
            case .viewLayout: return "View Layout"
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
        
        // Register custom cells
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
    
    @objc private func handleSignOut() {
        PapyrusAlert.showConfirmationAlert(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            confirmTitle: "Sign Out",
            confirmStyle: .destructive,
            from: self,
            onConfirm: { [weak self] in
                guard let self = self else { return }
                // Clear user session
                DatabaseManager.shared.clearUserSession()
                
                // Navigate to sign in screen
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let signInVC = SignInViewController()
                    let navigationController = UINavigationController(rootViewController: signInVC)
                    navigationController.modalPresentationStyle = .fullScreen
                    
                    window.rootViewController = navigationController
                    window.makeKeyAndVisible()
                    
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                }
            }
        )
    }
    
    private func showComingSoon(feature: String) {
        PapyrusAlert.showSimpleAlert(
            title: feature,
            message: "This feature is coming soon!",
            from: self
        )
    }
    
    
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .account:
            return AccountRow.allCases.count
        case .learning:
            return LearningRow.allCases.count
        case .experience:
            return ExperienceRow.allCases.count
        case .about:
            return AboutRow.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        let headerView = TransparentSectionHeaderView(title: sectionType.title)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else { 
            return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
        }
        
        switch sectionType {
        case .account:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransparentCardCell", for: indexPath) as! TransparentCardCell
            if let row = AccountRow(rawValue: indexPath.row) {
                cell.configure(text: row.title, textColor: UIColor.Papyrus.tombRed)
            }
            return cell
            
        case .learning:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransparentCardCell", for: indexPath) as! TransparentCardCell
            if let row = LearningRow(rawValue: indexPath.row) {
                cell.configure(text: row.title, accessoryType: .disclosureIndicator)
            }
            return cell
            
        case .experience:
            if let row = ExperienceRow(rawValue: indexPath.row) {
                switch row {
                case .viewLayout:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ExpandableLayoutCell", for: indexPath) as! ExpandableLayoutCell
                    let currentPreference = UserDefaults.standard.viewLayoutPreference
                    cell.configure(currentLayout: currentPreference) { [weak self] layout in
                        UserDefaults.standard.viewLayoutPreference = layout
                        
                        NotificationCenter.default.post(
                            name: .viewLayoutPreferenceChanged,
                            object: nil,
                            userInfo: ["layout": layout]
                        )
                    }
                    return cell
                    
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

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .account:
            if let row = AccountRow(rawValue: indexPath.row) {
                switch row {
                case .signOut:
                    handleSignOut()
                }
            }
            
        case .learning:
            if let row = LearningRow(rawValue: indexPath.row) {
                showComingSoon(feature: row.title)
            }
            
        case .experience:
            if let row = ExperienceRow(rawValue: indexPath.row) {
                switch row {
                case .viewLayout:
                    if let cell = tableView.cellForRow(at: indexPath) as? ExpandableLayoutCell {
                        cell.toggleExpansion()
                    }
                case .streamingHaptics:
                    // No action needed for switch cells
                    break
                }
            }
            
        case .about:
            if let row = AboutRow(rawValue: indexPath.row) {
                switch row {
                case .version:
                    break // No action for version
                case .privacyPolicy, .termsOfService:
                    showComingSoon(feature: row.title)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionType = Section(rawValue: indexPath.section),
              sectionType == .experience,
              let row = ExperienceRow(rawValue: indexPath.row),
              row == .viewLayout else {
            return UITableView.automaticDimension
        }
        
        // Check if cell is expanded
        if let cell = tableView.cellForRow(at: indexPath) as? ExpandableLayoutCell {
            return cell.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width, height: 0), 
                                              withHorizontalFittingPriority: .required, 
                                              verticalFittingPriority: .fittingSizeLevel).height
        }
        
        return 44
    }
}

// MARK: - SwitchTableViewCell

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


