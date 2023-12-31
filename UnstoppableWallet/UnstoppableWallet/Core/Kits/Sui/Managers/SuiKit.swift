import Foundation
import HsToolKit
import BigInt
import Combine
import MarketKit

public class SuiKit {
  
  private let token: Token
  private let signer: SuiSigner
  private let syncer: SuiCoinSyncer
  private let accountInfoManager: DerivableCoinAccountInfoManager
  private let transactionManager: DerivableCoinTransactionManager
  private let transactionSender: SuiTransactionSender
  private let feeProvider: SuiFeeProvider
  
  public let address: String
  public let blockchainUid: String
  public var networkUrl: String
  public var derivableNetwork: DerivableCoinNetwork
  
  init(
    token: Token,
    blockchainUid: String,
    address: String,
    networkUrl: String,
    derivableNetwork: DerivableCoinNetwork,
    syncer: SuiCoinSyncer,
    accountInfoManager: DerivableCoinAccountInfoManager,
    transactionManager: DerivableCoinTransactionManager,
    transactionSender: SuiTransactionSender,
    feeProvider: SuiFeeProvider,
    signer: SuiSigner
    
  ) {
    self.token = token
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
  }
  
  func updateNetwork(source: String) {
    self.networkUrl = source
    self.syncer.updateGridProviderNetwork(source: source)
  }
  
}

extension SuiKit {
  
  func isMainNet() -> Bool {
    self.derivableNetwork.isMainNet(source: self.networkUrl)
  }
  
  public var lastBlockHeight: Int? {
    syncer.lastBlockHeight
  }
  
  public var syncState: DerivableCoinSyncState {
    syncer.state
  }
  
  public var сoinSigner: SuiSigner {
    self.signer
  }
  
  public var receiveAddress: String {
    self.address
  }
  
  public var coinToken: Token {
    self.token
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
    accountInfoManager.balancePublisher
  }
  
  func transactionsPublisher(
    token: MarketKit.Token?,
    filter: TransactionTypeFilter
  ) -> AnyPublisher<[DerivableCoinTransaction], Never> {
      return transactionManager.transactionsPublisher(
        rpcSourceUrl: self.networkUrl,
        token: token,
        filter: filter
      )
  }
  
  func transactions(
    from: TransactionRecord?,
    token: MarketKit.Token?,
    filter: TransactionTypeFilter,
    limit: Int
  ) -> [DerivableCoinTransaction] {
    transactionManager.transactions(
      rpcSourceUrl: self.networkUrl,
      from: from,
      token: token,
      filter: filter,
      limit: limit
    )
  }
  
  public func estimateFee(to: String, sendAmount: BigUInt) async throws -> (fee: BigUInt, newSendSum: BigUInt) {
    let availableBalance = balance(contractAddress: self.address)
    let sendMax = availableBalance == sendAmount
    
    let ownedObjects = try await feeProvider.getOwnedObjects(address: self.address)
    
    let (initialFee, sendSum) = feeProvider.calcInitialFee(
      wannaSend: sendAmount,
      available: availableBalance
    )
    
    var objectsForTx: [String] = []
    if sendMax {
      objectsForTx = ownedObjects.map { o in
        o.data?.objectId
      } as! [String]
    } else {
      objectsForTx = feeProvider.getObjectsForAmount(
        desiredAmount: sendSum + initialFee,
        objects: ownedObjects
      )
    }
    
    let receivers = [to]
    let amounts = [sendSum]
    let pay = try await transactionSender.getPayTransaction(
      sendMax: sendMax,
      ids: objectsForTx,
      receivers: receivers,
      sender: self.address,
      feeBudged: initialFee,
      amounts: amounts
    )
    
    guard let payTx = pay else {
      throw SendError.abnormalSend
    }
    
    let dryRunTx = try await transactionSender.dryRunTransaction(tx: payTx)
    
    guard let feeResponse = dryRunTx else {
      throw SendError.dryRunIsNil
    }
    
    var realFee = feeProvider.calcRealFee(feeResponse: feeResponse)
    
    if realFee <= 0, !sendMax {
      //TODO нужна ошибка что мол неправильно рассчиталась транзакция, попробуй отправить позже
      throw SendError.dryRunNegativeFeeValue
    } else if realFee <= 0, sendMax {
      realFee = 2_000_000
    }
    
    return (BigUInt(realFee), sendSum)
  }
  
  public func send(to: String, fee: BigUInt, amount: BigUInt) async throws {
    let availableBalance = balance(contractAddress: self.address)
    let ownedObjects = try await feeProvider.getOwnedObjects(address: self.address)

    let sendMax = availableBalance == amount
    
    var objectsForTx: [String] = []
    if sendMax {
      objectsForTx = ownedObjects.map { o in
        o.data?.objectId
      } as! [String]
    } else {
      objectsForTx = feeProvider.getObjectsForAmount(
        desiredAmount: amount + fee,
        objects: ownedObjects
      )
    }
    
    let feeBudget = if fee > BigUInt.zero {
      fee
    } else {
      BigUInt(2_000_000)
    }
    
    let receivers = [to]
    let amounts = [amount]
    
    let pay = try await transactionSender.getPayTransaction(
      sendMax: sendMax,
      ids: objectsForTx,
      receivers: receivers,
      sender: self.address,
      feeBudged: feeBudget,
      amounts: amounts
    )
    
    guard let payTx = pay else {
      throw SendError.abnormalSend //TODO другая ошибка
    }
    
    try await executeTransaction(tx: payTx)
  }
  
  private func executeTransaction(tx: SuiWrappedTxBytes) async throws {
    let txBytes = Data(base64Encoded: tx.txBytes)
    let signature = transactionSender.sign(mnemonic: signer.getMnemonic, txBytes: Data([0, 0, 0]) + txBytes!)
    try await transactionSender.executeTransaction(
      txBytes: txBytes!,
      signedBytes: signature.signedData,
      pubkey: signature.pubKey
    )
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
  
  public static func instance(
    token: MarketKit.Token,
    signer: SuiSigner,
    blockchainUid: String,
    address: String,
    networkUrl: String,
    derivableNetwork: DerivableCoinNetwork,
    accountInfoStorage: DerivableCoinAccountInfoStorage,
    transactionStorage: DerivableCoinTransactionStorage,
    syncerStorage: DerivableCoinSyncerStorage,
    logger: Logger = Logger(minLogLevel: .error)
  ) throws -> SuiKit {
    
    let accountInfoManager = DerivableCoinAccountInfoManager(
      storage: accountInfoStorage,
      address: address,
      blockchainUid: blockchainUid
    )
    let transactionManager = DerivableCoinTransactionManager(
      userAddress: address,
      blockchainId: blockchainUid,
      storage: transactionStorage
    )
    
    let apiClient = SuiClient()
    apiClient.updateBaseUrl(newSourceUrl: networkUrl)
    
    let networkInteractor = SuiNetworkInteractor(
      networkUrl: networkUrl,
      blockchainUid: blockchainUid,
      signer: signer,
      apiClient: apiClient
    )
    let feeProvider = SuiFeeProvider(networkInteractor: networkInteractor)
    
    let syncer = SuiCoinSyncer(
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      networkInteractor: networkInteractor,
      syncerStorage: syncerStorage,
      address: address,
      blockchainUid: blockchainUid
    )
    let transactionSender = SuiTransactionSender(networkInteractor: networkInteractor)
    
    let kit = SuiKit(
      token: token,
      blockchainUid: blockchainUid,
      address: address,
      networkUrl: networkUrl,
      derivableNetwork: derivableNetwork,
      syncer: syncer,
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      transactionSender: transactionSender,
      feeProvider: feeProvider,
      signer: signer
    )
    
    return kit
  }
  
}

extension SuiKit {
  
  public enum SyncError: Error {
    case notStarted
    case noNetworkConnection
  }
  
  public enum SendError: Error {
    case notSupportedContract
    case abnormalSend
    case dryRunIsNil
    case dryRunNegativeFeeValue
    case invalidParameter
    case invalidCalcTransaction
  }
  
}
