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

    var rightClickAsHomeShortcut: Bool {
        get {
            if self.object(forKey: "rightClickAsHomeShortcut_2") == nil {
                return false
            } else {
                return self.bool(forKey: "rightClickAsHomeShortcut_2")
            }
        }
        set {
            self.setValue(newValue, forKey: "rightClickAsHomeShortcut_2")
        }
    }
}
