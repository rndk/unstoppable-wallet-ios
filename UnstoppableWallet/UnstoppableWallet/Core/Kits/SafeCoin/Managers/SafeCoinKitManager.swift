import Foundation
import MarketKit
import RxSwift
import RxRelay

class SafeCoinKitManager {
  private let disposeBag = DisposeBag()
  private var currentAccount: Account?
  private weak var _safeCoinKitWrapper: SafeCoinKitWrapper?
  private let queue = DispatchQueue(label: "\(AppConfig.label).safe-coin-kit-manager", qos: .userInitiated)
  
  private func _safeCoinKitWrapper(account: Account, blockchainType: BlockchainType) throws -> SafeCoinKitWrapper {
    if let _safeCoinKitWrapper = _safeCoinKitWrapper, let currentAccount = currentAccount, currentAccount == account {
      return _safeCoinKitWrapper
    }
    
    guard let seed = account.type.mnemonicSeed else {
      throw AdapterError.unsupportedAccount
    }
    
    let words = account.type.getWords()
    let der = try DerivableKeyPair(seed: seed, words: words!)//TODO!!!!!!!!!!!!!!!!!!!!!
    
    let signer = SafeCoinSigner(pair: der)
    let address: String = signer.address()
    
    let network: SafeCoinNetwork = .testNet //TODO network?
    print(">>> addre: \(address), words:\(String(describing: words))")
    
    let safeCoinKit = try SafeCoinKit.instance(
      signer: signer,
      address: address,
      network: network,
      walletId: account.id
    )
    
    safeCoinKit.start() //TODO or refresh?
    
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
  
//    func send(contract: Contract, feeLimit: Int?) async throws {
//        guard let signer = signer else {
//            throw SignerError.signerNotSupported
//        }
//  
//        return try await tronKit.send(contract: contract, signer: signer, feeLimit: feeLimit)
//    }
  
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
