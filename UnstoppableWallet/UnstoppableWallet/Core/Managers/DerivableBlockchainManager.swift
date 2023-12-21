import Foundation
import MarketKit
import RxRelay
import RxSwift

class DerivableBlockchainManager {
  
  private let blockchainTypes: [BlockchainType] = [
    .safeCoin,
  ]
  
  private let marketKit: MarketKit.Kit
  private let storage: BlockchainSettingsStorage
  private let derivableSourcesStorage: DerivableSyncSourceStorage
  
  private let syncSourceRelay = PublishRelay<BlockchainType>()
  private let syncSourcesUpdatedRelay = PublishRelay<BlockchainType>()
  
  let allBlockchains: [Blockchain]
  
  init(
    marketKit: MarketKit.Kit,
    storage: BlockchainSettingsStorage,
    derivableSourcesStorage: DerivableSyncSourceStorage
  ) {
    self.marketKit = marketKit
    self.storage = storage
    self.derivableSourcesStorage = derivableSourcesStorage
    
    do {
      allBlockchains = try marketKit.blockchains(uids: blockchainTypes.map { $0.uid })
    } catch {
      allBlockchains = []
    }
  }
  
}

extension DerivableBlockchainManager {
  
  var syncSourceObservable: Observable<BlockchainType> {
      syncSourceRelay.asObservable()
  }

  var syncSourcesUpdatedObservable: Observable<BlockchainType> {
      syncSourcesUpdatedRelay.asObservable()
  }
  
//  func blockchain(token: Token) -> Blockchain? {
//    allBlockchains.first(where: { token.blockchain == $0 })
//  }
  
  func defaultSyncSources(blockchainType: BlockchainType) -> [DerivableRpcSource] {
    switch blockchainType {
    case .safeCoin: return [
      DerivableRpcSource(
        blockchainUid: blockchainType.uid,
        name: "MainNet Beta",
        link: "https://api.mainnet-beta.safecoin.org/",
        createdAt: 0
      ),
      DerivableRpcSource(
        blockchainUid: blockchainType.uid,
        name: "TestNet",
        link: "https://api.testnet.safecoin.org/",
        createdAt: 0
      ),
      DerivableRpcSource(
        blockchainUid: blockchainType.uid,
        name: "DevNet",
        link: "https://devnet.safely.org/",
        createdAt: 0
      )
    ]
    default: return []
    }
  }
  
  func customSyncSources(blockchainType: BlockchainType?) -> [DerivableRpcSource] {
    guard let blc = blockchainType else {
      return []
    }
    return derivableSourcesStorage.get(blockchainUid: blc.uid)
  }
  
  func allSyncSources(blockchainType: BlockchainType) -> [DerivableRpcSource] {
    defaultSyncSources(blockchainType: blockchainType) + customSyncSources(blockchainType: blockchainType)
  }
  
  func syncSource(blockchainType: BlockchainType) -> DerivableRpcSource {
    let syncSources = allSyncSources(blockchainType: blockchainType)
    
    if let urlString = storage.derivableSyncSourceUrl(blockchainType: blockchainType),
       let syncSource = syncSources.first(where: { $0.link == urlString })
    {
      return syncSource
    }
    
    return syncSources[0]
  }
  
  func saveCurrent(syncSource: DerivableRpcSource, blockchainType: BlockchainType) {
    storage.save(derivableSyncSourceUrl: syncSource.link, blockchainType: blockchainType)
    syncSourceRelay.accept(blockchainType)
  }
  
  func saveSyncSource(blockchainType: BlockchainType, url: String, name: String?) {
    let record = DerivableRpcSource(
      blockchainUid: blockchainType.uid,
      name: name ?? "",
      link: url,
      createdAt: UInt64(Date().timeIntervalSince1970 * 1000)
    )
    
    try? derivableSourcesStorage.save(record: record)
    
    if let syncSource = customSyncSources(blockchainType: blockchainType).first(where: { $0.link == url }) {
      saveCurrent(syncSource: syncSource, blockchainType: blockchainType)
    }
    
    syncSourcesUpdatedRelay.accept(blockchainType)
  }
  
  func delete(syncSource: DerivableRpcSource, blockchainType: BlockchainType) {
    let isCurrent = self.syncSource(blockchainType: blockchainType) == syncSource
    
    try? derivableSourcesStorage.delete(
      blockchainUid: blockchainType.uid, link: syncSource.link
    )
    
    if isCurrent {
      syncSourceRelay.accept(blockchainType)
    }
    
    syncSourcesUpdatedRelay.accept(blockchainType)
  }
  
}
