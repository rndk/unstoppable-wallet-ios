import Foundation
import Combine

class SafeCoinTransactionManager {
  private let userAddress: String
  private let storage: SafeCoinTransactionStorage
  
  init(userAddress: String, storage: SafeCoinTransactionStorage) {
    self.userAddress = userAddress
    self.storage = storage
  }
  
  private let transactionsSubject = PassthroughSubject<[SafeCoinTransaction], Never>()
}

extension SafeCoinTransactionManager {
  
  var transactionsPublisher: AnyPublisher<[SafeCoinTransaction], Never> {
    transactionsSubject.eraseToAnyPublisher()
  }
  
  func allTransactions()/* -> [SafeCoinTransaction]*/ {
    let allTransactions = storage.allTransactions(address: self.userAddress)
    transactionsSubject.send(allTransactions)
  }
  
  func incomingTransactions() {
    let incomingTransactions = storage.incomingTransactions(address: self.userAddress)
    transactionsSubject.send(incomingTransactions)
  }
  
  func outgoingTransactions() {
    let outgoingTransactions = storage.outgoingTransactions(address: self.userAddress)
    transactionsSubject.send(outgoingTransactions)
  }
  
  func save(transactions: [SafeCoinTransaction], replaceOnConflict: Bool) {
    storage.save(transactions: transactions, replaceOnConflict: replaceOnConflict)
    transactionsSubject.send(transactions)
  }
  
  func getLastTransaction() -> SafeCoinTransaction? {
    storage.lastTransaction(address: userAddress)
  }
  
  func handle() {
    //TODO тут типа можно передать не список транзакций, а какой-нить Responce, распарсить его в список транзакций и затем уже сохранить все это дело
  }
  
}
