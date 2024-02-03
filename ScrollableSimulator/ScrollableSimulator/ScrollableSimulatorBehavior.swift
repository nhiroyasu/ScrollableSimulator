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
                format: "at: %ld\tpixelY: %d\tpixelX: %d\tfixedDeltaY: %.2f\tfixedDeltaX: %.2f\tdeltaY: %d\tdeltaX: %d\tmomentum: %d\tphase: %d\tcount: %d\tinstant: %d\tisContinuous: %d",
                scrollWheelEvent.timestamp,
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis2),
                scrollWheelEvent.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1),
                scrollWheelEvent.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventDeltaAxis1),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventDeltaAxis2),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventMomentumPhase),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventScrollPhase),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventScrollCount),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventInstantMouser),
                scrollWheelEvent.getIntegerValueField(.scrollWheelEventIsContinuous)
            )
        )
        #endif
    }
}
