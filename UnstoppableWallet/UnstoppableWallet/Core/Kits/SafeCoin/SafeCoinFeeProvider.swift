import Foundation
import BigInt

class SafeCoinFeeProvider {
  private let safeCoinGridProvider: SafeCoinGridProvider
  
  init(safeCoinGridProvider: SafeCoinGridProvider) {
    self.safeCoinGridProvider = safeCoinGridProvider
  }
}

extension SafeCoinFeeProvider {
  
  func prepareTransaction(
    to: String,
    sendAmount: BigUInt,
    currentAmount: BigUInt
  ) async throws -> DerivablePreparedTransaction {
    return try await safeCoinGridProvider.prepareTransaction(
      to: to, amount: UInt64(sendAmount)
    )
  }
  
  func calcMinRent() async throws -> BigUInt {
    return try await safeCoinGridProvider.calcMinRent()
  }
  
}
