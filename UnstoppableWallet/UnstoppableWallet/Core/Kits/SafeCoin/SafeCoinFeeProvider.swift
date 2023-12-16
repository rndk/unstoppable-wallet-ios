import Foundation
import BigInt

class SafeCoinFeeProvider {
  private let safeCoinGridProvider: SafeCoinGridProvider
  
  init(safeCoinGridProvider: SafeCoinGridProvider) {
    self.safeCoinGridProvider = safeCoinGridProvider
  }
}

extension SafeCoinFeeProvider {
  
  func estimateFee(
    to: String,
    sendAmount: BigUInt,
    currentAmount: BigUInt
  ) async throws -> DerivablePreparedTransaction {
    //todo передать все параметры наверное надо
    return try await safeCoinGridProvider.estimateFee(to: to, amount: UInt64(sendAmount))
  }
  
}
