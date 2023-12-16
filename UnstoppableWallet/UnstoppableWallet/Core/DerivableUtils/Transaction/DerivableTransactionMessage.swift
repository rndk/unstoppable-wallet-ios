import Foundation

public struct DerivableTransactionMessage {
    var instructions: [TransactionInstruction]
    var recentBlockhash: String
    var payerKey: PublicKey

    public init(instructions: [TransactionInstruction], recentBlockhash: String, payerKey: PublicKey) {
        self.instructions = instructions
        self.recentBlockhash = recentBlockhash
        self.payerKey = payerKey
    }

    // TODO: implement
    // static func decompile() {}

    public func compileToLegacyMessage() throws -> DerivableMessage {
        try DerivableTransaction(
            instructions: instructions,
            recentBlockhash: recentBlockhash,
            feePayer: payerKey
        )
        .compileMessage()
    }

//    public func compileToV0Message(
//        addressLookupTableAccounts: [AddressLookupTableAccount]? = nil
//    ) throws -> DerivableMessageV0 {
//        try DerivableMessageV0.compile(
//            payerKey: payerKey,
//            instructions: instructions,
//            recentBlockHash: recentBlockhash,
//            addressLookupTableAccounts: addressLookupTableAccounts
//        )
//    }
}
