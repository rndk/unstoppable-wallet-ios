import Foundation
import RxCocoa
import RxRelay
import RxSwift
import MarketKit

class SendSuiViewModel {
  
  private let service: SendSuiService
  private let disposeBag = DisposeBag()
  
  private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
  private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)
  private let addressCautionRelay = BehaviorRelay<Caution?>(value: nil)
  private let proceedRelay = PublishRelay<SendSuiService.SendData>()
  
  init(service: SendSuiService) {
    self.service = service
    
    subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    subscribe(disposeBag, service.amountCautionObservable) { [weak self] in self?.sync(amountCaution: $0) }
    subscribe(disposeBag, service.addressErrorObservable) { [weak self] in self?.sync(addressError: $0) }
    
    sync(state: service.state)
  }
  
  private func sync(state: SendSuiService.State) {
    if case .ready = state {
      proceedEnabledRelay.accept(true)
    } else {
      proceedEnabledRelay.accept(false)
    }
  }
  
  private func sync(amountCaution: (error: Error?, warning: SendSuiService.AmountWarning?)) {
    var caution: Caution? = nil
    
    if let error = amountCaution.error {
      caution = Caution(text: error.smartDescription, type: .error)
    } else if let warning = amountCaution.warning {
      switch warning {
      case .coinNeededForFee: caution = Caution(text: "send.amount_warning.coin_needed_for_fee".localized(service.sendToken.coin.code), type: .warning)
      }
    }
    
    amountCautionRelay.accept(caution)
  }
  
  private func sync(addressError: Error?) {
    var caution: Caution? = nil
    
    if let error = addressError {
      caution = Caution(text: error.smartDescription, type: .error)
    }
    
    addressCautionRelay.accept(caution)
  }
  
}

extension SendSuiViewModel {
  
  var title: String {
    switch service.mode {
    case .send: return "send.title".localized(token.coin.code)
    case .predefined: return "donate.title".localized(token.coin.code)
    }
  }
  
  var showAddress: Bool {
    switch service.mode {
    case .send: return true
    case .predefined: return false
    }
  }
  
  var proceedEnableDriver: Driver<Bool> {
    proceedEnabledRelay.asDriver()
  }
  
  var amountCautionDriver: Driver<Caution?> {
    amountCautionRelay.asDriver()
  }
  
  var addressCautionDriver: Driver<Caution?> {
    addressCautionRelay.asDriver()
  }
  
  var proceedSignal: Signal<SendSuiService.SendData> {
    proceedRelay.asSignal()
  }
  
  var token: Token {
    service.sendToken
  }
  
  func didTapProceed() {
    guard case .ready(let sendData) = service.state else {
      return
    }
    
    proceedRelay.accept(sendData)
  }
  
}

extension SendSuiService.AmountError: LocalizedError {
  
  var errorDescription: String? {
    switch self {
    case .insufficientBalance: return "send.amount_error.balance".localized
    default: return "\(self)"
    }
  }
  
}

extension SendSuiService.AddressError: LocalizedError {
  
  var errorDescription: String? {
    switch self {
    case .ownAddress: return "send.address_error.own_address".localized
    case .incorrectAddress:
      return "add_token.invalid_contract_address".localized
    }
  }
  
}
