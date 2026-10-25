import UIKit

extension PaywallViewController {
    /// Ask to Buy: the purchase waits for a parent's approval and unlocks by itself once it comes, so the paywall says
    /// so and closes instead of leaving the person on a screen that cannot finish.
    func showPendingApprovalAndDismiss() {
        let alert = UIAlertController(
            title: String(localized: "Waiting for Approval"),
            message: String(localized: "Your purchase is waiting for approval. It unlocks by itself once it is approved."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
