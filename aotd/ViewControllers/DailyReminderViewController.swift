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

    private let reminder = DailyReminder.shared

    private var isReminderEnabled: Bool { reminder.isEnabled }

    private var reminderTime: Date { reminder.time }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = String(localized: "Daily Reminder")
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
                cell.configure(text: String(localized: "Enable Daily Reminder"))
                cell.addSwitch(isOn: self.isReminderEnabled) { [weak self] isOn in
                    self?.toggleReminder(enabled: isOn)
                }
            case .timePicker:
                cell.configure(text: String(localized: "Reminder Time"))
                let timePicker = UIDatePicker()
                timePicker.datePickerMode = .time
                timePicker.preferredDatePickerStyle = .compact
                timePicker.date = self.reminderTime
                timePicker.addAction(UIAction { [weak self] action in
                    guard let picker = action.sender as? UIDatePicker else { return }
                    self?.updateReminderTime(picker.date)
                }, for: .valueChanged)
                cell.addAccessoryView(timePicker)
            }

            return cell
        }
    }

    private func applySnapshot(animatingDifferences: Bool = false, reloadingToggle: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        snapshot.appendSections([.toggle])
        snapshot.appendItems([.enableToggle], toSection: .toggle)

        if isReminderEnabled {
            snapshot.appendSections([.time])
            snapshot.appendItems([.timePicker], toSection: .time)
        }

        if reloadingToggle {
            snapshot.reloadItems([.enableToggle])
        }

        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func toggleReminder(enabled: Bool) {
        guard enabled else {
            reminder.disable()
            applySnapshot(animatingDifferences: true)
            return
        }
        reminder.enable { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                self.showPermissionDeniedAlert()
            }
            self.applySnapshot(animatingDifferences: true, reloadingToggle: !granted)
        }
    }

    private func showPermissionDeniedAlert() {
        PapyrusAlert(
            title: String(localized: "Notifications Disabled"),
            message: String(localized: "Enable notifications for App of the Dead in Settings to receive daily reminders."),
            style: .alert
        )
        .addAction(PapyrusAlert.Action(title: String(localized: "Open Settings"), style: .default) {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        .addAction(PapyrusAlert.Action(title: String(localized: "Not Now"), style: .cancel))
        .present(from: self)
    }

    private func updateReminderTime(_ time: Date) {
        reminder.updateTime(time)
    }
}

extension DailyReminderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") as! TransparentSectionHeaderView

        switch sectionType {
        case .toggle:
            headerView.configure(title: String(localized: "Reminder"))
        case .time:
            headerView.configure(title: String(localized: "Time"))
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}