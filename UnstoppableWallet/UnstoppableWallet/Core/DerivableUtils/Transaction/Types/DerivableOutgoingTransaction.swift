import Foundation
import MarketKit

class DerivableOutgoingTransaction: TransactionRecord {
  let transactionValue: TransactionValue
  let baseToken: Token
  let from: String
  let to: String
  
  init(
    hash: String,
    blockTime: UInt64,
    from: String,
    to: String,
    value: UInt64,
    fee: UInt64,
    isFailed: Bool,
    source: TransactionSource,
    transactionValue: TransactionValue,
    baseToken: Token
  ) {
    self.transactionValue = transactionValue
    self.baseToken = baseToken
    self.from = from
    self.to = to
    //TODO blockHeight and confirmationsThreshold
    super.init(
      source: source,
      uid: hash,
      transactionHash: hash,
      transactionIndex: 0,
      blockHeight: 0,
      confirmationsThreshold: 0,
      date: Date(timeIntervalSince1970: Double(blockTime)),
      failed: isFailed
    )
  }
}
