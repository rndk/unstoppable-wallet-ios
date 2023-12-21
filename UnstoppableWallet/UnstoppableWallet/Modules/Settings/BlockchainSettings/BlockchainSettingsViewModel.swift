import Combine
import MarketKit
import RxRelay
import RxSwift

class BlockchainSettingsViewModel: ObservableObject {
  private let btcBlockchainManager: BtcBlockchainManager
  private let evmBlockchainManager: EvmBlockchainManager
  private let evmSyncSourceManager: EvmSyncSourceManager
  private let derivableSyncSourceManager: DerivableBlockchainManager
  private let disposeBag = DisposeBag()
  
  @Published var evmItems: [EvmItem] = []
  @Published var btcItems: [BtcItem] = []
  @Published var derivableItems: [DerivableItem] = []
  
  init(
    btcBlockchainManager: BtcBlockchainManager,
    evmBlockchainManager: EvmBlockchainManager,
    evmSyncSourceManager: EvmSyncSourceManager,
    derivableSyncSourceManager: DerivableBlockchainManager
  ) {
    self.btcBlockchainManager = btcBlockchainManager
    self.evmBlockchainManager = evmBlockchainManager
    self.evmSyncSourceManager = evmSyncSourceManager
    self.derivableSyncSourceManager = derivableSyncSourceManager
    
    subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncBtcItems() }
    subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncEvmItems() }
    
    syncBtcItems()
    syncEvmItems()
    syncDerivableItems()
  }
  
  private func syncBtcItems() {
    btcItems = btcBlockchainManager.allBlockchains
      .map { blockchain in
        let restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
        return BtcItem(blockchain: blockchain, restoreMode: restoreMode)
      }
      .sorted { $0.blockchain.type.order < $1.blockchain.type.order }
  }
  
  private func syncEvmItems() {
    evmItems = evmBlockchainManager.allBlockchains
      .map { blockchain in
        let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
        return EvmItem(blockchain: blockchain, syncSource: syncSource)
      }
      .sorted { $0.blockchain.type.order < $1.blockchain.type.order }
  }
  
  private func syncDerivableItems() {
    derivableItems = derivableSyncSourceManager.allBlockchains
      .map { blockchain in
        let syncSource = derivableSyncSourceManager.syncSource(blockchainType: blockchain.type)
        return DerivableItem(blockchain: blockchain, syncSource: syncSource)
      }
      .sorted { $0.blockchain.type.order < $1.blockchain.type.order }
  }
}

extension BlockchainSettingsViewModel {
  struct BtcItem {
    let blockchain: Blockchain
    let restoreMode: BtcRestoreMode
  }
  
  struct EvmItem {
    let blockchain: Blockchain
    let syncSource: EvmSyncSource
  }
  
  struct DerivableItem {
    let blockchain: Blockchain
    let syncSource: DerivableRpcSource
  }
}
