import Foundation

public protocol IMessage {
    var version: DerivableTransactionVersion { get }
    var header: DerivableMessageHeader { get }
    var recentBlockhash: String { get }

    func serialize() throws -> Data

    var staticAccountKeys: [PublicKey] { get }
}
