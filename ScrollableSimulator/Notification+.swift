import Cocoa

extension Notification {
    func isSimulator() -> Bool {
        guard let app = self.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return false
        }
        return app.bundleIdentifier == SIMULATOR_BUNDLE_ID
    }

    func getSimulatorPID() -> pid_t? {
        guard let app = self.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return nil
        }
        return app.processIdentifier
    }
}
