import Foundation
import BigInt

class DerivableCoinTransactionSender {
  private let networkInteractor: DerivableCoinNetworkInteractor
  
  init(networkInteractor: DerivableCoinNetworkInteractor) {
    self.networkInteractor = networkInteractor
  }
}

extension DerivableCoinTransactionSender {
  
  func sendTransaction(
    transaction: DerivablePreparedTransaction
  ) async throws -> String {
    try await networkInteractor.sendTransaction(transaction: transaction)
  }
  
}
