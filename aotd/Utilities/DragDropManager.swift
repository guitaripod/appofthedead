import UIKit
import UniformTypeIdentifiers
final class DragDropManager: NSObject {
    static let shared = DragDropManager()
    private override init() {
        super.init()
    }
    func configureDragInteraction(for collectionView: UICollectionView) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let dragInteraction = UIDragInteraction(delegate: self)
        collectionView.addInteraction(dragInteraction)
        collectionView.dragInteractionEnabled = true
    }
    func configureDragInteraction(for textView: UITextView) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        textView.isUserInteractionEnabled = true
        textView.textDragInteraction?.isEnabled = true
    }
    func configureDropInteraction(for view: UIView, delegate: UIDropInteractionDelegate) {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        let dropInteraction = UIDropInteraction(delegate: delegate)
        view.addInteraction(dropInteraction)
    }
}
extension DragDropManager: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let collectionView = interaction.view as? UICollectionView else { return [] }
        let location = session.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return [] }
        if let cell = collectionView.cellForItem(at: indexPath) {
            let itemProvider = NSItemProvider()
            if cell is PathCollectionViewCell || cell is PathCollectionViewCellIPad {
                let beliefSystemData = BeliefSystemDragData(
                    id: "beliefSystem_\(indexPath.item)",
                    name: "Belief System",
                    colorHex: "#000000"
                )
                if let data = try? JSONEncoder().encode(beliefSystemData) {
                    itemProvider.registerDataRepresentation(
                        forTypeIdentifier: UTType.json.identifier,
                        visibility: .all
                    ) { completion in
                        completion(data, nil)
                        return nil
                    }
                }
            }
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = indexPath
            let previewParameters = UIDragPreviewParameters()
            previewParameters.visiblePath = UIBezierPath(
                roundedRect: cell.bounds,
                cornerRadius: PapyrusDesignSystem.CornerRadius.medium
            )
            dragItem.previewProvider = {
                let dragPreview = UIDragPreview(view: cell, parameters: previewParameters)
                return dragPreview
            }
            return [dragItem]
        }
        return []
    }
    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}
struct BeliefSystemDragData: Codable {
    let id: String
    let name: String
    let colorHex: String
}
struct NoteDragData: Codable {
    let text: String
    let source: String
    let timestamp: Date
}
