import Foundation
import CoreGraphics

func getYScrollQuantity(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
}

func getXScrollQuantity(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
}

func getYScrollAbsoluteQuantity(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
}

func getXScrollAbsoluteQuantity(from event: CGEvent) -> Int64 {
    event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
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

func isValidScrollPhase(for event: CGEvent) -> Bool {
    event.getIntegerValueField(.scrollWheelEventMomentumPhase) != CGMomentumScrollPhase.none.rawValue || event.getIntegerValueField(.scrollWheelEventScrollPhase) != 0
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

@available(macOS 12.0, *)
func replaceLocationForCGEvent(baseEvent: CGEvent, addPoint: CGPoint) -> CGEvent? {
    let globalLocationAddress: [UInt8] = [0x00, 0x02, 0xc0, 0x38]
    let localLocationAddress: [UInt8] = [0x00, 0x02, 0xc0, 0x39]

    let mutableData = CFDataCreateMutableCopy(nil, 0, baseEvent.data)
    guard let mutableDataRef = CFDataGetMutableBytePtr(mutableData) else { return nil }

    // Update global location
    guard let globalLocationOffset: Int = CFComputeNextOffset(bytes: mutableDataRef, count: CFDataGetLength(mutableData), target: globalLocationAddress) else {
        return nil
    }
    let globalXBytes: [UInt8] = [
        mutableDataRef[globalLocationOffset + 0],
        mutableDataRef[globalLocationOffset + 1],
        mutableDataRef[globalLocationOffset + 2],
        mutableDataRef[globalLocationOffset + 3]
    ]
    let globalYBytes: [UInt8] = [
        mutableDataRef[globalLocationOffset + 4],
        mutableDataRef[globalLocationOffset + 5],
        mutableDataRef[globalLocationOffset + 6],
        mutableDataRef[globalLocationOffset + 7]
    ]
    let globalX = bytesToFloat(globalXBytes)
    let globalY = bytesToFloat(globalYBytes)
    let newGlobalX: Float32 = globalX + Float32(addPoint.x)
    let newGlobalY: Float32 = globalY + Float32(addPoint.y)
    let newGlobalXBytes = withUnsafeBytes(of: newGlobalX.bitPattern.bigEndian) { Array($0) }
    let newGlobalYBytes = withUnsafeBytes(of: newGlobalY.bitPattern.bigEndian) { Array($0) }
    mutableDataRef[globalLocationOffset + 0] = newGlobalXBytes[0]
    mutableDataRef[globalLocationOffset + 1] = newGlobalXBytes[1]
    mutableDataRef[globalLocationOffset + 2] = newGlobalXBytes[2]
    mutableDataRef[globalLocationOffset + 3] = newGlobalXBytes[3]
    mutableDataRef[globalLocationOffset + 4] = newGlobalYBytes[0]
    mutableDataRef[globalLocationOffset + 5] = newGlobalYBytes[1]
    mutableDataRef[globalLocationOffset + 6] = newGlobalYBytes[2]
    mutableDataRef[globalLocationOffset + 7] = newGlobalYBytes[3]

    // Update local location
    guard let localLocationOffset: Int = CFComputeNextOffset(bytes: mutableDataRef, count: CFDataGetLength(mutableData), target: localLocationAddress) else {
        return nil
    }
    let localXBytes: [UInt8] = [
        mutableDataRef[localLocationOffset + 0],
        mutableDataRef[localLocationOffset + 1],
        mutableDataRef[localLocationOffset + 2],
        mutableDataRef[localLocationOffset + 3]
    ]
    let localYBytes: [UInt8] = [
        mutableDataRef[localLocationOffset + 4],
        mutableDataRef[localLocationOffset + 5],
        mutableDataRef[localLocationOffset + 6],
        mutableDataRef[localLocationOffset + 7]
    ]
    let localX = bytesToFloat(localXBytes)
    let localY = bytesToFloat(localYBytes)
    let newLocalX: Float32 = localX + Float32(addPoint.x)
    let newLocalY: Float32 = localY + Float32(addPoint.y)
    let newLocalXBytes = withUnsafeBytes(of: newLocalX.bitPattern.bigEndian) { Array($0) }
    let newLocalYBytes = withUnsafeBytes(of: newLocalY.bitPattern.bigEndian) { Array($0) }
    mutableDataRef[localLocationOffset + 0] = newLocalXBytes[0]
    mutableDataRef[localLocationOffset + 1] = newLocalXBytes[1]
    mutableDataRef[localLocationOffset + 2] = newLocalXBytes[2]
    mutableDataRef[localLocationOffset + 3] = newLocalXBytes[3]
    mutableDataRef[localLocationOffset + 4] = newLocalYBytes[0]
    mutableDataRef[localLocationOffset + 5] = newLocalYBytes[1]
    mutableDataRef[localLocationOffset + 6] = newLocalYBytes[2]
    mutableDataRef[localLocationOffset + 7] = newLocalYBytes[3]

    #if DEBUG
    print("globalX: \(globalX), globalY: \(globalY), localX: \(localX), localY: \(localY)")
    print("newGlobalX: \(newGlobalX), newGlobalY: \(newGlobalY), newLocalX: \(newLocalX), newLocalY: \(newLocalY)")
    print("---")
    #endif

    return CGEvent(withDataAllocator: kCFAllocatorDefault, data: mutableData)
}

private func CFComputeNextOffset(bytes: UnsafeMutablePointer<UInt8>, count: Int, target: [UInt8]) -> Int? {
    for i in 0..<count {
        for targetIndex in 0..<target.count {
            if bytes[i + targetIndex] != target[targetIndex] {
                break
            }
            if targetIndex == target.count - 1 {
                return i + target.count
            }
        }
    }
    return nil
}
