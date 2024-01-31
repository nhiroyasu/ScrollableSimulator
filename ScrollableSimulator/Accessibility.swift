import Cocoa

func showAccessibilityPermissionsAlert() {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "Requesting access to accessibility features"
    alert.informativeText = """
    You can manage this permission in System Preferences > Security & Privacy > Privacy.

    After setting, please restart the application.
    """
    alert.addButton(withTitle: "Open Settings and Quit")
    let response = alert.runModal()

    switch response {
    case .alertFirstButtonReturn:
        openAccessibilityForSystemPreference()
        NSWorkspace.shared.selectFile(
            APP_URL.path,
            inFileViewerRootedAtPath: APP_URL.deletingLastPathComponent().path
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApplication.shared.terminate(nil)
        }
    default:
        break
    }
}

func openAccessibilityForSystemPreference() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
    }
}
