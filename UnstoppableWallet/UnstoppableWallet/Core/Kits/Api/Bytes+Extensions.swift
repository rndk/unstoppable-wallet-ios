import Foundation
//TODO REMOVE MB?
public extension Array where Element == UInt8 {
    func toUInt32() -> UInt32? {
        let data = Data(self)
        return UInt32(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    func toUInt64() -> UInt64? {
        let data = Data(self)
        return UInt64(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    func toInt() -> Int {
        var value = 0
        for byte in self {
            value = value << 8
            value = value | Int(byte)
        }
        return value
    }
}
