import Foundation

public enum DerivableVersionedMessage: Equatable {
    case legacy(DerivableMessage)
    case v0(DerivableMessageV0)

    static func deserialize(data: Data) throws -> Self {
        guard !data.isEmpty else {
            throw DerivableVersionedMessageError.deserializationError("Data is empty")
        }
        let prefix: UInt8 = data.first!
        let maskedPrefix = prefix & DerivableConstants.versionPrefixMask

        if maskedPrefix == prefix {
            return try .legacy(.from(data: data))
        } else {
            return try .v0(.deserialize(serializedMessage: data))
        }
    }

    public var value: IMessage {
        switch self {
        case let .legacy(message): return message
        case let .v0(message): return message
        }
    }

    public mutating func setRecentBlockHash(_ blockHash: DerivableBlockHash) {
        switch self {
        case var .legacy(message):
            message.recentBlockhash = blockHash
            self = .legacy(message)
        case var .v0(messageV0):
            messageV0.recentBlockhash = blockHash
            self = .v0(messageV0)
        }
    }
}
