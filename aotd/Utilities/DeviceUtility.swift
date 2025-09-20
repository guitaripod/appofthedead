import Foundation
import UIKit
struct DeviceUtility {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    static var isPhysicalDevice: Bool {
        !isSimulator
    }
    static var supportsTapticEngine: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return false
        }
        if #available(iOS 10.0, *) {
            return UIDevice.current.hasTapticEngine
        }
        return false
    }
}
private extension UIDevice {
    var hasTapticEngine: Bool {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        let deviceModel = modelIdentifier
        let modelsWithTapticEngine = [
            "iPhone8,1", "iPhone8,2",  
            "iPhone8,4",               
            "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4",  
            "iPhone10,1", "iPhone10,2", "iPhone10,3", "iPhone10,4", "iPhone10,5", "iPhone10,6",  
            "iPhone11,", "iPhone12,", "iPhone13,", "iPhone14,", "iPhone15,", "iPhone16,"  
        ]
        return modelsWithTapticEngine.contains { deviceModel.hasPrefix($0) }
    }
    private var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}