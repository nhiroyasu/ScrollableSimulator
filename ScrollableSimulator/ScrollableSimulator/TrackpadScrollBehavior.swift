import Foundation
import CoreGraphics

class TrackpadScrollBehavior {
    private var scrollEventQueue: [CGEvent] = []
    private var additionalDraggedPosition: CGPoint = .zero

    func mutateForDragging(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event mutableEvent: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        guard let immutableEvent = mutableEvent.copy() else { return Unmanaged.passUnretained(mutableEvent) }

        let xScrollQuantity = getXScrollQuantity(from: immutableEvent)
        let yScrollQuantity = getYScrollQuantity(from: immutableEvent)

        // pattern1: began scroll
        if isBeganScroll(from: immutableEvent) {
            mutableEvent.type = .leftMouseDown
            copyAndStoreEvent(immutableEvent)
            return Unmanaged.passUnretained(mutableEvent)
        }
        // pattern2: end scroll(non inertial scroll)
        if isEndedScroll(from: immutableEvent) && isNonInertialScroll(lastEvent: scrollEventQueue.last) {
            mutableEvent.type = .leftMouseUp
            resetState()
            return Unmanaged.passUnretained(mutableEvent)
        }
        // pattern3: end scroll(inertial scroll)
        if isEndContinuousScroll(from: immutableEvent) {
            mutableEvent.type = .leftMouseUp
            resetState()
            return Unmanaged.passUnretained(mutableEvent)
        }
        // pattern4: while scrolling
        mutableEvent.type = .leftMouseDragged
        additionalDraggedPosition = .init(
            x: additionalDraggedPosition.x + CGFloat(xScrollQuantity),
            y: additionalDraggedPosition.y + CGFloat(yScrollQuantity)
        )
        mutableEvent.location = .init(
            x: immutableEvent.location.x + additionalDraggedPosition.x,
            y: immutableEvent.location.y + additionalDraggedPosition.y
        )
        copyAndStoreEvent(immutableEvent)
        return Unmanaged.passUnretained(mutableEvent)
    }

    private func isNonInertialScroll(lastEvent: CGEvent?) -> Bool {
        guard let lastEvent else {
            assertionFailure("lastEvent is null")
            return true
        }
        let lastDeltaY = lastEvent.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let lastDeltaX = lastEvent.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        return lastDeltaY == 0.0 && lastDeltaX == 0.0
    }

    private func copyAndStoreEvent(_ event: CGEvent) {
        guard let copyEvent = event.copy() else { return }
        scrollEventQueue.append(copyEvent)
    }

    private func resetState() {
        scrollEventQueue = []
        additionalDraggedPosition = .zero
    }
}
