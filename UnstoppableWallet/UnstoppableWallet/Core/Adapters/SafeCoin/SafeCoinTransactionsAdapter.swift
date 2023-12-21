import Foundation
import RxSwift
import BigInt
import HsToolKit
import MarketKit

class SafeCoinTransactionsAdapter: BaseSafeCoinAdapter {
  
  override init(
    safeCoinKitWrapper: SafeCoinKitWrapper
  ) {
    super.init(safeCoinKitWrapper: safeCoinKitWrapper)
    //
  }
  
  private func convert(safeCoinTransaction: SafeCoinTransaction) -> TransactionRecord? {
    return TransactionRecord(
      source: TransactionSource(blockchainType: BlockchainType(uid: "safe-coin-2"), meta: nil),
      uid: safeCoinTransaction.hash,
      transactionHash: safeCoinTransaction.hash,
      transactionIndex: 0,
      blockHeight: nil,
      confirmationsThreshold: nil,
      date: Date(timeIntervalSince1970: Double(safeCoinTransaction.blockTime / 1000)),
      failed: safeCoinTransaction.isFailed
    )
  }
  
}

extension SafeCoinTransactionsAdapter: ITransactionsAdapter {
  func explorerUrl(transactionHash: String) -> String? {
    kit.networkUrl //TODO тут надо урл эксплорера в зависимости от блокчейна
  }
  
  var explorerTitle: String {
    "SafeCoinExplorer"
  }
  
//  func explorerUrl(transactionHash: String) -> String? {
//    //TODO
//    switch kit.network {
//    case .mainNet: ""
//    case .devNet: ""
//    case .testNet: ""
//    case .custom(_, let url): ""
//    }
//  }
  
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
      $0.compactMap { self?.convert(safeCoinTransaction: $0) }
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
    return Single.just(transactions.compactMap { self.convert(safeCoinTransaction: $0) })
  }
 
  func rawTransaction(hash: String) -> String? {
    //TODO
    nil
  }
  
  
}
