import Foundation

extension UserDefaults {
    var mouseSensitivity: Double {
        get {
            let value = self.double(forKey: "mouseSensitivity")
            if value == 0.0 {
                return 5.0
            } else {
                return value
            }
        }
        set {
            self.setValue(newValue, forKey: "mouseSensitivity")
        }
    }
}
