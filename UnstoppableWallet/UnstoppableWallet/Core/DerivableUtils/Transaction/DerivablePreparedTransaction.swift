import Foundation

public struct DerivablePreparedTransaction: Equatable {
  public init(
    transaction: DerivableTransaction,
    signers: [DerivableKeyPair],
    expectedFee: FeeAmount
  ) {
    self.transaction = transaction
    self.signers = signers
    self.expectedFee = expectedFee
  }
  
  public var transaction: DerivableTransaction
  public var signers: [DerivableKeyPair]
  public var expectedFee: FeeAmount
  
  public mutating func sign() throws {
    try transaction.sign(signers: signers)
  }
  
  public func serialize() throws -> String {
    var transaction = transaction
    let serializedTransaction = try transaction.serialize().bytes.toBase64()
#if DEBUG
    //            Logger.log(event: "serializedTransaction", message: serializedTransaction, logLevel: .debug)
    if let decodedTransaction = transaction.jsonString {
      //                Logger.log(event: "decodedTransaction", message: decodedTransaction, logLevel: .debug)
    }
#endif
    return serializedTransaction
  }
  
  public func findSignature(publicKey: PublicKey) throws -> String {
    guard let signature = transaction.findSignature(pubkey: publicKey)?.signature
    else {
      //            Logger.log(event: "SolanaSwift: findSignature", message: "Signature not found", logLevel: .error)
      //            throw DerivableVersionedTransactionError.signatureNotFound
      throw DerivableVersionedTransactionError.signatureNotFound
    }
    return Base58.encode(signature.bytes)
  }
}
