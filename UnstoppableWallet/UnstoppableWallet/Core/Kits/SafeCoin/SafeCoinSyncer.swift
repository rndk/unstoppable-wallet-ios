import Foundation
import HsExtensions

class SafeCoinSyncer {
  
  private var tasks = Set<AnyTask>()
  
  private let accountInfoManager: SafeCoinAccountInfoManager
  private let transactionManager: SafeCoinTransactionManager
  private let safeCoinGridProvider: SafeCoinGridProvider
  private let storage: DerivableCoinSyncerStorage
  private var address: String = ""
  
  private var syncing: Bool = false
  
  @DistinctPublished private(set) var state: SafeCoinSyncState = .notSynced(error: SafeCoinSyncState.SyncError.notStarted)
  @DistinctPublished private(set) var lastBlockHeight: Int = 0
  
  init(
    accountInfoManager: SafeCoinAccountInfoManager,
    transactionManager: SafeCoinTransactionManager,
    safeCoinGridProvider: SafeCoinGridProvider,
    syncerStorage: DerivableCoinSyncerStorage,
    address: String
  ) {
    self.accountInfoManager = accountInfoManager
    self.transactionManager = transactionManager
    self.safeCoinGridProvider = safeCoinGridProvider
    self.storage = syncerStorage
    self.address = address
    
    lastBlockHeight = Int(storage.lastBlockHeight(address: address, coinUid: "safe-coin-2"))
  }
  
  private func set(state: SafeCoinSyncState) {
    self.state = state
    
    if case .syncing = state {} else {
      syncing = false
    }
  }
  
  func updateGridProviderNetwork(source: String) {
    self.safeCoinGridProvider.updateBaseUrl(newSourceUrl: source)
  }
  
}

extension SafeCoinSyncer {
  
  var source: String {
    "RPC \(safeCoinGridProvider.source)"
  }
  
  func start() {
    sync()
  }
  
  func stop() {
    //TODO tasks cancel?
    tasks.forEach({t in t.cancel()})
    tasks.removeAll()
  }
  
  func refresh() {
    //        switch syncTimer.state {
    //        case .ready:
    //            sync()
    //        case .notReady:
    //            syncTimer.start()
    //        }
    if !state.syncing {
      sync()
    }
  }
  
  func sync() {
    print(">>> SafeCoinSyncer sync() start...")
    Task { [weak self, safeCoinGridProvider, address, transactionManager, accountInfoManager, storage] in
      do {
        guard let syncer = self, !syncer.syncing else {
          return
        }
        syncer.syncing = true
        
        print(">>> SafeCoinSyncer try get balance >>>")
        let balance = try await safeCoinGridProvider.getBalance(address: address)
        accountInfoManager.handle(newBalance: balance)
        print(">>> saef coien blance: \(balance)")
        
        //todo blockHeight
        let newLastBlockHeight = try await safeCoinGridProvider.getLastBlockHeight()
        if self?.lastBlockHeight != Int(newLastBlockHeight) {
          storage.save(address: address, coinUid: "safe_coin_2", blockHeight: newLastBlockHeight)
          self?.lastBlockHeight = Int(newLastBlockHeight)
          print(">>> newLastBlockHeight: \(newLastBlockHeight)")
        }
        
        let lastTransactionHash = transactionManager.getLastTransaction()?.hash
        print(">>> las transaction hash: \(lastTransactionHash)")
        
        //let rpcSignatureInfos = try await self?.getSignaturesFromRpcNode(
        //  lastTransactionHash: lastTransactionHash
        //)
        //print(">>> rpcSignaturesInfo: \(rpcSignaturesInfo?.count)")
        let safeTransfers = try await safeCoinGridProvider.safeTransfers(address: address)
        let splTransfers = try await safeCoinGridProvider.splTransfers(address: address)
        let safeRpcExportedTxs = (safeTransfers + splTransfers).sorted(by: {$0.blockTime < $1.blockTime })
        
        //let tokenAccounts = try await self?.getTokenAccounts()
        //let mintAccounts = self?.getMintAccounts(tokenAccounts.map { $0.mintAddress })
        print(">>> SafeCoinSyncer transactions: \(safeRpcExportedTxs)")
        
        //let transactions =
        //TODO короч тут минт эти штуки надо сделать как в андроиде
        transactionManager.save(transactions: safeRpcExportedTxs, replaceOnConflict: true)
        
        self?.set(state: .synced)
        print(">>> SafeCoinSyncer sync() complete...")
      } catch {
        print(">>> SafeCoinSyncer error while syncing \(error)")
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
    return try await safeCoinGridProvider.getSignaturesForAddress(address: address)
  }
  
  private func getTokenAccounts() async throws -> [String] {
    return try await safeCoinGridProvider.getTokenAccountsByOwner(address: address)
  }
}
