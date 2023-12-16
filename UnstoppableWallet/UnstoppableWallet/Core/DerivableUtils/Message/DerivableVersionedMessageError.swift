import Foundation

public enum DerivableVersionedMessageError: Error, Equatable {
    case expectedVersionedMessageButReceivedLegacyMessage
    case invalidMessageVersion(expectedVersion: UInt8, receivedVersion: UInt8)
    case deserializationError(String)
    case other(String)
}
