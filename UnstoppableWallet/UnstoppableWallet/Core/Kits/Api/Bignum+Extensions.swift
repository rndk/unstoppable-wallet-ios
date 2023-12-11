//
//  Bignum+Extensions.swift
//  UnstoppableWallet
//
//  Created by rmnn on 08.12.2023.
//  Copyright © 2023 Grouvi. All rights reserved.
//

import Foundation

/// Bignum compatibility alias for BInt
public typealias Bignum = BInt

public extension Bignum {
    /// Representation as Data
    var data: Data {
        let n = limbs.count
        var data = Data(count: n * 8)
        data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) in
            var p = ptr
            for i in (0 ..< n).reversed() {
                for j in (0 ..< 8).reversed() {
                    p.pointee = UInt8((limbs[i] >> UInt64(j * 8)) & 0xFF)
                    p += 1
                }
            }
        }
        return data
    }

    /// Decimal string representation
    var dec: String { description }

    /// Hexadecimal string representation
    var hex: String { data.hexString }

    ///
    /// Initialise a BInt from a hexadecimal string
    ///
    /// - Parameter hex: the hexadecimal string to convert to a big integer
    init(hex: String) {
        self.init(number: hex.lowercased(), withBase: 16)
    }

    /// Initialise from an unsigned, 64 bit integer
    ///
    /// - Parameter n: the 64 bit unsigned integer to convert to a BInt
    init(_ n: UInt64) {
        self.init(limbs: [n])
    }

    /// Initialise from big-endian data
    ///
    /// - Parameter data: the data to convert to a Bignum
    init(data: Data) {
        let n = data.count
        guard n > 0 else {
            self.init(0)
            return
        }
        let m = (n + 7) / 8
        var limbs = Limbs(repeating: 0, count: m)
        data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
            var p = ptr
            let r = n % 8
            let k = r == 0 ? 8 : r
            for j in (0 ..< k).reversed() {
                limbs[m - 1] += UInt64(p.pointee) << UInt64(j * 8)
                p += 1
            }
            guard m > 1 else { return }
            for i in (0 ..< (m - 1)).reversed() {
                for j in (0 ..< 8).reversed() {
                    limbs[i] += UInt64(p.pointee) << UInt64(j * 8)
                    p += 1
                }
            }
        }
        self.init(limbs: limbs)
    }
}

/// Extension for Data to interoperate with Bignum
public extension Data {
    /// Hexadecimal string representation of the underlying data
    var hexString: String {
        withUnsafeBytes { (buf: UnsafePointer<UInt8>) -> String in
            let charA = UInt8(UnicodeScalar("a").value)
            let char0 = UInt8(UnicodeScalar("0").value)

            func itoh(_ value: UInt8) -> UInt8 {
                (value > 9) ? (charA + value - 10) : (char0 + value)
            }

            let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: count * 2)

            for i in 0 ..< count {
                ptr[i * 2] = itoh((buf[i] >> 4) & 0xF)
                ptr[i * 2 + 1] = itoh(buf[i] & 0xF)
            }

            return String(bytesNoCopy: ptr, length: count * 2, encoding: .utf8, freeWhenDone: true)!
        }
    }
}
