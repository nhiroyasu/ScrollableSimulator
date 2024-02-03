import Cocoa
import LaunchAtLogin

class SettingViewController: NSViewController {
    @objc dynamic var launchAtLogin = LaunchAtLogin.kvo
    @IBOutlet weak var mouseSensitivitySlider: NSSlider! {
        didSet {
            mouseSensitivitySlider.doubleValue = UserDefaults.standard.mouseSensitivity
        }
    }

    @IBAction func didChangeMouseSensitivity(_ sender: Any) {
        UserDefaults.standard.mouseSensitivity = mouseSensitivitySlider.doubleValue
    }
}
