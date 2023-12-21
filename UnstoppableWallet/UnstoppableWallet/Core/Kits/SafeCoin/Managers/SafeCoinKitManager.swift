import Foundation
import MarketKit
import RxSwift
import RxRelay

class SafeCoinKitManager {
  private let syncSourceManager: DerivableBlockchainManager
  private let disposeBag = DisposeBag()
  private var currentAccount: Account?
  private weak var _safeCoinKitWrapper: SafeCoinKitWrapper?
  private let queue = DispatchQueue(label: "\(AppConfig.label).safe-coin-kit-manager", qos: .userInitiated)
  private let safeCoinKitUpdatedRelay = PublishRelay<Void>()
  
  init(syncSourceManager: DerivableBlockchainManager) {
    self.syncSourceManager = syncSourceManager
    
    subscribe(disposeBag, syncSourceManager.syncSourceObservable) { [weak self] blockchainType in
        self?.handleUpdatedSyncSource(blockchainType: blockchainType)
    }
  }
  
  private func handleUpdatedSyncSource(blockchainType: BlockchainType) {
    queue.sync {
      guard let _safeCoinKitWrapper = _safeCoinKitWrapper else {
        return
      }
      
      guard _safeCoinKitWrapper.blockchainType == blockchainType else {
        return
      }
      
      self._safeCoinKitWrapper?.safeCoinKit.updateNetwork(
        source: syncSourceManager.syncSource(blockchainType: blockchainType).link
      )
      self._safeCoinKitWrapper?.safeCoinKit.refresh()
    }
  }
  
  private func _safeCoinKitWrapper(
    account: Account,
    blockchainType: BlockchainType
  ) throws -> SafeCoinKitWrapper {
    if let _safeCoinKitWrapper = _safeCoinKitWrapper, let currentAccount = currentAccount, currentAccount == account {
      return _safeCoinKitWrapper
    }
    
    guard let seed = account.type.mnemonicSeed else {
      throw AdapterError.unsupportedAccount
    }
    
    let words = account.type.getWords()
    let der = try DerivableKeyPair(seed: seed, words: words!)
    
    let signer = SafeCoinSigner(pair: der)
    let address: String = signer.address()
    
    let networkUrl = self.syncSourceManager.syncSource(blockchainType: .safeCoin).link
    
    let safeCoinKit = try SafeCoinKit.instance(
      signer: signer,
      address: address,
      networkUrl: networkUrl,
      walletId: account.id
    )
    
    safeCoinKit.start()
    
    let wrapper = SafeCoinKitWrapper(blockchainType: blockchainType, safeCoinKit: safeCoinKit)
    
    _safeCoinKitWrapper = wrapper
    currentAccount = account
    
    return wrapper
  }
  
}

class SafeCoinKitWrapper {
  let blockchainType: BlockchainType
  let safeCoinKit: SafeCoinKit
  
  init(blockchainType: BlockchainType, safeCoinKit: SafeCoinKit) {
    self.blockchainType = blockchainType
    self.safeCoinKit = safeCoinKit
  }
  
  func send(preparedTransaction: DerivablePreparedTransaction) async throws {
    try await self.safeCoinKit.send(transaction: preparedTransaction)
  }
  
  func refresh() {
    safeCoinKit.refresh()
  }
  
}

extension SafeCoinKitManager {
  
  var safeCoinKit: SafeCoinKitWrapper? {
    queue.sync {
      _safeCoinKitWrapper
    }
  }
  
  func safeCoinKit(account: Account, blockChainType: BlockchainType) throws -> SafeCoinKitWrapper {
    try queue.sync {
      try _safeCoinKitWrapper(account: account, blockchainType: blockChainType)
    }
  }
  
}
