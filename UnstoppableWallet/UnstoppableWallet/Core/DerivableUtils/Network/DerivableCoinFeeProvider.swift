import Foundation
import BigInt

class DerivableCoinFeeProvider {
  private let networkInteractor: DerivableCoinNetworkInteractor
  
  init(networkInteractor: DerivableCoinNetworkInteractor) {
    self.networkInteractor = networkInteractor
  }
}

extension DerivableCoinFeeProvider {
  
  func prepareTransaction(
    to: String,
    sendAmount: BigUInt,
    currentAmount: BigUInt
  ) async throws -> DerivablePreparedTransaction {
    return try await networkInteractor.prepareTransaction(
      to: to, amount: UInt64(sendAmount)
    )
  }
  
  func calcMinRent() async throws -> BigUInt {
    return try await networkInteractor.calcMinRent()
  }
  
}
