import Foundation
import TweetNacl
import HsCryptoKit

public enum Ed25519HDKey {
    public typealias Hex = String
    public typealias Path = String

    private static let ed25519Curve = "ed25519 seed"
    public static let hardenedOffset = 0x8000_0000

    public static func getMasterKeyFromSeed(_ seed: Hex) -> Result<Keys, Ed25519HDKeyError> {
        let hmacKey = ed25519Curve.bytes
      
        let entropy = Crypto.hmacSha512(Data(hex: seed), key: Data(hmacKey))

//        guard let entropy = hmacSha512(message: Data(hex: seed), key: Data(hmacKey)) else {
//        guard let entropy = Crypto.hmacSha512(Data(hex: seed), key: Data(hmacKey)) else {
//            return .failure(.hmacCanNotAuthenticate)
//        }
        let IL = Data(entropy[0 ..< 32])
        let IR = Data(entropy[32...])
        return .success(Keys(key: IL, chainCode: IR))
    }

    private static func CKDPriv(keys: Keys, index: UInt32) -> Result<Keys, Ed25519HDKeyError> {
        var bytes = [UInt8]()
        bytes.append(UInt8(0))
        bytes += keys.key.bytes
        bytes += index.edBytes
        let data = Data(bytes)

//        guard let entropy = hmacSha512(message: data, key: keys.chainCode) else {
//            return .failure(.hmacCanNotAuthenticate)
//        }
        let entropy = Crypto.hmacSha512(data, key: keys.chainCode)
      
        let IL = Data(entropy[0 ..< 32])
        let IR = Data(entropy[32...])
        return .success(Keys(key: IL, chainCode: IR))
    }

    public static func getPublicKey(privateKey: Data, withZeroBytes: Bool = true) throws -> Data {
        let keyPair = try NaclSign.KeyPair.keyPair(fromSeed: privateKey)
        let signPk = keyPair.secretKey[32...]
        let zero = Data([UInt8(0)])
        return withZeroBytes ? Data(zero + signPk) : Data(signPk)
    }

    public static func derivePath(_ path: Path, seed: Hex,
                                  offSet: Int = hardenedOffset) -> Result<Keys, Ed25519HDKeyError>
    {
        guard path.isValidDerivationPath else {
            return .failure(.invalidDerivationPath)
        }

        return getMasterKeyFromSeed(seed).flatMap { keys in
            let segments = path.components(separatedBy: "/")[1...]
                .map(\.replacingDerive)
                .map { Int($0)! }
            return .success((keys: keys, segments: segments))
        }.flatMap { (keys: Keys, segments: [Int]) in
            do {
                let keys = try segments.reduce(keys) { try CKDPriv(keys: $0, index: UInt32($1 + offSet)).get() }
                return .success(keys)
            } catch {
                return .failure(.canNotGetMasterKeyFromSeed)
            }
        }
    }
}

public enum Ed25519HDKeyError: Error {
    case invalidDerivationPath
    case hmacCanNotAuthenticate
    case canNotGetMasterKeyFromSeed
}

public extension Ed25519HDKey {
    struct Keys {
        public let key: Data
        public let chainCode: Data
    }
}

extension String {
    var isValidDerivationPath: Bool {
        range(of: "^m(\\/[0-9]+'?)+$", options: .regularExpression, range: nil, locale: nil) != nil
    }

    var replacingDerive: String {
        replacingOccurrences(of: "'", with: "")
    }
}

extension UInt32 {
    var edBytes: [UInt8] {
        var bigEndian = self.bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
}
