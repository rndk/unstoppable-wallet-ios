import Foundation

public struct DerivableMessageAddressTableLookup: Equatable {
    public let accountKey: PublicKey
    public let writableIndexes: [UInt8]
    public let readonlyIndexes: [UInt8]

    public init(accountKey: PublicKey, writableIndexes: [UInt8], readonlyIndexes: [UInt8]) {
        self.accountKey = accountKey
        self.writableIndexes = writableIndexes
        self.readonlyIndexes = readonlyIndexes
    }
}
