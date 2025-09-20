import UIKit
extension HomeViewController {
    override var keyCommands: [UIKeyCommand]? {
        guard AdaptiveLayoutManager.shared.isIPad else { return nil }
        return [
            UIKeyCommand(
                title: "Search Paths",
                action: #selector(searchPaths),
                input: "f",
                modifierFlags: .command,
                discoverabilityTitle: "Search Paths"
            ),
            UIKeyCommand(
                title: "Refresh",
                action: #selector(refreshData),
                input: "r",
                modifierFlags: .command,
                discoverabilityTitle: "Refresh"
            ),
            UIKeyCommand(
                title: "Grid View",
                action: #selector(switchToGrid),
                input: "1",
                modifierFlags: .command,
                discoverabilityTitle: "Grid View"
            ),
            UIKeyCommand(
                title: "List View",
                action: #selector(switchToList),
                input: "2",
                modifierFlags: .command,
                discoverabilityTitle: "List View"
            ),
            UIKeyCommand(
                title: "Next Path",
                action: #selector(selectNextPath),
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [],
                discoverabilityTitle: "Next Path"
            ),
            UIKeyCommand(
                title: "Previous Path",
                action: #selector(selectPreviousPath),
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: [],
                discoverabilityTitle: "Previous Path"
            ),
            UIKeyCommand(
                title: "Open Path",
                action: #selector(openSelectedPath),
                input: "\r",
                modifierFlags: [],
                discoverabilityTitle: "Open Path"
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