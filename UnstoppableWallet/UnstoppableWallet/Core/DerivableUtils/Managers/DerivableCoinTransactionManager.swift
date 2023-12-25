import Foundation
import Combine
import MarketKit

class DerivableCoinTransactionManager {
  private let userAddress: String
  private let blockchainId: String
  private let storage: DerivableCoinTransactionStorage
  
  init(
    userAddress: String,
    blockchainId: String,
    storage: DerivableCoinTransactionStorage
  ) {
    self.userAddress = userAddress
    self.blockchainId = blockchainId
    self.storage = storage
  }
  
  private let transactionsSubject = PassthroughSubject<[DerivableCoinTransaction], Never>()
}

extension DerivableCoinTransactionManager {
  
  var transactionsPublisher: AnyPublisher<[DerivableCoinTransaction], Never> {
    transactionsSubject.eraseToAnyPublisher()
  }
  
  func transactionsPublisher(
    token: MarketKit.Token?,
    filter: TransactionTypeFilter
  ) -> AnyPublisher<[DerivableCoinTransaction], Never> {
    switch filter {
    case .incoming: incomingTransactions()
    case .outgoing: outgoingTransactions()
    default: allTransactions()
    }
    return transactionsPublisher
  }
  
  func transactions(
    from: TransactionRecord?,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter,
    limit: Int
  ) -> [DerivableCoinTransaction] {
    return storage.transactions(
      address: self.userAddress,
      blockchainUid: blockchainId,
      fromHash: from?.transactionHash,
      filter: filter,
      limit: limit
    )
  }
  
  func allTransactions() {
    let allTransactions = storage.allTransactions(
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
    transactionsSubject.send(allTransactions)
  }
  
  func incomingTransactions() {
    let incomingTransactions = storage.incomingTransactions(
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
    transactionsSubject.send(incomingTransactions)
  }
  
  func outgoingTransactions() {
    let outgoingTransactions = storage.outgoingTransactions(
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
    transactionsSubject.send(outgoingTransactions)
  }
  
  func save(
    transactions: [DerivableCoinTransaction],
    replaceOnConflict: Bool
  ) {
    storage.save(transactions: transactions, replaceOnConflict: replaceOnConflict)
    transactionsSubject.send(transactions)
  }
  
  func getLastTransaction() -> DerivableCoinTransaction? {
    storage.lastTransaction(
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
  }
  
  func handle() {
    //
  }
  
}
