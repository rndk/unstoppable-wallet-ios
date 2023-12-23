import Foundation
import MarketKit
import RxSwift
import RxRelay
import BigInt
import HsExtensions

class SendDerivableCoinService {
  let sendToken: Token
  let mode: SendBaseService.Mode
  
  private let disposeBag = DisposeBag()
  private let adapter: DerivableCoinAdapter
  private let addressService: AddressService
  
  private let stateRelay = PublishRelay<State>()
  private(set) var state: State = .notReady {
    didSet {
      stateRelay.accept(state)
    }
  }
  
  private var coinAmount: BigUInt?
  private var addressData: AddressData?
  
  private let amountCautionRelay = PublishRelay<(error: Error?, warning: AmountWarning?)>()
  private var amountCaution: (error: Error?, warning: AmountWarning?) = (error: nil, warning: nil) {
    didSet {
      amountCautionRelay.accept(amountCaution)
    }
  }
  
  private let addressErrorRelay = PublishRelay<Error?>()
  private var addressError: Error? = nil {
    didSet {
      addressErrorRelay.accept(addressError)
    }
  }
  
  private let activeAddressRelay = PublishRelay<Bool>()
  
  init(
    token: Token,
    mode: SendBaseService.Mode,
    adapter: DerivableCoinAdapter,
    addressService: AddressService
  ) {
    self.sendToken = token
    self.mode = mode
    self.adapter = adapter
    self.addressService = addressService
    
    switch mode {
    case .predefined(let address): addressService.set(text: address)
    case .send: ()
    }
    
    subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
  }
  
  public func sync(addressState: AddressService.State) {
    switch addressState {
    case .success(let address):
      do {
        //addressData = AddressData(tronAddress: try TronKit.Address(address: address.raw), domain: address.domain)
//        _ = try PublicKey(string: address.raw) //TODO было закомменчено, если что - снова закомменть
        addressData = AddressData(coinAddress: Address(raw: address.raw), domain: address.domain)
      } catch {
        addressData = nil
      }
    default: addressData = nil
    }
    
    syncState()
  }
  
  private func syncState() {
    if amountCaution.error == nil,
       case .success = addressService.state,
       let sendAmount = coinAmount,
       let addressData = addressData {
      state = .ready(sendData: SendData(addressData: addressData, sendAmount: sendAmount))
    } else {
      state = .notReady
    }
  }
  
  private func validCoinAmount(amount: Decimal) throws -> BigUInt {
    guard let derivableCoinAmount = BigUInt(amount.hs.roundedString(decimal: sendToken.decimals)) else {
      throw AmountError.invalidDecimal
    }
    
    guard amount <= adapter.balanceData.available else {
      throw AmountError.insufficientBalance
    }
    
    return derivableCoinAmount
  }
  
}

extension SendDerivableCoinService {
  
  var stateObservable: Observable<State> {
    stateRelay.asObservable()
  }
  
  var amountCautionObservable: Observable<(error: Error?, warning: AmountWarning?)> {
    amountCautionRelay.asObservable()
  }
  
  var addressErrorObservable: Observable<Error?> {
    addressErrorRelay.asObservable()
  }
  
  var activeAddressObservable: Observable<Bool> {
    activeAddressRelay.asObservable()
  }
  
}

extension SendDerivableCoinService: IAvailableBalanceService {
  
  var availableBalance: DataStatus<Decimal> {
    .completed(adapter.balanceData.available)
  }
  
  var availableBalanceObservable: Observable<DataStatus<Decimal>> {
    Observable.just(availableBalance)
  }
  
}

extension SendDerivableCoinService: IAmountInputService {
  
  var amount: Decimal {
    0
  }
  
  var token: Token? {
    sendToken
  }
  
  var balance: Decimal? {
    adapter.balanceData.available
  }
  
  var amountObservable: Observable<Decimal> {
    .empty()
  }
  
  var tokenObservable: Observable<Token?> {
    .empty()
  }
  
  var balanceObservable: Observable<Decimal?> {
    .just(adapter.balanceData.available)
  }
  
  func onChange(amount: Decimal) {
    if amount > 0 {
      do {
        coinAmount = try validCoinAmount(amount: amount)
        
        var amountWarning: AmountWarning? = nil
        if amount.isEqual(to: adapter.balanceData.available) {
          switch sendToken.type {
          case .native: amountWarning = AmountWarning.coinNeededForFee
          default: ()
          }
        }
        
        amountCaution = (error: nil, warning: amountWarning)
      } catch {
        coinAmount = nil
        amountCaution = (error: error, warning: nil)
      }
    } else {
      coinAmount = nil
      amountCaution = (error: nil, warning: nil)
    }
    
    syncState()
  }
  
  func sync(address: String) {
    let coinAddress = Address(raw: address.trimmingCharacters(in: .whitespacesAndNewlines))
    
    guard coinAddress.raw != adapter.wrapper.coinKit.receiveAddress else {
      state = .notReady
      addressError = AddressError.ownAddress
      return
    }
    
    Single<Bool>
      .create { [weak self] observer in
        let task = Task { [weak self] in
          let active = self?.adapter.accountActive(address: coinAddress.raw) ?? false
          observer(.success(active))
        }
        
        return Disposables.create {
          task.cancel()
        }
      }
      .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
      .subscribe(onSuccess: { [weak self] active in
        self?.activeAddressRelay.accept(active)
      })
      .disposed(by: disposeBag)
  }
  
}

extension SendDerivableCoinService {
  
  enum State {
    case ready(sendData: SendData)
    case notReady
  }
  
  enum AmountError: Error {
    case invalidDecimal
    case insufficientBalance
  }
  
  enum AddressError: Error {
    case ownAddress
    case incorrectAddress
  }
  
  enum AmountWarning {
    case coinNeededForFee
  }
  
  struct AddressData {
    let coinAddress: Address
    let domain: String?
  }
  
  struct SendData {
    let addressData: SendDerivableCoinService.AddressData
    var sendAmount: BigUInt
    
    mutating func updateAmount(newAmount: BigUInt) {
      self.sendAmount = newAmount
    }
  }
  
}
