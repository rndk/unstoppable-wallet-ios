import Foundation
import RxSwift
import MarketKit

class DerivableCoinTransactionsAdapter: BaseDerivableCoinAdapter {
  
  private let blockchainType: BlockchainType
  private let baseToken: Token
  private let transactionSource: TransactionSource
  private let converter: DerivableTransactionConverter
  
  init(coinKitWrapper: DerivableCoinKitWrapper, transactionSource: TransactionSource, baseToken: Token) {
    self.blockchainType = coinKitWrapper.blockchainType
    self.transactionSource = transactionSource
    self.baseToken = baseToken
    
    self.converter = DerivableTransactionConverter(
      selfAddress: coinKitWrapper.coinKit.address,
      source: transactionSource,
      baseToken: baseToken
    )
    
    super.init(coinKitWrapper: coinKitWrapper)
  }
  
  private func convert(coinTransaction: DerivableCoinTransaction) -> TransactionRecord? {
    converter.convert(coinTransaction: coinTransaction)
  }
  
}

extension DerivableCoinTransactionsAdapter: ITransactionsAdapter {
  func explorerUrl(transactionHash: String) -> String? {
    let url = switch blockchainType {
    case .safeCoin: "https://explorer.safecoin.org/tx/\(transactionHash)"
    case .solana: "https://explorer.solana.com/tx/\(transactionHash)"
    default: ""
    }
    return url
  }
  
  var explorerTitle: String {
    let title: String
    switch blockchainType{
    case .safeCoin: title = "SafecoinExplorer"
    case .solana: title = "SolanaExplorer"
    default: title = "Explorer"
    }
    return title
  }
  
  var syncing: Bool {
    kit.syncState.syncing
  }
  
  var syncingObservable: RxSwift.Observable<Void> {
    kit.syncStatePublisher.asObservable().map { _ in () }
  }
  
  var lastBlockInfo: LastBlockInfo? {
    return kit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
  }
  
  var lastBlockUpdatedObservable: RxSwift.Observable<Void> {
    return kit.lastBlockHeightPublisher.asObservable().map { _ in () }
  }
  
  func transactionsObservable(
    token: MarketKit.Token?,
    filter: TransactionTypeFilter
  ) -> RxSwift.Observable<[TransactionRecord]> {
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
