import Foundation
import HsExtensions

class SuiCoinSyncer {
  
  private var tasks = Set<AnyTask>()
  
  private let accountInfoManager: DerivableCoinAccountInfoManager
  private let transactionManager: DerivableCoinTransactionManager
  private let networkInteractor: SuiNetworkInteractor
  private let storage: DerivableCoinSyncerStorage
  private var blockchainUid: String
  private var address: String = ""
  
  private var syncing: Bool = false
  
  @DistinctPublished private(set) var state: DerivableCoinSyncState = .notSynced(error: DerivableCoinSyncState.SyncError.notStarted)
  @DistinctPublished private(set) var lastBlockHeight: Int = 0
  
  init(
    accountInfoManager: DerivableCoinAccountInfoManager,
    transactionManager: DerivableCoinTransactionManager,
    networkInteractor: SuiNetworkInteractor,
    syncerStorage: DerivableCoinSyncerStorage,
    address: String,
    blockchainUid: String
  ) {
    self.accountInfoManager = accountInfoManager
    self.transactionManager = transactionManager
    self.networkInteractor = networkInteractor
    self.storage = syncerStorage
    self.address = address
    self.blockchainUid = blockchainUid
    
    lastBlockHeight = Int(storage.lastBlockHeight(address: address, coinUid: self.blockchainUid))
  }
  
  private func set(state: DerivableCoinSyncState) {
    self.state = state
    
    if case .syncing = state {} else {
      syncing = false
    }
  }
  
  func updateGridProviderNetwork(source: String) {
    self.networkInteractor.updateBaseUrl(newSourceUrl: source)
  }
  
}

extension SuiCoinSyncer {
  
  func start() {
    sync()
  }
  
  func stop() {
    tasks.forEach({t in t.cancel()})
    tasks.removeAll()
  }
  
  func refresh() {
    if !state.syncing {
      sync()
    }
  }
  
  func sync() {
    Task { [weak self, networkInteractor, address, transactionManager, accountInfoManager] in
      do {
        guard let syncer = self, !syncer.state.syncing else {
          return
        }
        self?.set(state: .syncing(progress: nil))
        
        let balance = try await networkInteractor.getBalance(address: address)
        
        accountInfoManager.handle(newBalance: balance)

        let lastIncHash = transactionManager.getLastIncomingTransaction(
          rpcSourceUrl: networkInteractor.source
        )?.hash
        let lastOutHash = transactionManager.getLastOutgoingTransaction(
          rpcSourceUrl: networkInteractor.source
        )?.hash
        
        let incomingTxs = try await networkInteractor.getIncomingTransactions(
          address: address, lastHash: lastIncHash
        )
        
        let outgoingTxs = try await networkInteractor.getOutgoingTransactions(
          address: address, lastHash: lastOutHash
        )
        
        let merged = (incomingTxs + outgoingTxs).sorted(by: {$0.blockTime < $1.blockTime })

        transactionManager.save(transactions: merged, replaceOnConflict: true)
        
        self?.set(state: .synced)
      } catch {
        self?.set(state: .notSynced(error: error))
      }
    }.store(in: &tasks)
  }
  
}
