import Foundation
import CoreGraphics

fileprivate let behavior = ScrollableSimulatorBehavior()

class ScrollableSimulatorLauncher {
    private let runLoop: CFRunLoop = CFRunLoopGetMain()
    private let runLoopMode: CFRunLoopMode = .defaultMode

    func activate(simulatorPID: pid_t) throws -> ScrollableSimulatorControl {
        let control = ScrollableSimulatorControl(pid: simulatorPID, runLoop: runLoop, runLoopMode: runLoopMode)
        let controlPointer = Unmanaged.passUnretained(control).toOpaque()
        guard let port = CGEvent.tapCreateForPid(
            pid: simulatorPID,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: .max,
            callback: { proxy, type, event, refcon in
                return behavior.tapEventHandler(proxy: proxy, type: type, event: event, refcon: refcon) {
                    if let refcon = refcon {
                        let control = Unmanaged<ScrollableSimulatorControl>.fromOpaque(refcon).takeUnretainedValue()
                        control.reactivate()
                    }
                }
            },
            userInfo: controlPointer
        ) else {
            throw ScrollableSimulatorLauncherError.tapIsNotCreated
        }
        guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
            throw ScrollableSimulatorLauncherError.tapIsNotCreated
        }
        CFRunLoopAddSource(runLoop, runLoopSource, runLoopMode)
        CGEvent.tapEnable(tap: port, enable: true)
        control._set(runLoopSource: runLoopSource, port: port)
        Logger.info("ScrollableSimulator is active!")
        return control
    }
}
