import Foundation
import HsToolKit
import BigInt
import Combine
import MarketKit

public class SafeCoinKit {
  private let signer: SafeCoinSigner
  private let syncer: SafeCoinSyncer
  private let accountInfoManager: SafeCoinAccountInfoManager
  private let transactionManager: SafeCoinTransactionManager
  private let transactionSender: SafeCoinTransactionSender
  private let feeProvider: SafeCoinFeeProvider
  
  public let address: String
  public var networkUrl: String
  
  
  init(
    address: String,
    networkUrl: String,
    syncer: SafeCoinSyncer,
    accountInfoManager: SafeCoinAccountInfoManager,
    transactionManager: SafeCoinTransactionManager,
    transactionSender: SafeCoinTransactionSender,
    feeProvider: SafeCoinFeeProvider,
    signer: SafeCoinSigner
  ) {
    self.address = address
    self.networkUrl = networkUrl
    self.accountInfoManager = accountInfoManager
    self.transactionManager = transactionManager
    self.transactionSender = transactionSender
    self.syncer = syncer
    self.feeProvider = feeProvider
    self.signer = signer
  }
  
  func updateNetwork(source: String) {
    self.networkUrl = source
    self.syncer.updateGridProviderNetwork(source: source)
  }
}

extension SafeCoinKit {
  
  func isMainNet() -> Bool {
    SafeCoinNetwork.isMainNet(source: self.networkUrl)
  }
  
  public var lastBlockHeight: Int? {
    syncer.lastBlockHeight
  }
  
  public var syncState: SafeCoinSyncState {
    syncer.state
  }
  
  public var safeCoinSigner: SafeCoinSigner {
    self.signer
  }
  
  public var receiveAddress: String {
    self.address
  }
  
  public var lastBlockHeightPublisher: AnyPublisher<Int, Never> {
    syncer.$lastBlockHeight.eraseToAnyPublisher()
  }
  
  public var syncStatePublisher: AnyPublisher<SafeCoinSyncState, Never> {
    syncer.$state.eraseToAnyPublisher()
  }
  
  public var balancePublisher: AnyPublisher<BigUInt, Never> {
    accountInfoManager.balancePublisher
  }
  
  public var allTransactionsPublisher: AnyPublisher<[SafeCoinTransaction], Never> {
    transactionManager.transactionsPublisher
  }
  
  public func balance(contractAddress: String) -> BigUInt {
    accountInfoManager.balance(contractAddress: contractAddress)
  }
  
  public func balancePublisher(contractAddress: String) -> AnyPublisher<BigUInt, Never> {
    accountInfoManager.balancePublisher/*(contractAddress: contractAddress)*/
  }
  
  func transactionsPublisher(
    token: MarketKit.Token?,
    filter: TransactionTypeFilter
  ) -> AnyPublisher<[SafeCoinTransaction], Never> {
      return transactionManager.transactionsPublisher(token: token, filter: filter)
  }
  
  func transactions(
    from: TransactionRecord?,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter,
    limit: Int
  ) -> [SafeCoinTransaction] {
    transactionManager.transactions(from: from, token: token, filter: filter, limit: limit)
  }
  
  public func prepareTransaction(
    to: String,
    sendAmount: BigUInt
  ) async throws -> DerivablePreparedTransaction {
    try await feeProvider.prepareTransaction(
      to: to,
      sendAmount: sendAmount,
      currentAmount: accountInfoManager.safeCoinBalance
    )
  }
  
  public func calcMinRent() async throws -> BigUInt {
    try await feeProvider.calcMinRent()
  }
  
  public func send(transaction: DerivablePreparedTransaction) async throws {
    let transactionId = try await transactionSender.sendTransaction(transaction: transaction)
    print(">>> SafeCoinKit send transaction, answer transactionId: \(transactionId)")
    transactionManager.handle(/*newTransaction: newTransaction*/)
  }
  
  public func start() {
    syncer.start()
  }
  
  public func stop() {
    syncer.stop()
  }
  
  public func refresh() {
    syncer.refresh()
  }
}

extension SafeCoinKit {
  
  //    public static func clear(exceptFor excludedFiles: [String]) throws {
  //        let fileManager = FileManager.default
  //        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)
  //
  //        for filename in fileUrls {
  //            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
  //                try fileManager.removeItem(at: filename)
  //            }
  //        }
  //    }
  
  public static func instance(
    signer: SafeCoinSigner,
    address: String,
    networkUrl: String,
    walletId: String,
    logger: Logger = Logger(minLogLevel: .error)
  ) throws -> SafeCoinKit {
    let databaseDirectoryUrl = try dataDirectoryUrl()
    
    //TODO тут наверное надо заменить на DerivableStorage
    
    let accountInfoStorage = SafeCoinAccountInfoStorage(
      databaseDirectoryUrl: databaseDirectoryUrl,
      databaseFileName: "safe-coinaccount-info-storage"
    )
    let transactionStorage = SafeCoinTransactionStorage(
      databaseDirectoryUrl: databaseDirectoryUrl,
      databaseFileName: "safe-coin-transactions-storage"
    )

    let syncerStorage = DerivableCoinSyncerStorage(
      databaseDirectoryUrl: databaseDirectoryUrl,
      databaseFileName: "derivable-syncer-storage"
    )
    
    let accountInfoManager = SafeCoinAccountInfoManager(storage: accountInfoStorage, address: address)
    let transactionManager = SafeCoinTransactionManager(userAddress: address, storage: transactionStorage)
    
    let networkManager = NetworkManager(logger: logger)
    
    let safeCoinGridProvider = SafeCoinGridProvider(
      baseUrl: networkUrl,
      networkManager: networkManager,
      safeCoinSigner: signer
    )
    let feeProvider = SafeCoinFeeProvider(safeCoinGridProvider: safeCoinGridProvider)
    
    let syncer = SafeCoinSyncer(
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      safeCoinGridProvider: safeCoinGridProvider,
      syncerStorage: syncerStorage,
      address: address
    )
    let transactionSender = SafeCoinTransactionSender(safeCoinGridProvider: safeCoinGridProvider)
    
    let kit = SafeCoinKit(
      address: address,
      networkUrl: networkUrl,
      syncer: syncer,
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      transactionSender: transactionSender,
      feeProvider: feeProvider,
      signer: signer
    )
    
    return kit
  }
  
  private static func dataDirectoryUrl() throws -> URL {
    let fileManager = FileManager.default
    
    let url = try fileManager
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("safe-coin-kit", isDirectory: true)
    
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    
    return url
  }
  
}

extension SafeCoinKit {
  
  public enum SyncError: Error {
    case notStarted
    case noNetworkConnection
  }
  
  public enum SendError: Error {
    case notSupportedContract
    case abnormalSend
    case invalidParameter
  }
  
}
