import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var appService: AppService!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let scrollableSimulator = ScrollableSimulatorLauncher()
        appService = .init(
            scrollableSimulator: scrollableSimulator,
            scrollableSimulatorStatusSubject: scrollableSimulatorStatusSubject,
            restartScrollableSimulatorSubject: restartScrollableSimulatorSubject
        )
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appService.didBecomeActive()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        appService.terminate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
