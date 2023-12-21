import Foundation
import BigInt

class SafeCoinTransactionSender {
  private let safeCoinGridProvider: SafeCoinGridProvider
  
  init(safeCoinGridProvider: SafeCoinGridProvider) {
    self.safeCoinGridProvider = safeCoinGridProvider
  }
}

extension SafeCoinTransactionSender {
  
  func sendTransaction(
    transaction: DerivablePreparedTransaction
  ) async throws -> String {
    try await safeCoinGridProvider.sendTransaction(transaction: transaction)
  }
  
}
