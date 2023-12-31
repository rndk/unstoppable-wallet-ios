import Foundation
import BigInt
import MarketKit
import RxSwift
import RxRelay

class SuiKitManager {
  
  private let syncSourceManager: DerivableBlockchainManager
  private var currentAccount: Account?
  
  private let disposeBag = DisposeBag()
  private let queue = DispatchQueue(label: "\(AppConfig.label).sui-kit-manager", qos: .userInitiated)
  
  private var wrapper: SuiKitWrapper?
  
  init(syncSourceManager: DerivableBlockchainManager) {
    self.syncSourceManager = syncSourceManager
    
    subscribe(disposeBag, syncSourceManager.syncSourceObservable) { [weak self] blockchainType in
        self?.handleUpdatedSyncSource(blockchainType: blockchainType)
    }
  }
  
  private func handleUpdatedSyncSource(blockchainType: BlockchainType) {
    queue.sync {
      guard let kitWrapper = wrapper else {
        return
      }
      
      guard kitWrapper.blockchainType == blockchainType else {
        return
      }
      
      kitWrapper.coinKit.updateNetwork(
        source: syncSourceManager.syncSource(blockchainType: blockchainType).link
      )
      kitWrapper.coinKit.refresh()
    }
  }
  
  private func _coinKitWrapper(
    token: MarketKit.Token,
    account: Account,
    blockchainType: BlockchainType,
    derivableNetwork: DerivableCoinNetwork
  ) throws -> SuiKitWrapper {
    if let wrp = wrapper, let currentAccount = currentAccount, currentAccount == account {
      return wrp
    }
    if currentAccount != account {
      wrapper = nil
    }
    
    guard let words = account.type.getWords() else {
      throw AdapterError.unsupportedAccount
    }
    
    let signer = SuiSigner(mnemonic: words.joined(separator: " "))
    let address: String = signer.coinAddress
    
    let networkUrl = self.syncSourceManager.syncSource(blockchainType: blockchainType).link
    
    let coinKit = try SuiKit.instance(
      token: token,
      signer: signer,
      blockchainUid: blockchainType.uid,
      address: address,
      networkUrl: networkUrl,
      derivableNetwork: derivableNetwork,
      accountInfoStorage: App.shared.derivableAccountStorage,
      transactionStorage: App.shared.derivableTransactionsStorage,
      syncerStorage: App.shared.derivableSyncerStorage
    )
    
    coinKit.start()
    
    let wrapper = SuiKitWrapper(blockchainType: blockchainType, coinKit: coinKit)
    
    currentAccount = account
    self.wrapper = wrapper
    
    return wrapper
  }
  
}

class SuiKitWrapper {
  
  let blockchainType: BlockchainType
  let coinKit: SuiKit
  
  init(blockchainType: BlockchainType, coinKit: SuiKit) {
    self.blockchainType = blockchainType
    self.coinKit = coinKit
  }
  
  func send(to: String, fee: BigUInt, amount: BigUInt) async throws {
    try await self.coinKit.send(to: to, fee: fee, amount: amount)
  }
  
  func refresh() {
    coinKit.refresh()
  }
  
}

extension SuiKitManager {
  
  func coinKit(blockchainType: BlockchainType) -> SuiKitWrapper? {
    queue.sync {
      wrapper
    }
  }
  
  func coinKit(
    token: MarketKit.Token,
    account: Account,
    blockChainType: BlockchainType,
    derivableNetwork: DerivableCoinNetwork
  ) throws -> SuiKitWrapper {
    try queue.sync {
      try _coinKitWrapper(
        token: token,
        account: account,
        blockchainType: blockChainType,
        derivableNetwork: derivableNetwork
      )
    }
  }
  
}
