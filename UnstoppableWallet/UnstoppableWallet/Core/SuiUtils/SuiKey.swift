import Foundation
import CryptoSwift
import ed25519swift
import Blake2

public class SuiKey {
    static let key = "ed25519 seed"
    
    static func getSuiAddress(_ mnemonic: String) -> String {
        let seedKey = getPrivKeyFromSeed(mnemonic)
        let publicKey = Ed25519.calcPublicKey(secretKey: [UInt8](seedKey))
        let data = Data([UInt8](Data(count: 1)) + publicKey)
//        let hash = try! Blake2.hash(.b2b, size: 32, data: data)
        let hash = try! Blake2b.hash(size: 32, data: data)
        return "0x" + hash.toHexString()
    }
    
    static func getPubKey(_ mnemonic: String) -> Data {
        let seedKey = getPrivKeyFromSeed(mnemonic)
        return Data(Ed25519.calcPublicKey(secretKey: [UInt8](seedKey)))
    }
    
    static func sign(_ seedKey: Data, _ data: Data) -> Data {
//        let hash = try! Blake2.hash(.b2b, size: 32, data: data)
        let hash = try! Blake2b.hash(size: 32, data: data)
        let signature = Ed25519.sign(message: [UInt8](hash), secretKey: [UInt8](seedKey))
        return Data(signature)
    }
    
    static func getPrivKeyFromSeed(_ mnemonic: String, _ path: Int? = nil) -> Data {
        let seed = BIP39.seedFromMmemonics(mnemonic, password: "", language: .english)
        var result = Data()
        do {
            let mac = try CryptoSwift.HMAC(key: key, variant: .sha512).authenticate(seed!.bytes)
            let macSeed = Data(mac)
            
            let macSeedLeft = macSeed.subdata(in: 0..<32)
            let macSeedRight = macSeed.subdata(in: 32..<64)
            
            var seedKey = macSeedLeft
            var seedChain = macSeedRight
            
            let paths = [44, 784, 0, 0, path ?? 0]
            try paths.forEach { path in
                let buf = Data(UInt32(0x80000000 + path).suiBytes)
                let databuf = Data(count: 1) + seedKey + buf
                
                let reduceMac = try CryptoSwift.HMAC(key: seedChain.bytes, variant: .sha512).authenticate(databuf.bytes)
                let reduceMacSeed = Data(reduceMac)
                
                seedKey = reduceMacSeed.subdata(in: 0..<32)
                seedChain = reduceMacSeed.subdata(in: 32..<64)
            }
            result = seedKey
            
        } catch {
            print("error")
        }
        return result
    }
}


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

extension UInt32 {
    var suiBytes: [UInt8] {
        var bend = bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bend) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
}
