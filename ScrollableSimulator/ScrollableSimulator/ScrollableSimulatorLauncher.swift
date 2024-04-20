import Foundation
import CoreGraphics

fileprivate let behavior = ScrollableSimulatorBehavior()

class ScrollableSimulatorLauncher {
    private let runLoop: CFRunLoop = CFRunLoopGetMain()
    private let runLoopMode: CFRunLoopMode = .defaultMode
    private var runLoopSource: CFRunLoopSource?

    func activate(simulatorPID: pid_t) throws {
        if let runLoopSource {
            if CFRunLoopContainsSource(runLoop, runLoopSource, runLoopMode) {
                CFRunLoopRemoveSource(runLoop, runLoopSource, runLoopMode)
                self.runLoopSource = nil
            }
        }

        guard let port = CGEvent.tapCreateForPid(
            pid: simulatorPID,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: .max,
            callback: { proxy, type, event, refcon in
                behavior.tapEventHandler(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: nil
        ) else {
            throw ScrollableSimulatorLauncherError.tapIsNotCreated
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(runLoop, runLoopSource, runLoopMode)
        CGEvent.tapEnable(tap: port, enable: true)
        Logger.info("ScrollableSimulator is active!")
    }

    func deactivate() {
        guard let runLoopSource else { return }
        if CFRunLoopContainsSource(runLoop, runLoopSource, runLoopMode) {
            CFRunLoopRemoveSource(runLoop, runLoopSource, runLoopMode)
        }
        self.runLoopSource = nil
        Logger.info("ScrollableSimulator is inactive")
    }
}

enum ScrollableSimulatorLauncherError: Error {
    case tapIsNotCreated
}
