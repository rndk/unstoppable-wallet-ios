import Foundation
import HsToolKit
import BigInt
import Combine
import MarketKit

public class DerivableCoinKit {
  private let signer: DerivableCoinSigner
  private let syncer: DerivableCoinSyncer
  private let accountInfoManager: DerivableCoinAccountInfoManager
  private let transactionManager: DerivableCoinTransactionManager
  private let transactionSender: DerivableCoinTransactionSender
  private let feeProvider: DerivableCoinFeeProvider
  
  public let address: String
  public let blockchainUid: String
  public var networkUrl: String
  public var derivableNetwork: DerivableCoinNetwork
  
  private let systemProframId: PublicKey
  private let tokenProgramId: PublicKey
  private let associatedProgramId: PublicKey
  private let sysvarRent: PublicKey
  
  
  init(
    blockchainUid: String,
    address: String,
    networkUrl: String,
    derivableNetwork: DerivableCoinNetwork,
    syncer: DerivableCoinSyncer,
    accountInfoManager: DerivableCoinAccountInfoManager,
    transactionManager: DerivableCoinTransactionManager,
    transactionSender: DerivableCoinTransactionSender,
    feeProvider: DerivableCoinFeeProvider,
    signer: DerivableCoinSigner,
    systemProframId: PublicKey,
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    sysvarRent: PublicKey
    
  ) {
    self.address = address
    self.blockchainUid = blockchainUid
    self.networkUrl = networkUrl
    self.derivableNetwork = derivableNetwork
    self.accountInfoManager = accountInfoManager
    self.transactionManager = transactionManager
    self.transactionSender = transactionSender
    self.syncer = syncer
    self.feeProvider = feeProvider
    self.signer = signer
    
    self.systemProframId = systemProframId
    self.tokenProgramId = tokenProgramId
    self.associatedProgramId = associatedProgramId
    self.sysvarRent = sysvarRent
  }
  
  func updateNetwork(source: String) {
    self.networkUrl = source
    self.syncer.updateGridProviderNetwork(source: source)
  }
}

extension DerivableCoinKit {
  
  func isMainNet() -> Bool {
    self.derivableNetwork.isMainNet(source: self.networkUrl)
  }
  
  public var lastBlockHeight: Int? {
    syncer.lastBlockHeight
  }
  
  public var syncState: DerivableCoinSyncState {
    syncer.state
  }
  
  public var сoinSigner: DerivableCoinSigner {
    self.signer
  }
  
  public var receiveAddress: String {
    self.address
  }
  
  public var lastBlockHeightPublisher: AnyPublisher<Int, Never> {
    syncer.$lastBlockHeight.eraseToAnyPublisher()
  }
  
  public var syncStatePublisher: AnyPublisher<DerivableCoinSyncState, Never> {
    syncer.$state.eraseToAnyPublisher()
  }
  
  public var balancePublisher: AnyPublisher<BigUInt, Never> {
    accountInfoManager.balancePublisher
  }
  
  public var allTransactionsPublisher: AnyPublisher<[DerivableCoinTransaction], Never> {
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
  ) -> AnyPublisher<[DerivableCoinTransaction], Never> {
      return transactionManager.transactionsPublisher(token: token, filter: filter)
  }
  
  func transactions(
    from: TransactionRecord?,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter,
    limit: Int
  ) -> [DerivableCoinTransaction] {
    transactionManager.transactions(from: from, token: token, filter: filter, limit: limit)
  }
  
  public func prepareTransaction(
    to: String,
    sendAmount: BigUInt
  ) async throws -> DerivablePreparedTransaction {
    try await feeProvider.prepareTransaction(
      to: to,
      sendAmount: sendAmount,
      currentAmount: accountInfoManager.coinBalance
    )
  }
  
  public func calcMinRent() async throws -> BigUInt {
    try await feeProvider.calcMinRent()
  }
  
  public func send(transaction: DerivablePreparedTransaction) async throws {
    try await transactionSender.sendTransaction(transaction: transaction)
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

extension DerivableCoinKit {
  
  public static func instance(
    signer: DerivableCoinSigner,
    blockchainUid: String,
    address: String,
    networkUrl: String,
    walletId: String,
    derivableNetwork: DerivableCoinNetwork,
    accountInfoStorage: DerivableCoinAccountInfoStorage,
    transactionStorage: DerivableCoinTransactionStorage,
    syncerStorage: DerivableCoinSyncerStorage,
    systemProframId: PublicKey,
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    sysvarRent: PublicKey,
    logger: Logger = Logger(minLogLevel: .error)
  ) throws -> DerivableCoinKit {
    
    let accountInfoManager = DerivableCoinAccountInfoManager(
      storage: accountInfoStorage,
      address: address,
//      blockchainUid: BlockchainType.safeCoin.uid
      blockchainUid: blockchainUid
    )
    let transactionManager = DerivableCoinTransactionManager(
      userAddress: address,
//      blockchainId: BlockchainType.safeCoin.uid,
      blockchainId: blockchainUid,
      storage: transactionStorage
    )
    
    let networkManager = NetworkManager(logger: logger)
    
    let networkInteractor = DerivableCoinNetworkInteractor(
      baseUrl: networkUrl,
//      blockchainUid: BlockchainType.safeCoin.uid,
      blockchainUid: blockchainUid,
      networkManager: networkManager,
      signer: signer,
      systemProframId: systemProframId,
      tokenProgramId: tokenProgramId,
      associatedProgramId: associatedProgramId,
      sysvarRent: sysvarRent
    )
    let feeProvider = DerivableCoinFeeProvider(networkInteractor: networkInteractor)
    
    let syncer = DerivableCoinSyncer(
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      networkInteractor: networkInteractor,
      syncerStorage: syncerStorage,
      address: address,
//      blockchainUid: BlockchainType.safeCoin.uid
      blockchainUid: blockchainUid
    )
    let transactionSender = DerivableCoinTransactionSender(networkInteractor: networkInteractor)
    
    let kit = DerivableCoinKit(
      blockchainUid: blockchainUid,
      address: address,
      networkUrl: networkUrl,
      derivableNetwork: derivableNetwork,
      syncer: syncer,
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      transactionSender: transactionSender,
      feeProvider: feeProvider,
      signer: signer,
      systemProframId: systemProframId,
      tokenProgramId: tokenProgramId,
      associatedProgramId: associatedProgramId,
      sysvarRent: sysvarRent
    )
    
    return kit
  }
  
//  private static func dataDirectoryUrl() throws -> URL {
//    let fileManager = FileManager.default
//    
//    let url = try fileManager
//      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//      .appendingPathComponent("safe-coin-kit", isDirectory: true)
//    
//    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
//    
//    return url
//  }
  
}

extension DerivableCoinKit {
  
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
