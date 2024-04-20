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
            if self.object(forKey: "rightClickAsHomeShortcut") == nil {
                return true
            } else {
                return self.bool(forKey: "rightClickAsHomeShortcut")
            }
        }
        set {
            self.setValue(newValue, forKey: "rightClickAsHomeShortcut")
        }
    }
}
