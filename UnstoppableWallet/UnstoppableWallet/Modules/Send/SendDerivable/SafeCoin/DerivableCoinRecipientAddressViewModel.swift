import Foundation
import RxSwift

class DerivableCoinRecipientAddressViewModel: RecipientAddressViewModel {
  private let disposeBag = DisposeBag()
  private let sendService: SendDerivableCoinService
  
  init(
    service: AddressService,
    handlerDelegate: IRecipientAddressService?,
    sendService: SendDerivableCoinService
  ) {
    self.sendService = sendService
    super.init(service: service, handlerDelegate: handlerDelegate)
    
    subscribe(disposeBag, sendService.activeAddressObservable) { [weak self] in self?.handle(active: $0) }
  }
  
  private func handle(active: Bool) {
    if active {
      cautionRelay.accept(nil)
    } else {
      cautionRelay.accept(Caution(text: "tron.send.inactive_address".localized, type: .warning)) //TODO string res
    }
  }
  
  override func sync(state: AddressService.State? = nil, customError: Error? = nil) {
    super.sync(state: state, customError: customError)
    
    if case let .success(address) = state {
      sendService.sync(address: address.raw)
    }
  }
}
