import Foundation
import MarketKit
import RxSwift
import RxRelay

class DerivableCoinKitManager {
  
  private let syncSourceManager: DerivableBlockchainManager
  private var currentAccount: Account?
  
  private let disposeBag = DisposeBag()
  private let queue = DispatchQueue(label: "\(AppConfig.label).derivable-coin-kit-manager", qos: .userInitiated)
  
  private var kitMap = [BlockchainType: DerivableCoinKitWrapper]()
  
  init(syncSourceManager: DerivableBlockchainManager) {
    self.syncSourceManager = syncSourceManager
    
    subscribe(disposeBag, syncSourceManager.syncSourceObservable) { [weak self] blockchainType in
        self?.handleUpdatedSyncSource(blockchainType: blockchainType)
    }
  }
  
  private func handleUpdatedSyncSource(blockchainType: BlockchainType) {
    queue.sync {
      guard let kitWrapper = kitMap[blockchainType] else {
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
    derivableNetwork: DerivableCoinNetwork,
    systemProframId: PublicKey,
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    sysvarRent: PublicKey,
    coinId: Int
  ) throws -> DerivableCoinKitWrapper {
    if let wrp = kitMap[blockchainType], let currentAccount = currentAccount, currentAccount == account {
      return wrp
    }
    if currentAccount != account {
      print(">>> clear kit map")
      for kit in kitMap.values {
        kit.coinKit.stop()
      }
      kitMap.removeAll()
    }
    
    guard let seed = account.type.mnemonicSeed else {
      throw AdapterError.unsupportedAccount
    }
    
    guard let words = account.type.getWords() else {
      throw AdapterError.unsupportedAccount
    }
    
    let keyPair = try DerivableKeyPair(
      path: DerivablePath(type: .bip44Change, coinId: coinId, walletIndex: 0, accountIndex: 0),
      seed: seed,
      words: words
    )
    
    let signer = DerivableCoinSigner(pair: keyPair)
    let address: String = signer.address()
    
    let networkUrl = self.syncSourceManager.syncSource(blockchainType: blockchainType).link
    
    let coinKit = try DerivableCoinKit.instance(
      token: token,
      signer: signer,
      blockchainUid: blockchainType.uid,
      address: address,
      networkUrl: networkUrl,
      walletId: account.id,
      derivableNetwork: derivableNetwork,
      accountInfoStorage: App.shared.derivableAccountStorage,
      transactionStorage: App.shared.derivableTransactionsStorage,
      syncerStorage: App.shared.derivableSyncerStorage,
      systemProframId: systemProframId,
      tokenProgramId: tokenProgramId,
      associatedProgramId: associatedProgramId,
      sysvarRent: sysvarRent
    )
    
    coinKit.start()
    
    let wrapper = DerivableCoinKitWrapper(blockchainType: blockchainType, coinKit: coinKit)
    
    currentAccount = account
    kitMap[blockchainType] = wrapper
    
    return wrapper
  }
  
}

class DerivableCoinKitWrapper {
  let blockchainType: BlockchainType
  let coinKit: DerivableCoinKit
  
  init(blockchainType: BlockchainType, coinKit: DerivableCoinKit) {
    self.blockchainType = blockchainType
    self.coinKit = coinKit
  }
  
  func send(preparedTransaction: DerivablePreparedTransaction) async throws {
    try await self.coinKit.send(transaction: preparedTransaction)
  }
  
  func refresh() {
    coinKit.refresh()
  }
  
}

extension DerivableCoinKitManager {
  
  func coinKit(blockchainType: BlockchainType) -> DerivableCoinKitWrapper? {
    queue.sync {
      kitMap[blockchainType]
    }
  }
  
  func coinKit(
    token: MarketKit.Token,
    account: Account,
    blockChainType: BlockchainType,
    derivableNetwork: DerivableCoinNetwork,
    systemProframId: PublicKey,
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    sysvarRent: PublicKey,
    coinId: Int
  ) throws -> DerivableCoinKitWrapper {
    try queue.sync {
      try _coinKitWrapper(
        token: token,
        account: account,
        blockchainType: blockChainType,
        derivableNetwork: derivableNetwork,
        systemProframId: systemProframId,
        tokenProgramId: tokenProgramId,
        associatedProgramId: associatedProgramId,
        sysvarRent: sysvarRent,
        coinId: coinId
      )
    }
  }
  
}
