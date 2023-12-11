import Foundation
import BigInt

class SafeCoinTransactionSender {
  private let safeCoinGridProvider: SafeCoinGridProvider
  
  init(safeCoinGridProvider: SafeCoinGridProvider) {
    self.safeCoinGridProvider = safeCoinGridProvider
  }
}

extension SafeCoinTransactionSender {
  
  func sendTransaction(to: String, amount: BigUInt, fee: BigUInt) async throws -> SafeCoinTransaction? {
    nil //TODO рассчитать газ, а затем, если все норм, выполнить транзакцию
  }
  
}
