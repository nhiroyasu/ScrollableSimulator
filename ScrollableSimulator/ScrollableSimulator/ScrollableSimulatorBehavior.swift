import Foundation
import CoreGraphics

class ScrollableSimulatorBehavior {
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private let trackpadScrollBehavior: TrackpadScrollBehavior = .init()
    private let mouseScrollBehavior: MouseScrollBehavior = .init()

    func tapEventHandler(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        switch type {
        case .scrollWheel:
            return eventBehaviorOnScrollWheel(proxy: proxy, type: type, event: event, refcon: refcon)
        case .rightMouseDown:
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
        case .rightMouseUp:
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

        if isValidScrollPhase(for: event) {
            // use trackpad or magic mouse etc.
            return trackpadScrollBehavior.imitateDragging(proxy: proxy, type: type, event: event, refcon: refcon)
        } else {
            // use mouse.
            return mouseScrollBehavior.imitateDragging(proxy: proxy, type: type, event: event, refcon: refcon)
        }
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
