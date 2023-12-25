import Foundation
import MarketKit
import BigInt

class DerivableTransactionConverter {
  
  private let selfAddress: String
  private let source: TransactionSource
  private let baseToken: MarketKit.Token
  
  init(selfAddress: String, source: TransactionSource, baseToken: MarketKit.Token) {
    self.selfAddress = selfAddress
    self.source = source
    self.baseToken = baseToken
  }
  
  private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
      guard let significand = Decimal(string: amount.description), significand != 0 else {
          return 0
      }
      return Decimal(sign: sign, exponent: -decimals, significand: significand)
  }

  private func baseCoinValue(value: UInt64, sign: FloatingPointSign) -> TransactionValue {
      let amount = convertAmount(
        amount: BigUInt(value),
        decimals: baseToken.decimals,
        sign: sign
      )
      return .coinValue(token: baseToken, value: amount)
  }
  
  public func convert(coinTransaction: DerivableCoinTransaction) -> TransactionRecord? {
    let incomingTx = self.selfAddress == coinTransaction.to
    
    if incomingTx {
      return DerivableIncomingTransaction(
        hash: coinTransaction.hash,
        blockTime: coinTransaction.blockTime,
        from: coinTransaction.from,
        to: coinTransaction.to,
        value: coinTransaction.value,
        fee: coinTransaction.fee,
        isFailed: coinTransaction.isFailed,
        source: self.source,
        transactionValue: baseCoinValue(value: coinTransaction.value, sign: .plus),
        baseToken: self.baseToken
      )
    } else {
      return DerivableOutgoingTransaction(
        hash: coinTransaction.hash,
        blockTime: coinTransaction.blockTime,
        from: coinTransaction.from,
        to: coinTransaction.to,
        value: coinTransaction.value,
        fee: coinTransaction.fee,
        isFailed: coinTransaction.isFailed,
        source: self.source,
        transactionValue: baseCoinValue(value: coinTransaction.value, sign: .minus),
        baseToken: self.baseToken
      )
    }
  }
  
}
