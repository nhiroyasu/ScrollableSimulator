import Foundation
import CoreGraphics

class MouseScrollBehavior {
    private let mouseScrollCompletionCaller: MouseScrollCompletionCaller = .init()
    private var additionalDraggedPosition: CGPoint = .zero
    private var beganDraggingSequence = false
    private var completionSequenceTimer: Timer?

    func imitateDragging(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event mutableEvent: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        guard let immutableEvent = mutableEvent.copy() else { return Unmanaged.passUnretained(mutableEvent) }
        let xScrollQuantity = getXScrollQuantity(from: immutableEvent)
        let yScrollQuantity = getYScrollQuantity(from: immutableEvent)

        if xScrollQuantity == 0 && yScrollQuantity == 0 && !beganDraggingSequence {
            return nil
        }

        if completionSequenceTimer != nil {
            return nil
        }

        if !beganDraggingSequence {
            Logger.info("mouse down")
            beganDraggingSequence = true
            mouseScrollCompletionCaller.initialize(scrollCompletionHandler: { [weak self] lastEvent in
                self?.onCompletionScroll(proxy: proxy, lastEvent: lastEvent)
            })
            mouseScrollCompletionCaller.push(scrollEvent: immutableEvent)
            let mouseDownEvent = convertMouseDownEvent(mutableEvent: mutableEvent)
            return Unmanaged.passUnretained(mouseDownEvent)
        } else {
            mouseScrollCompletionCaller.push(scrollEvent: immutableEvent)
            let dragEvent = convertDragEvent(
                mutateEvent: mutableEvent,
                immutableEvent: immutableEvent,
                xScrollQuantity: CGFloat(xScrollQuantity),
                yScrollQuantity: CGFloat(yScrollQuantity),
                magnification: UserDefaults.standard.mouseSensitivity / 10.0
            )
            return Unmanaged.passUnretained(dragEvent)
        }
    }

    private func convertMouseDownEvent(mutableEvent: CGEvent) -> CGEvent {
        mutableEvent.type = .leftMouseDown
        return mutableEvent
    }

    private func convertDragEvent(
        mutateEvent: CGEvent,
        immutableEvent: CGEvent,
        xScrollQuantity: CGFloat,
        yScrollQuantity: CGFloat,
        magnification: CGFloat
    ) -> CGEvent {
        mutateEvent.type = .leftMouseDragged
        additionalDraggedPosition = .init(
            x: additionalDraggedPosition.x + xScrollQuantity * magnification,
            y: additionalDraggedPosition.y + yScrollQuantity * magnification
        )
        mutateEvent.location = .init(
            x: immutableEvent.location.x + additionalDraggedPosition.x,
            y: immutableEvent.location.y + additionalDraggedPosition.y
        )
        return mutateEvent
    }

    private func onCompletionScroll(proxy: CGEventTapProxy, lastEvent: CGEvent?) {
        var timerCount = 0
        let invalidatedTimerCount = 10
        let interval = 0.01
        let absoluteBufferValue: CGFloat = {
            if additionalDraggedPosition.y < 10.0 && additionalDraggedPosition.x < 10.0 {
                return 5
            }
            return 1
        }()
        let bufferPositionX: CGFloat = { [self] in
            if self.additionalDraggedPosition.x == 0 { return 0 }
            if self.additionalDraggedPosition.x < 0 { return absoluteBufferValue * -1.0 }
            return absoluteBufferValue
        }()
        let bufferPositionY: CGFloat = { [self] in
            if self.additionalDraggedPosition.y == 0 { return 0 }
            if self.additionalDraggedPosition.y < 0 { return absoluteBufferValue * -1.0 }
            return absoluteBufferValue
        }()
        completionSequenceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            guard let mouseDraggedEvent = lastEvent?.copy() else {
                Logger.info("no lastEvent")
                timer.invalidate()
                self.resetDraggingSequence()
                return
            }
            timerCount += 1
            let shouldDragForBuffer = timerCount != invalidatedTimerCount
            if shouldDragForBuffer {
                // leftMouseDragged
                mouseDraggedEvent.type = .leftMouseDragged
                mouseDraggedEvent.timestamp += UInt64(interval * 1_000_000_000.0)
                additionalDraggedPosition = .init(
                    x: additionalDraggedPosition.x + bufferPositionX,
                    y: additionalDraggedPosition.y + bufferPositionY
                )
                mouseDraggedEvent.location = .init(
                    x: mouseDraggedEvent.location.x + additionalDraggedPosition.x,
                    y: mouseDraggedEvent.location.y + additionalDraggedPosition.y
                )
                mouseDraggedEvent.tapPostEvent(proxy)
            } else {
                // leftMouseUp
                mouseDraggedEvent.type = .leftMouseUp
                mouseDraggedEvent.timestamp += UInt64(interval * 1_000_000_000.0)
                additionalDraggedPosition = .init(
                    x: additionalDraggedPosition.x + bufferPositionX,
                    y: additionalDraggedPosition.y + bufferPositionY
                )
                mouseDraggedEvent.location = .init(
                    x: mouseDraggedEvent.location.x + additionalDraggedPosition.x,
                    y: mouseDraggedEvent.location.y + additionalDraggedPosition.y
                )
                mouseDraggedEvent.tapPostEvent(proxy)

                // dragging sequence is end
                timer.invalidate()
                resetDraggingSequence()
                Logger.info("mouse up")
            }
        }
    }

    private func resetDraggingSequence() {
        additionalDraggedPosition = .zero
        beganDraggingSequence = false
        completionSequenceTimer = nil
    }
}
