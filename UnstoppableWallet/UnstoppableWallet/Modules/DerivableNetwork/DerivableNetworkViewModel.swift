import Foundation
import RxSwift
import RxRelay
import RxCocoa
import EvmKit
import MarketKit

class DerivableNetworkViewModel {
  private let service: DerivableNetworkService
  private let disposeBag = DisposeBag()
  
  private let stateRelay = BehaviorRelay<State>(value: State(defaultViewItems: [], customViewItems: []))
  private let finishRelay = PublishRelay<()>()
  
  init(service: DerivableNetworkService) {
    self.service = service
    
    subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    
    sync(state: service.state)
  }
  
  private func sync(state: DerivableNetworkService.State) {
    let state = State(
      defaultViewItems: state.defaultItems.map { viewItem(item: $0) },
      customViewItems: state.customItems.map { viewItem(item: $0) }
    )
    
    stateRelay.accept(state)
  }
  
  private func viewItem(item: DerivableNetworkService.Item) -> ViewItem {
    //url: url(rpcSource: item.syncSource.rpcSource)?.absoluteString,
    ViewItem(
      name: item.syncSource.name,
      url: item.syncSource.link,
      selected: item.selected
    )
  }
  
  private func url(rpcSource: RpcSource) -> URL? {
    switch rpcSource {
    case .http(let urls, _): return urls.first
    case .webSocket(let url, _): return url
    }
  }
  
}

extension DerivableNetworkViewModel {
  
  var stateDriver: Driver<State> {
    stateRelay.asDriver()
  }
  
  var finishSignal: Signal<()> {
    finishRelay.asSignal()
  }
  
  var title: String {
    service.blockchain.name
  }
  
  var iconUrl: String {
    service.blockchain.type.imageUrl
  }
  
  var blockchainType: BlockchainType {
    service.blockchain.type
  }
  
  func onSelectDefault(index: Int) {
    service.setDefault(index: index)
  }
  
  func onSelectCustom(index: Int) {
    service.setCustom(index: index)
  }
  
  func onRemoveCustom(index: Int) {
    service.removeCustom(index: index)
  }
  
}

extension DerivableNetworkViewModel {
  
  struct State {
    let defaultViewItems: [ViewItem]
    let customViewItems: [ViewItem]
  }
  
  struct ViewItem {
    let name: String
    let url: String?
    let selected: Bool
  }
  
}
