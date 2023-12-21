import RxSwift
import RxRelay
import EvmKit
import MarketKit

class DerivableNetworkService {
  let blockchain: Blockchain
  private let syncSourceManager: DerivableBlockchainManager
  private var disposeBag = DisposeBag()
  
  private let stateRelay = PublishRelay<State>()
  private(set) var state: State = State(defaultItems: [], customItems: []) {
    didSet {
      stateRelay.accept(state)
    }
  }
  
  init(blockchain: Blockchain, derivableSyncSourceManager: DerivableBlockchainManager) {
    self.blockchain = blockchain
    self.syncSourceManager = derivableSyncSourceManager
    
    subscribe(disposeBag, derivableSyncSourceManager.syncSourcesUpdatedObservable) { [weak self] _ in self?.syncState() }
    
    syncState()
  }
  
  private var currentSyncSource: DerivableRpcSource {
    syncSourceManager.syncSource(blockchainType: blockchain.type)
  }
  
  private func syncState() {
    state = State(
      defaultItems: items(syncSources: syncSourceManager.defaultSyncSources(blockchainType: blockchain.type)),
      customItems: items(syncSources: syncSourceManager.customSyncSources(blockchainType: blockchain.type))
    )
  }
  
  private func items(syncSources: [DerivableRpcSource]) -> [Item] {
    let currentSyncSource = currentSyncSource
    
    return syncSources.map { syncSource in
      Item(
        syncSource: syncSource,
        selected: syncSource == currentSyncSource
      )
    }
  }
  
  func setCurrent(syncSource: DerivableRpcSource) {
    guard currentSyncSource != syncSource else {
      return
    }
    
    syncSourceManager.saveCurrent(syncSource: syncSource, blockchainType: blockchain.type)
    
    syncState()
  }
  
}

extension DerivableNetworkService {
  
  var stateObservable: Observable<State> {
    stateRelay.asObservable()
  }
  
  func setDefault(index: Int) {
    setCurrent(syncSource: state.defaultItems[index].syncSource)
  }
  
  func setCustom(index: Int) {
    setCurrent(syncSource: state.customItems[index].syncSource)
  }
  
  func removeCustom(index: Int) {
    syncSourceManager.delete(syncSource: state.customItems[index].syncSource, blockchainType: blockchain.type)
  }
  
}

extension DerivableNetworkService {
  
  struct State {
    let defaultItems: [Item]
    let customItems: [Item]
  }
  
  struct Item {
    let syncSource: DerivableRpcSource
    let selected: Bool
  }
  
}
