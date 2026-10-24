import UIKit
import MidgarCore
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
        MidgarLog.info("Search paths keyboard shortcut triggered", category: .ui)
    }
    @objc private func refreshData() {
        viewModel.loadData()
    }
    @objc private func switchToGrid() {
        MidgarLog.info("Grid view keyboard shortcut (layout is automatic)", category: .ui)
    }
    @objc private func switchToList() {
        MidgarLog.info("List view keyboard shortcut (layout is automatic)", category: .ui)
    }
    @objc private func selectNextPath() {
        MidgarLog.info("Select next path keyboard shortcut triggered", category: .ui)
    }
    @objc private func selectPreviousPath() {
        MidgarLog.info("Select previous path keyboard shortcut triggered", category: .ui)
    }
    @objc private func openSelectedPath() {
        MidgarLog.info("Open selected path keyboard shortcut triggered", category: .ui)
    }
}