import Foundation

func bytesToFloat(_ bytes: [UInt8]) -> Float {
    if bytes.count >= 4 {
        return Float(bitPattern: UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3]))
    } else {
        return 0
    }
}
