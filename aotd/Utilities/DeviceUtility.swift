import Foundation

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
}