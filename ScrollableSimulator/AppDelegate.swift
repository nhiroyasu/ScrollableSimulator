import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var appService: AppService?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let scrollableSimulatorLauncher = ScrollableSimulatorLauncher()
        appService = .init(
            scrollableSimulatorLauncher: scrollableSimulatorLauncher,
            scrollableSimulatorStatusSubject: scrollableSimulatorStatusSubject,
            restartScrollableSimulatorSubject: restartScrollableSimulatorSubject
        )
        appService?.didFinishLaunch()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appService?.didBecomeActive()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        appService?.terminate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
