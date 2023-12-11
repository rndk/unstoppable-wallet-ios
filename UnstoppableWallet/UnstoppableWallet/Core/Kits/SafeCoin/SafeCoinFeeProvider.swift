import Foundation
import BigInt

class SafeCoinFeeProvider {
  private let safeCoinGridProvider: SafeCoinGridProvider
  
  init(safeCoinGridProvider: SafeCoinGridProvider) {
    self.safeCoinGridProvider = safeCoinGridProvider
  }
}

extension SafeCoinFeeProvider {
  
  func estimateFee(to: String, sendAmount: BigUInt, currentAmount: BigUInt) async throws -> BigUInt {
    BigUInt(0) //TODO дернуть расчет газа на основе того сколько хочешь отправить и сколько вообще есть
  }
  
}
