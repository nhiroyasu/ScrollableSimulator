import Cocoa

let SIMULATOR_BUNDLE_ID = "com.apple.iphonesimulator"

class SimulatorApp {
    static func getSimulatorPID() -> pid_t? {
        NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == SIMULATOR_BUNDLE_ID })?
            .processIdentifier
    }
}
