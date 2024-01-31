import Foundation
import CoreGraphics

func getYScrollQuantity(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
}

func getXScrollQuantity(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
}

func getYScrollQuantityForLineBase(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1)
}

func getXScrollQuantityForLineBase(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2)
}

func isBeganScroll(from event: CGEvent) -> Bool {
    event.getIntegerValueField(.scrollWheelEventScrollPhase) == CGScrollPhase.began.rawValue
}

func isEndedScroll(from event: CGEvent) -> Bool {
    event.getIntegerValueField(.scrollWheelEventScrollPhase) == CGScrollPhase.ended.rawValue
}

func isContinuousScroll(from event: CGEvent) -> Bool {
    event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
}

func isBeginContinuousScroll(from event: CGEvent) -> Bool {
    event.getIntegerValueField(.scrollWheelEventMomentumPhase) == CGMomentumScrollPhase.begin.rawValue
}

func isEndContinuousScroll(from event: CGEvent) -> Bool {
    event.getIntegerValueField(.scrollWheelEventMomentumPhase) == CGMomentumScrollPhase.end.rawValue
}

func makeLeftMouseDown(baseEvent: CGEvent) -> CGEvent? {
    guard let copyEvent = baseEvent.copy() else { return nil }
    copyEvent.type = .leftMouseDown
    return copyEvent
}

func makeLeftMouseUp(baseEvent: CGEvent) -> CGEvent? {
    guard let copyEvent = baseEvent.copy() else { return nil }
    copyEvent.type = .leftMouseUp
    return copyEvent
}

func makeLeftMouseDragged(baseEvent: CGEvent, location: CGPoint? = nil) -> CGEvent? {
    guard let copyEvent = baseEvent.copy() else { return nil }
    copyEvent.type = .leftMouseDragged
    if let location {
        copyEvent.location = location
    }
    return copyEvent
}

/// Getting scroll quantity from CGEvent.data
@available(*, deprecated, message: "Use getXScrollQuantity()")
func getXScrollQuantity(from cfData: CFData) -> Int32 {
    // Find the value that marks the point where the scroll quantity is stored.
    var findData: [UInt8] = [0x00, 0x01, 0x40, 0x60]  // Data array in front of the scroll value (maybe)
    let findCfData = CFDataCreate(kCFAllocatorDefault, &findData, findData.count)
    let originRange = CFDataFind(
        cfData,
        findCfData,
        .init(location: 0, length: CFDataGetLength(cfData)),
        []
    )

    // The value of 4 bytes behind the marker point is the scroll quantity, so extract the data at that point.
    var scrollValues = [UInt8](repeating: 0, count: 4)
    CFDataGetBytes(
        cfData,
        CFRange(
            location: originRange.location + originRange.length,
            length: 4
        ),
        &scrollValues
    )

    // convert uint8[] -> uint32 -> int32
    let unsignedScrollQuantity = UInt32(scrollValues[0]) << 24 +
                                    UInt32(scrollValues[1]) << 16 +
                                    UInt32(scrollValues[2]) << 8 +
                                    UInt32(scrollValues[3])
    let data = withUnsafeBytes(of: unsignedScrollQuantity) { Data($0) }
    let signedScrollQuantity = data.withUnsafeBytes { $0.load(as: Int32.self) }
    return signedScrollQuantity
}
