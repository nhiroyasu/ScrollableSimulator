import Cocoa

class AboutViewController: NSViewController {
    @IBAction func didClickGitHubLabel(_ sender: Any) {
        NSWorkspace.shared.open(Constants.gitHub)
    }
}
