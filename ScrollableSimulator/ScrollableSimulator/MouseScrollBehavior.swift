import Foundation
import CoreGraphics

class MouseScrollBehavior {
    private let mouseScrollCompletionCaller: MouseScrollCompletionCaller = .init()
    private var additionalDraggedPosition: CGPoint = .zero

    func mutateForDragging(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event mutableEvent: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        guard let immutableEvent = mutableEvent.copy() else { return Unmanaged.passUnretained(mutableEvent) }
        let targetPID = pid_t(immutableEvent.getIntegerValueField(.eventTargetUnixProcessID))
        let xScrollQuantity = getXScrollQuantity(from: immutableEvent)
        let yScrollQuantity = getYScrollQuantity(from: immutableEvent)

        if !mouseScrollCompletionCaller.isInitialized() {
            mouseScrollCompletionCaller.initialize(scrollCompletionHandler: {
                [weak self] in
                let mouseUp = makeLeftMouseUp(baseEvent: immutableEvent)
                mouseUp?.postToPid(targetPID)
                self?.resetState()
            })
            let mouseDown = makeLeftMouseDown(baseEvent: immutableEvent)
            mouseDown?.postToPid(targetPID)
        }
        mouseScrollCompletionCaller.send(event: immutableEvent)

        mutableEvent.type = .leftMouseDragged
        additionalDraggedPosition = .init(
            x: additionalDraggedPosition.x + CGFloat(xScrollQuantity),
            y: additionalDraggedPosition.y + CGFloat(yScrollQuantity)
        )
        mutableEvent.location = .init(
            x: immutableEvent.location.x + additionalDraggedPosition.x,
            y: immutableEvent.location.y + additionalDraggedPosition.y
        )
        mutableEvent.postToPid(targetPID)

        return nil
    }

    private func resetState() {
        additionalDraggedPosition = .zero
    }
}
