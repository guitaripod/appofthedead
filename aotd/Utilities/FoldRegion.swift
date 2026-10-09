import UIKit

enum FoldRegion {
    /// The fold while the device is partly folded, in the view's coordinates, or nil when it is
    /// flat, closed or the device has no fold. Ask on every layout pass: the system reports
    /// regions after the first pass and never announces a change.
    static func activeFrame(in view: UIView) -> CGRect? {
        #if canImport(UIKit, _version: 9127.0.85)
        if #available(iOS 27.1, *) {
            return view.reservedRegions(kind: .division).first { $0.isActive }?.frame
        }
        #endif
        return nil
    }
}
