import UIKit
extension HomeViewController {
    override var keyCommands: [UIKeyCommand]? {
        guard AdaptiveLayoutManager.shared.isIPad else { return nil }
        return [
            UIKeyCommand(
                title: String(localized: "Search Paths"),
                action: #selector(searchPaths),
                input: "f",
                modifierFlags: .command,
                discoverabilityTitle: String(localized: "Search Paths")
            ),
            UIKeyCommand(
                title: String(localized: "Refresh"),
                action: #selector(refreshData),
                input: "r",
                modifierFlags: .command,
                discoverabilityTitle: String(localized: "Refresh")
            ),
            UIKeyCommand(
                title: String(localized: "Grid View"),
                action: #selector(switchToGrid),
                input: "1",
                modifierFlags: .command,
                discoverabilityTitle: String(localized: "Grid View")
            ),
            UIKeyCommand(
                title: String(localized: "List View"),
                action: #selector(switchToList),
                input: "2",
                modifierFlags: .command,
                discoverabilityTitle: String(localized: "List View")
            ),
            UIKeyCommand(
                title: String(localized: "Next Path"),
                action: #selector(selectNextPath),
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [],
                discoverabilityTitle: String(localized: "Next Path")
            ),
            UIKeyCommand(
                title: String(localized: "Previous Path"),
                action: #selector(selectPreviousPath),
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: [],
                discoverabilityTitle: String(localized: "Previous Path")
            ),
            UIKeyCommand(
                title: String(localized: "Open Path"),
                action: #selector(openSelectedPath),
                input: "\r",
                modifierFlags: [],
                discoverabilityTitle: String(localized: "Open Path")
            )
        ]
    }
    @objc private func searchPaths() {
        AppLogger.ui.info("Search paths keyboard shortcut triggered")
    }
    @objc private func refreshData() {
        viewModel.loadData()
    }
    @objc private func switchToGrid() {
        AppLogger.ui.info("Grid view keyboard shortcut (layout is automatic)")
    }
    @objc private func switchToList() {
        AppLogger.ui.info("List view keyboard shortcut (layout is automatic)")
    }
    @objc private func selectNextPath() {
        AppLogger.ui.info("Select next path keyboard shortcut triggered")
    }
    @objc private func selectPreviousPath() {
        AppLogger.ui.info("Select previous path keyboard shortcut triggered")
    }
    @objc private func openSelectedPath() {
        AppLogger.ui.info("Open selected path keyboard shortcut triggered")
    }
}