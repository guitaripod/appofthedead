import UIKit

final class DailyReminderViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case toggle
        case time
    }

    private enum Item: Hashable {
        case enableToggle
        case timePicker
    }

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = UIColor.Papyrus.background
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 52
        table.allowsSelection = false
        return table
    }()

    private var dataSource: UITableViewDiffableDataSource<Section, Item>!

    private var isReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "DailyReminderEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "DailyReminderEnabled") }
    }

    private var reminderTime: Date {
        get {
            if let savedTime = UserDefaults.standard.object(forKey: "DailyReminderTime") as? Date {
                return savedTime
            }
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set { UserDefaults.standard.set(newValue, forKey: "DailyReminderTime") }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "Daily Reminder"
    }

    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background

        tableView.delegate = self
        tableView.register(TransparentCardCell.self, forCellReuseIdentifier: "TransparentCardCell")
        tableView.register(TransparentSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self = self else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransparentCardCell", for: indexPath) as! TransparentCardCell

            switch item {
            case .enableToggle:
                cell.configure(text: "Enable Daily Reminder")
                cell.addSwitch(isOn: self.isReminderEnabled) { [weak self] isOn in
                    self?.toggleReminder(enabled: isOn)
                }
            case .timePicker:
                cell.configure(text: "Reminder Time")
                let timePicker = UIDatePicker()
                timePicker.datePickerMode = .time
                timePicker.preferredDatePickerStyle = .compact
                timePicker.date = self.reminderTime
                timePicker.addAction(UIAction { [weak self] _ in
                    self?.updateReminderTime(timePicker.date)
                }, for: .valueChanged)
                cell.addAccessoryView(timePicker)
            }

            return cell
        }
    }

    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        snapshot.appendSections([.toggle])
        snapshot.appendItems([.enableToggle], toSection: .toggle)

        if isReminderEnabled {
            snapshot.appendSections([.time])
            snapshot.appendItems([.timePicker], toSection: .time)
        }

        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func toggleReminder(enabled: Bool) {
        if enabled {
            requestNotificationPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.isReminderEnabled = true
                    NotificationManager.shared.scheduleDailyReminder(at: self.reminderTime)
                    self.applySnapshot(animatingDifferences: true)
                } else {
                    self.isReminderEnabled = false
                    self.showPermissionDeniedAlert()
                    self.applySnapshot(animatingDifferences: true)
                }
            }
        } else {
            isReminderEnabled = false
            NotificationManager.shared.cancelDailyReminder()
            applySnapshot(animatingDifferences: true)
        }
    }

    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        NotificationManager.shared.requestAuthorization { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    private func showPermissionDeniedAlert() {
        PapyrusAlert.showSimpleAlert(
            title: "Notifications Disabled",
            message: "Please enable notifications in Settings to receive daily reminders.",
            from: self
        )
    }

    private func updateReminderTime(_ time: Date) {
        reminderTime = time
        if isReminderEnabled {
            NotificationManager.shared.scheduleDailyReminder(at: time)
        }
    }
}

extension DailyReminderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") as! TransparentSectionHeaderView

        switch sectionType {
        case .toggle:
            headerView.configure(title: "Reminder")
        case .time:
            headerView.configure(title: "Time")
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}