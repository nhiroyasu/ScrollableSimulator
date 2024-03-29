import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private let appService: AppService = .init()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        appService.initialize()
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
