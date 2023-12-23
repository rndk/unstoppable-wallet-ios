import Foundation
import RxSwift
import BigInt
import HsToolKit
import MarketKit

class DerivableCoinTransactionsAdapter: BaseDerivableCoinAdapter {
  
  private let blockchainType: BlockchainType
  
  override init(coinKitWrapper: DerivableCoinKitWrapper) {
    self.blockchainType = coinKitWrapper.blockchainType
    super.init(coinKitWrapper: coinKitWrapper)
  }
  
  private func convert(coinTransaction: DerivableCoinTransaction) -> TransactionRecord? {
    //TODO проверить все ли тут правильно, возможно в транзакцию надо пихать больше данных
    return TransactionRecord(
//      source: TransactionSource(blockchainType: BlockchainType(uid: "safe-coin-2"), meta: nil),
//      source: TransactionSource(blockchainType: BlockchainType(uid: BlockchainType.safeCoin.uid), meta: nil),
      source: TransactionSource(blockchainType: BlockchainType(uid: self.blockchainType.uid), meta: nil),
      uid: coinTransaction.hash,
      transactionHash: coinTransaction.hash,
      transactionIndex: 0,
      blockHeight: nil,
      confirmationsThreshold: nil,
      date: Date(timeIntervalSince1970: Double(coinTransaction.blockTime / 1000)),
      failed: coinTransaction.isFailed
    )
  }
  
}

extension DerivableCoinTransactionsAdapter: ITransactionsAdapter {
  func explorerUrl(transactionHash: String) -> String? {
    //TODO тут надо урл эксплорера в зависимости от блокчейна
    kit.networkUrl
  }
  
  var explorerTitle: String {
    "SafeCoinExplorer"
  }
  
  var syncing: Bool {
    kit.syncState.syncing
  }
  
  var syncingObservable: RxSwift.Observable<Void> {
    kit.syncStatePublisher.asObservable().map { _ in () }
  }
  
  var lastBlockInfo: LastBlockInfo? {
    print(">>> SafeCoinTransactionsAdapter lastBlockInfo")
    return kit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
  }
  
  var lastBlockUpdatedObservable: RxSwift.Observable<Void> {
    print(">>> SafeCoinTransactionsAdapter lastBlockUpdatedObservable")
    return kit.lastBlockHeightPublisher.asObservable().map { _ in () }
  }
  
  func transactionsObservable(
    token: MarketKit.Token?,
    filter: TransactionTypeFilter
  ) -> RxSwift.Observable<[TransactionRecord]> {
    print(">>> SafeCoinTransactionsAdapter transactionsObservable()")
    return kit.transactionsPublisher(
      token: token,
      filter: filter
    )
    .asObservable()
    .map { [weak self] in
      $0.compactMap { self?.convert(coinTransaction: $0) }
    }
  }
  
  func transactionsSingle(
    from: TransactionRecord?,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter,
    limit: Int
  ) -> RxSwift.Single<[TransactionRecord]> {
    print(">>> SafeCoinTransactionsAdapter transactionsSingle()")
    let transactions = kit.transactions(
      from: from,
      token: token,
      filter: filter,
      limit: limit
    )
    return Single.just(transactions.compactMap { self.convert(coinTransaction: $0) })
  }
 
  func rawTransaction(hash: String) -> String? {
    nil
  }
  
  
}
