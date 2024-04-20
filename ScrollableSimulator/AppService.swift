import Cocoa
import Combine

class AppService {
    private let scrollableSimulator: ScrollableSimulatorLauncher
    private let scrollableSimulatorStatusSubject: CurrentValueSubject<ScrollableSimulatorStatus, Never>
    private let restartScrollableSimulatorSubject: PassthroughSubject<Void, Never>
    private var didTerminateAppObserver: NSObjectProtocol?
    private var didLaunchAppAppObserver: NSObjectProtocol?
    private var didActivateAppObserver: NSObjectProtocol?
    private var requestScrollableSimulatorStatusCancellation: AnyCancellable?
    private var restartScrollableSimulatorCancellation: AnyCancellable?

    init(
        scrollableSimulator: ScrollableSimulatorLauncher,
        scrollableSimulatorStatusSubject: CurrentValueSubject<ScrollableSimulatorStatus, Never>,
        restartScrollableSimulatorSubject: PassthroughSubject<Void, Never>
    ) {
        self.scrollableSimulator = scrollableSimulator
        self.scrollableSimulatorStatusSubject = scrollableSimulatorStatusSubject
        self.restartScrollableSimulatorSubject = restartScrollableSimulatorSubject
        initialize()
    }

    private func initialize() {
        if AXIsProcessTrusted() {
            observeDidLaunchApplication()
            observeDidTerminateApplication()
            observeDidActivateApplication()
            observeRestartingScrollableSimulatorStatus()
            if let pid = SimulatorApp.getSimulatorPID() {
                launchScrollableSimulator(pid: pid)
            } else {
                scrollableSimulatorStatusSubject.send(.simulatorIsNotRunning)
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
        scrollableSimulator.deactivate()
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

    private func observeDidLaunchApplication() {
        didLaunchAppAppObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self else { return }
            if notification.isSimulator(), let pid = notification.getSimulatorPID() {
                launchScrollableSimulator(pid: pid)
            }
        })
    }

    private func observeDidTerminateApplication() {
        didTerminateAppObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self else { return }
            if notification.isSimulator() {
                scrollableSimulator.deactivate()
                scrollableSimulatorStatusSubject.send(.simulatorIsNotRunning)
            }
        })
    }

    private func observeDidActivateApplication() {
        didActivateAppObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let self else { return }
            if notification.isSimulator() {
                scrollableSimulator.recoverIfNeeded()
            }
        })
    }

    private func observeRestartingScrollableSimulatorStatus() {
        restartScrollableSimulatorCancellation = restartScrollableSimulatorSubject.sink { [weak self] in
            guard let self else { return }
            if let pid = SimulatorApp.getSimulatorPID() {
                self.launchScrollableSimulator(pid: pid)
            } else {
                scrollableSimulatorStatusSubject.send(.simulatorIsNotRunning)
            }
        }
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

