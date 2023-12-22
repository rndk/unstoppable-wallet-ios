import Foundation
import BigInt
import Combine
import HsExtensions

class DerivableCoinAccountInfoManager {
  private let storage: DerivableCoinAccountInfoStorage
  private let address: String
  private let blockchainUid: String
  
  init(
    storage: DerivableCoinAccountInfoStorage,
    address: String,
    blockchainUid: String
  ) {
    self.storage = storage
    self.address = address
    self.blockchainUid = blockchainUid
  }
  
  private let balanceSubject = PassthroughSubject<BigUInt, Never>()
  
  var coinBalance: BigUInt {
    storage.balance(address: self.address, blockchainUid: blockchainUid) ?? 0
  }
  
  var accountActive: Bool = true
}

extension DerivableCoinAccountInfoManager {
  var balancePublisher: AnyPublisher<BigUInt, Never> {
    balanceSubject.eraseToAnyPublisher()
  }
  
  func balance(contractAddress: String) -> BigUInt {
    storage.balance(address: contractAddress, blockchainUid: blockchainUid) ?? 0
  }
  
  func handle(newBalance: UInt64) {
    accountActive = true
    let balance = BigUInt(newBalance)
    storage.save(balance: balance, address: self.address, blockchainUid: blockchainUid)
    balanceSubject.send(balance)
  }
  
  func handleInactiveAccount() {
      accountActive = false
      balanceSubject.send(BigUInt.zero)
  }
}
