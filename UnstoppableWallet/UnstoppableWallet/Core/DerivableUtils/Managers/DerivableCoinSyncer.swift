import Foundation
import HsExtensions

class DerivableCoinSyncer {
  
  private var tasks = Set<AnyTask>()
  
  private let accountInfoManager: DerivableCoinAccountInfoManager
  private let transactionManager: DerivableCoinTransactionManager
  private let networkInteractor: DerivableCoinNetworkInteractor
  private let storage: DerivableCoinSyncerStorage
  private var blockchainUid: String
  private var address: String = ""
  
  private var syncing: Bool = false
  
  @DistinctPublished private(set) var state: DerivableCoinSyncState = .notSynced(error: DerivableCoinSyncState.SyncError.notStarted)
  @DistinctPublished private(set) var lastBlockHeight: Int = 0
  
  init(
    accountInfoManager: DerivableCoinAccountInfoManager,
    transactionManager: DerivableCoinTransactionManager,
    networkInteractor: DerivableCoinNetworkInteractor,
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

extension DerivableCoinSyncer {
  
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
    Task { [weak self, networkInteractor, address, transactionManager, accountInfoManager, storage, blockchainUid] in
      do {
        guard let syncer = self, !syncer.state.syncing else {
          return
        }
        self?.set(state: .syncing(progress: nil))
        
        let balance = try await networkInteractor.getBalance(address: address)
        accountInfoManager.handle(newBalance: balance)
        
        let newLastBlockHeight = try await networkInteractor.getLastBlockHeight()
        if self?.lastBlockHeight != Int(newLastBlockHeight) {
          storage.save(address: address, coinUid: blockchainUid, blockHeight: newLastBlockHeight)
          self?.lastBlockHeight = Int(newLastBlockHeight)
        }
        
        let lastTransactionHash = transactionManager.getLastTransaction(rpcSourceUrl: networkInteractor.source)?.hash

        let safeTransfers = try await networkInteractor.safeTransfers(
          address: address,
          lastTransaction: lastTransactionHash
        )
        let splTransfers = try await networkInteractor.splTransfers(
          address: address,
          lastTransaction: lastTransactionHash
        )
        
        let safeRpcExportedTxs = (safeTransfers + splTransfers).sorted(by: {$0.blockTime < $1.blockTime })
        
        transactionManager.save(transactions: safeRpcExportedTxs, replaceOnConflict: true)
        
        self?.set(state: .synced)
      } catch {
        self?.set(state: .notSynced(error: error))
      }
    }.store(in: &tasks)
  }
  
  private func getSignaturesFromRpcNode(
    lastTransactionHash: String?
  ) async throws -> [DerivableSignatureInfo] {
    var signatureObjects = [] as [DerivableSignatureInfo]
    var signatureObjectsChunk = [] as [DerivableSignatureInfo]
    
    repeat {
      let lastSignature = signatureObjectsChunk.last?.signature
      signatureObjectsChunk = try await getSignaturesChunk(
        lastTransactionHash: lastTransactionHash, before: lastSignature
      )
      signatureObjects.append(contentsOf: signatureObjectsChunk)
    } while(signatureObjectsChunk.count == 1000)
    
    return signatureObjects
  }
  
  private func getSignaturesChunk(
    lastTransactionHash: String?,
    before: String? = nil
  ) async throws -> [DerivableSignatureInfo] {
    return try await networkInteractor.getSignaturesForAddress(address: address)
  }
  
  private func getTokenAccounts() async throws -> [String] {
    return try await networkInteractor.getTokenAccountsByOwner(address: address)
  }
}
