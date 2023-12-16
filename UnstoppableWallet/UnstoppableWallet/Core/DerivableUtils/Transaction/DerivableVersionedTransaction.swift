import Foundation
import TweetNacl

public enum DerivableTransactionVersion: Equatable {
    case v0
    case legacy
}

public struct DerivableVersionedTransaction: Equatable {
    public var message: DerivableVersionedMessage
    public internal(set) var signatures: [Data]

    public mutating func setRecentBlockHash(_ blockHash: DerivableBlockHash) {
        message.setRecentBlockHash(blockHash)
    }

    public var version: DerivableTransactionVersion {
        message.value.version
    }

    public init(message: DerivableVersionedMessage, signatures: [Data]? = nil) {
        self.message = message

        if let signatures = signatures {
            self.signatures = signatures
        } else {
            var signatures: [Data] = []
            for _ in 0 ..< message.value.header.numRequiredSignatures {
                signatures.append(DerivableConstants.defaultSignature)
            }
            self.signatures = signatures
        }
    }

    public func serialize() throws -> Data {
        let serializedMessage = try message.value.serialize()

        let encodedSignaturesLength = Data.encodeLength(signatures.count)
        let signaturesData = signatures.reduce(Data(), +)

        var serializedTransaction: Data = .init()
        serializedTransaction.append(encodedSignaturesLength)
        serializedTransaction.append(signaturesData)
        serializedTransaction.append(serializedMessage)

        return serializedTransaction
    }

    public static func deserialize(data: Data) throws -> Self {
        var byteArray = BinaryReader(bytes: data.bytes)

        var signatures: [Data] = []
        let signaturesLength = try byteArray.decodeLength()
        for _ in 0 ..< signaturesLength {
            let signatureData = try byteArray.read(count: DerivableConstants.signatureLength)
            signatures.append(Data(signatureData))
        }

        let versionedMessage = try DerivableVersionedMessage.deserialize(data: Data(byteArray.readAll()))

        return .init(message: versionedMessage, signatures: signatures)
    }

    public mutating func sign(signers: [DerivableKeyPair]) throws {
        let messageData = try message.value.serialize()
        let signerPubkeys = message.value.staticAccountKeys.prefix(message.value.header.numRequiredSignatures)

        for signer in signers {
            guard let signerIndex = signerPubkeys.firstIndex(of: signer.publicKey) else {
                print("Cannot sign with non signer key \(signer.publicKey.base58EncodedString)")
                continue
            }
            signatures[signerIndex] = try NaclSign.signDetached(
                message: messageData,
                secretKey: signer.secretKey
            )
        }
    }

    public mutating func addSignature(publicKey: PublicKey, signature: Data) throws {
        let signerPubkeys = Array(message.value.staticAccountKeys.prefix(message.value.header.numRequiredSignatures))

        guard let signerIndex = signerPubkeys.firstIndex(of: publicKey) else {
            throw DerivableVersionedTransactionError.nonRequiredSigner(publicKey.base58EncodedString)
        }

        signatures[signerIndex] = signature
    }
}
