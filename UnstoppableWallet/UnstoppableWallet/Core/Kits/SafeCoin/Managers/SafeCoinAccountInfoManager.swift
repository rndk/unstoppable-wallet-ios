import Foundation
import BigInt
import Combine
import HsExtensions

class SafeCoinAccountInfoManager {
  private let storage: SafeCoinAccountInfoStorage
  private let address: String
  
  init(storage: SafeCoinAccountInfoStorage, address: String) {
    self.storage = storage
    self.address = address
  }
  
  private let balanceSubject = PassthroughSubject<BigUInt, Never>()
  
  var safeCoinBalance: BigUInt {
    storage.balance(address: self.address) ?? 0
  }
  
  var accountActive: Bool = true
}

extension SafeCoinAccountInfoManager {
  var balancePublisher: AnyPublisher<BigUInt, Never> {
    balanceSubject.eraseToAnyPublisher()
  }
  
  func balance(contractAddress: String) -> BigUInt {
    storage.balance(address: contractAddress) ?? 0
  }
  
  func handle(newBalance: UInt64) {
    accountActive = true
    let balance = BigUInt(newBalance)
    storage.save(balance: balance, address: self.address)
    balanceSubject.send(balance)
  }
  
  func handleInactiveAccount() {
      accountActive = false
      balanceSubject.send(BigUInt.zero)
  }
}
