import Foundation
import HsExtensions

//TODO тут надо запрашивать баланс и транзакции
class SafeCoinSyncer {
  
  private var tasks = Set<AnyTask>()
  
  private let accountInfoManager: SafeCoinAccountInfoManager
  private let transactionManager: SafeCoinTransactionManager
  private let safeCoinGridProvider: SafeCoinGridProvider
  private var address: String = ""
  
  private var syncing: Bool = false
  
  @DistinctPublished private(set) var state: SafeCoinSyncState =
    .notSynced(error: SafeCoinSyncState.SyncError.notStarted)
  
  init(
    accountInfoManager: SafeCoinAccountInfoManager,
    transactionManager: SafeCoinTransactionManager,
    safeCoinGridProvider: SafeCoinGridProvider,
    address: String
  ) {
    self.accountInfoManager = accountInfoManager
    self.transactionManager = transactionManager
    self.safeCoinGridProvider = safeCoinGridProvider
    self.address = address
  }
  
  private func set(state: SafeCoinSyncState) {
    self.state = state
    
    if case .syncing = state {} else {
      syncing = false
    }
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
    Task { [weak self, safeCoinGridProvider, address, transactionManager, accountInfoManager] in
      do {
        guard let syncer = self, !syncer.syncing else {
          return
        }
        syncer.syncing = true
        
        print(">>> SafeCoinSyncer try get balance >>>")
        let balance = try await safeCoinGridProvider.getBalance(address: address)
        accountInfoManager.handle(newBalance: balance)
        print(">>> saef coien blance: \(balance)")
        
        let lastTransactionHash = transactionManager.getLastTransaction()?.hash
        
//        let rpcSignatureInfos = try await self?.getSignaturesFromRpcNode(
//          lastTransactionHash: lastTransactionHash
//        )
//        print(">>> rpcSignaturesInfo: \(rpcSignaturesInfo?.count)")
        let safeTransfers = try await safeCoinGridProvider.safeTransfers(address: address)
        let splTransfers = try await safeCoinGridProvider.splTransfers(address: address)
        let safeRpcExportedTxs = (safeTransfers + splTransfers).sorted(by: {$0.blockTime < $1.blockTime })
        
//        let tokenAccounts = try await self?.getTokenAccounts()
//        let mintAccounts = self?.getMintAccounts(tokenAccounts.map { $0.mintAddress })
        print(">>> SafeCoinSyncer transactions: \(safeRpcExportedTxs)")
        
//        let transactions =
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
