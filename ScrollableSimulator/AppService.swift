import Cocoa
import Combine

class AppService {
    private let scrollableSimulator: ScrollableSimulatorLauncher
    private let scrollableSimulatorStatusSubject: CurrentValueSubject<ScrollableSimulatorStatus, Never>
    private var didTerminateAppObserver: NSObjectProtocol?
    private var didLaunchAppAppObserver: NSObjectProtocol?
    private var requestScrollableSimulatorStatusCancellation: AnyCancellable?
    private var restartScrollableSimulatorCancellation: AnyCancellable?

    init(
        scrollableSimulator: ScrollableSimulatorLauncher,
        scrollableSimulatorStatusSubject: CurrentValueSubject<ScrollableSimulatorStatus, Never>
    ) {
        self.scrollableSimulator = scrollableSimulator
        self.scrollableSimulatorStatusSubject = scrollableSimulatorStatusSubject
        initialize()
    }

    private func initialize() {
        if AXIsProcessTrusted() {
            observeDidLaunchApplication()
            observeDidTerminateApplication()
            if let pid = SimulatorApp.getSimulatorPID() {
                launchScrollableSimulator(pid: pid)
            }
        } else {
            showAccessibilityPermissionsAlert()
        }
    }

    func didBecomeActive() {
        NSApplication.shared.windows.forEach {
            if $0.identifier?.rawValue == "main" {
                $0.makeKeyAndOrderFront(nil)
            }
        }
    }

    func terminate() {
        terminateScrollableSimulator()
    }

    private func launchScrollableSimulator(pid: pid_t) {
        do {
            try scrollableSimulator.activate(simulatorPID: pid)
            scrollableSimulatorStatusSubject.send(.active)
        } catch {
            scrollableSimulatorStatusSubject.send(.error)
            showAlertForFailedLaunching(retryHandler: {
                launchScrollableSimulator(pid: pid)
            })
        }
    }

    private func terminateScrollableSimulator() {
        scrollableSimulator.deactivate()
        scrollableSimulatorStatusSubject.send(.simulatorIsNotRunning)
    }

    private func observeDidLaunchApplication() {
        didLaunchAppAppObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self else { return }
            if isSimulator(for: notification), let pid = getSimulatorPID(for: notification) {
                launchScrollableSimulator(pid: pid)
            }
        })
    }

    private func observeDidTerminateApplication() {
        didTerminateAppObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self else { return }
            if isSimulator(for: notification) {
                terminateScrollableSimulator()
            }
        })
    }

    private func observeRestartingScrollableSimulatorStatus() {
        restartScrollableSimulatorCancellation = restartScrollableSimulatorStatus.sink { [weak self] in
            guard let self else { return }
            if let pid = SimulatorApp.getSimulatorPID() {
                self.launchScrollableSimulator(pid: pid)
            }
        }
    }

    private func isSimulator(for notification: Notification) -> Bool {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return false
        }
        return app.bundleIdentifier == SIMULATOR_BUNDLE_ID
    }

    private func getSimulatorPID(for notification: Notification) -> pid_t? {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return nil
        }
        return app.processIdentifier
    }

    private func showAlertForFailedLaunching(retryHandler: () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "System failed to boot"
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Quit")
        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            retryHandler()
        case .alertSecondButtonReturn:
            NSApplication.shared.terminate(nil)
        default:
            break
        }
    }
}

