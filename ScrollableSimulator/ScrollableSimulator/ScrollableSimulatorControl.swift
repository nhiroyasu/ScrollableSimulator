import Foundation
import CoreGraphics

class ScrollableSimulatorControl {
    private let pid: pid_t
    private let runLoop: CFRunLoop
    private let runLoopMode: CFRunLoopMode
    private var runLoopSource: CFRunLoopSource?
    private var port: CFMachPort?

    init(pid: pid_t, runLoop: CFRunLoop, runLoopMode: CFRunLoopMode) {
        self.pid = pid
        self.runLoop = runLoop
        self.runLoopMode = runLoopMode
    }

    func _set(runLoopSource: CFRunLoopSource, port: CFMachPort) {
        self.runLoopSource = runLoopSource
        self.port = port
    }

    func reactivate() {
        if let port, CGEvent.tapIsEnabled(tap: port) == false {
            CGEvent.tapEnable(tap: port, enable: true)
            Logger.info("Recovers TapEvents for \(pid)")
        }
    }

    func deactivate() {
        if let port {
            CGEvent.tapEnable(tap: port, enable: false)
        }
        if let runLoopSource, CFRunLoopContainsSource(runLoop, runLoopSource, runLoopMode) {
            CFRunLoopRemoveSource(runLoop, runLoopSource, runLoopMode)
        }
        Logger.info("TapEvents for \(pid) is inactive")
    }
}
