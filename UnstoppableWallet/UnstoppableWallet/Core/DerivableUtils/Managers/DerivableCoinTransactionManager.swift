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
    rpcSourceUrl: String,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter
  ) -> AnyPublisher<[DerivableCoinTransaction], Never> {
    switch filter {
    case .incoming: incomingTransactions(rpcSourceUrl: rpcSourceUrl)
    case .outgoing: outgoingTransactions(rpcSourceUrl: rpcSourceUrl)
    default: allTransactions(rpcSourceUrl: rpcSourceUrl)
    }
    return transactionsPublisher
  }
  
  func transactions(
    rpcSourceUrl: String,
    from: TransactionRecord?,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter,
    limit: Int
  ) -> [DerivableCoinTransaction] {
    return storage.transactions(
      rpcSourceUrl: rpcSourceUrl,
      address: self.userAddress,
      blockchainUid: blockchainId,
      fromHash: from?.transactionHash,
      filter: filter,
      limit: limit
    )
  }
  
  func allTransactions(rpcSourceUrl: String) {
    let allTransactions = storage.allTransactions(
      rpcSourceUrl: rpcSourceUrl,
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
    transactionsSubject.send(allTransactions)
  }
  
  func incomingTransactions(rpcSourceUrl: String) {
    let incomingTransactions = storage.incomingTransactions(
      rpcSourceUrl: rpcSourceUrl,
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
    transactionsSubject.send(incomingTransactions)
  }
  
  func outgoingTransactions(rpcSourceUrl: String) {
    let outgoingTransactions = storage.outgoingTransactions(
      rpcSourceUrl: rpcSourceUrl,
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
  
  func getLastTransaction(rpcSourceUrl: String) -> DerivableCoinTransaction? {
    storage.lastTransaction(
      rpcSourceUrl: rpcSourceUrl,
      address: self.userAddress,
      blockchainUid: self.blockchainId
    )
  }
  
  func handle() {
    //
  }
  
}
