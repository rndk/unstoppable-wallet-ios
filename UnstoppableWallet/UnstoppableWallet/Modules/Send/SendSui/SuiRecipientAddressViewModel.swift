import Foundation
import RxSwift

class SuiRecipientAddressViewModel: RecipientAddressViewModel {
  
  private let disposeBag = DisposeBag()
  private let sendService: SendSuiService
  
  init(
    service: AddressService,
    handlerDelegate: IRecipientAddressService?,
    sendService: SendSuiService
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
