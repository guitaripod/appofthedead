import UIKit

final class SettingsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = UIColor.Papyrus.background
        return table
    }()
    
    private enum Section: Int, CaseIterable {
        case account
        case learning
        case about
        
        var title: String {
            switch self {
            case .account: return "Account"
            case .learning: return "Learning"
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
                
                // TODO: Navigate to sign in screen
                PapyrusAlert.showSimpleAlert(
                    title: "Signed Out",
                    message: "You have been signed out successfully.",
                    from: self
                )
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
        case .about:
            return AboutRow.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        return sectionType.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return cell }
        
        switch sectionType {
        case .account:
            if let row = AccountRow(rawValue: indexPath.row) {
                cell.textLabel?.text = row.title
                cell.textLabel?.textColor = UIColor.Papyrus.tombRed
            }
            
        case .learning:
            if let row = LearningRow(rawValue: indexPath.row) {
                cell.textLabel?.text = row.title
                cell.accessoryType = .disclosureIndicator
            }
            
        case .about:
            if let row = AboutRow(rawValue: indexPath.row) {
                cell.textLabel?.text = row.title
                
                if row == .version {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    cell.detailTextLabel?.text = "\(version) (\(build))"
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .disclosureIndicator
                }
            }
        }
        
        return cell
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
}