import Cocoa
import LaunchAtLogin
import Combine

class SettingViewController: NSViewController {
    @objc dynamic var launchAtLogin = LaunchAtLogin.kvo
    @IBOutlet weak var systemStatusImageView: NSImageView!
    @IBOutlet weak var systemStatusLabel: NSTextField!
    @IBOutlet weak var mouseSensitivitySlider: NSSlider! {
        didSet {
            mouseSensitivitySlider.doubleValue = UserDefaults.standard.mouseSensitivity
        }
    }
    @IBOutlet weak var systemStatusButton: NSButton!
    private var scrollableSimulatorStatusCancellation: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollableSimulatorStatusCancellation = scrollableSimulatorStatusSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateUI(status:))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        updateUI(status: scrollableSimulatorStatusSubject.value)
    }

    private func updateUI(status: ScrollableSimulatorStatus) {
        switch status {
        case .active:
            systemStatusImageView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            systemStatusImageView.contentTintColor = .systemGreen
            systemStatusLabel.stringValue = "System is running"
            systemStatusButton.isHidden = true
        case .simulatorIsNotRunning:
            systemStatusImageView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            systemStatusImageView.contentTintColor = .systemGray
            systemStatusLabel.stringValue = "Simulator.app is not running"
            systemStatusButton.isHidden = false
            systemStatusButton.title = "Open Simulator.app"
            systemStatusButton.target = self
            systemStatusButton.action = #selector(openSimulatorApp)
        case .error:
            systemStatusImageView.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
            systemStatusImageView.contentTintColor = .systemRed
            systemStatusLabel.stringValue = "System is not running"
            systemStatusButton.isHidden = false
            systemStatusButton.title = "Restart system"
            systemStatusButton.target = self
            systemStatusButton.action = #selector(restartSystem)
        }
    }

    @IBAction func didChangeMouseSensitivity(_ sender: Any) {
        UserDefaults.standard.mouseSensitivity = mouseSensitivitySlider.doubleValue
    }

    @objc private func openSimulatorApp() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: SIMULATOR_BUNDLE_ID) else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Simulator.app not found"
            alert.runModal()
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }

    @objc private func restartSystem() {
        restartScrollableSimulatorStatus.send(())
    }
}
