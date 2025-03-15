import Foundation
import CoreGraphics
import AppKit

class ScrollableSimulatorBehavior {
    private let trackpadScrollBehavior: TrackpadScrollBehavior = .init()
    private let mouseScrollBehavior: MouseScrollBehavior = .init()

    func tapEventHandler(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?,
        onDisabledHandler: () -> Void
    ) -> Unmanaged<CGEvent>? {
        switch type {
        case .scrollWheel:
            return eventBehaviorOnScrollWheel(proxy: proxy, type: type, event: event, refcon: refcon)
        case .rightMouseDown:
            return eventBehaviorOnRightClickDown(event: event)
        case .rightMouseUp:
            return eventBehaviorOnRightClickUp(event: event)
        case .tapDisabledByTimeout:
            Logger.info("tapDisabledByTimeout")
            onDisabledHandler()
            return Unmanaged.passUnretained(event)
        case .tapDisabledByUserInput:
            Logger.info("tapDisabledByUserInput")
            onDisabledHandler()
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func eventBehaviorOnScrollWheel(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        log(scrollWheelEvent: event)

        if macOS15Later() && !isActiveSimulatorApp() {
            return Unmanaged.passUnretained(event)
        }

        if isValidScrollPhase(for: event) {
            // use trackpad or magic mouse etc.
            return trackpadScrollBehavior.imitateDragging(proxy: proxy, type: type, event: event, refcon: refcon)
        } else {
            // use mouse.
            return mouseScrollBehavior.imitateDragging(proxy: proxy, type: type, event: event, refcon: refcon)
        }
    }

    private func isActiveSimulatorApp() -> Bool {
        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == SIMULATOR_BUNDLE_ID {
                return app.isActive
            }
        }
        return false
    }

    private func macOS15Later() -> Bool {
        if #available(macOS 10.15, *) {
            return true
        } else {
            return false
        }
    }

    private func eventBehaviorOnRightClickDown(event: CGEvent) -> Unmanaged<CGEvent>? {
        guard UserDefaults.standard.rightClickAsHomeShortcut,
              let keyboardType = CGEventSource(stateID: .hidSystemState)?.keyboardType else {
            return Unmanaged.passUnretained(event)
        }
        event.type = .keyDown
        event.flags = [.maskCommand, .maskShift]
        event.setIntegerValueField(.keyboardEventKeycode, value: 0x04)  // H key
        event.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
        event.setIntegerValueField(.keyboardEventKeyboardType, value: Int64(keyboardType))
        return Unmanaged.passUnretained(event)
    }

    private func eventBehaviorOnRightClickUp(event: CGEvent) -> Unmanaged<CGEvent>? {
        guard UserDefaults.standard.rightClickAsHomeShortcut,
              let keyboardType = CGEventSource(stateID: .hidSystemState)?.keyboardType else {
            return Unmanaged.passUnretained(event)
        }
        event.type = .keyUp
        event.flags = [.maskCommand, .maskShift]
        event.setIntegerValueField(.keyboardEventKeycode, value: 0x04)  // H key
        event.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
        event.setIntegerValueField(.keyboardEventKeyboardType, value: Int64(keyboardType))
        return Unmanaged.passUnretained(event)
    }

    private func log(scrollWheelEvent: CGEvent) {
        #if DEBUG
        print(
            String(
                format: "at: %ld\tpixelY: %d\tpixelX: %d\tfixedDeltaY: %.2f\tfixedDeltaX: %.2f\tmomentum: %d\tphase: %d\tisContinuous: %d\tpixelsPerLine: %.1f",
                scrollWheelEvent.timestamp,
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis2),
                scrollWheelEvent.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1),
                scrollWheelEvent.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventMomentumPhase),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventScrollPhase),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventIsContinuous),
                CGEventSource(event: scrollWheelEvent)?.pixelsPerLine ?? 0.0
            )
        )
        #endif
    }
}
