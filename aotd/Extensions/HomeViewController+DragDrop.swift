import UIKit
import UniformTypeIdentifiers
extension HomeViewController: UIDropInteractionDelegate {
    func setupDropInteraction() {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let dropInteraction = UIDropInteraction(delegate: self)
        collectionView.addInteraction(dropInteraction)
    }
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [UTType.json.identifier])
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let location = session.location(in: collectionView)
        if collectionView.indexPathForItem(at: location) != nil {
            return UIDropProposal(operation: .copy)
        } else {
            return UIDropProposal(operation: .forbidden)
        }
    }
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        let location = session.location(in: collectionView)
        session.loadObjects(ofClass: NSString.self) { items in
            guard let strings = items as? [String],
                  let jsonString = strings.first,
                  let data = jsonString.data(using: .utf8),
                  let dragData = try? JSONDecoder().decode(BeliefSystemDragData.self, from: data) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.handleDroppedBeliefSystem(dragData, at: location)
            }
        }
    }
    private func handleDroppedBeliefSystem(_ data: BeliefSystemDragData, at location: CGPoint) {
        AppLogger.ui.info("Dropped belief system", metadata: [
            "id": data.id,
            "name": data.name
        ])
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        PapyrusAlert.showSimpleAlert(
            title: "Added to Favorites",
            message: "\(data.name) has been added to your favorites",
            from: self
        )
    }
}