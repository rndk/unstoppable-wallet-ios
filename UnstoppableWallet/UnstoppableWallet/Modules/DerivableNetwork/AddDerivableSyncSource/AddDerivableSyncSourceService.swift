import Foundation
import RxSwift
import RxRelay
import EvmKit
import MarketKit

class AddDerivableSyncSourceService {
  private let blockchainType: BlockchainType
  private let syncSourceManager: DerivableBlockchainManager
  private var disposeBag = DisposeBag()
  
  private var urlString: String = ""
  private var sourceName: String = ""
  
  init(blockchainType: BlockchainType, syncSourceManager: DerivableBlockchainManager) {
    self.blockchainType = blockchainType
    self.syncSourceManager = syncSourceManager
  }
}

extension AddDerivableSyncSourceService {
  func set(urlString: String) {
    self.urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  func set(sourceName: String) {
    self.sourceName = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  func save() throws {
    guard let url = URL(string: urlString), let scheme = url.scheme else {
      throw UrlError.invalid
    }
    
    guard ["https", "wss"].contains(scheme) else {
      throw UrlError.invalid
    }
    
    let existingSources = syncSourceManager.allSyncSources(blockchainType: blockchainType)
    
    guard !existingSources.contains(where: { $0.link == url.absoluteString }) else {
      throw UrlError.alreadyExists
    }
    
    syncSourceManager.saveSyncSource(
      blockchainType: blockchainType,
      url: urlString,
      name: sourceName
    )
  }
}

extension AddDerivableSyncSourceService {
  enum UrlError: Error {
    case invalid
    case alreadyExists
  }
}
