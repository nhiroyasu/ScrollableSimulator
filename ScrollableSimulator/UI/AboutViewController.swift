import Cocoa

class AboutViewController: NSViewController {
    @IBOutlet weak var versionLabel: NSTextField! {
        didSet {
            let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
            let buildNumber = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? ""
            versionLabel.stringValue = "Version \(version) (\(buildNumber))"
        }
    }

    @IBAction func didClickGitHubLabel(_ sender: Any) {
        NSWorkspace.shared.open(Constants.gitHub)
    }
}
