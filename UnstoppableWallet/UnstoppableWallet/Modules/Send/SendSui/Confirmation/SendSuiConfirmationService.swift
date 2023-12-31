import Foundation
import RxSwift
import RxCocoa
import BigInt
import HsExtensions
import Combine

class SendSuiConfirmationService {
  
  private var tasks = Set<AnyTask>()
  
  private var coinDecimals = Decimal(1_000_000_000)
  private let feeService: SendFeeService
  private let coinKitWrapper: SuiKitWrapper
  private let evmLabelManager: EvmLabelManager
  private let sendAddress: Address?
  
  private let stateRelay = PublishRelay<State>()
  private(set) var state: State = .notReady(errors: []) {
    didSet {
      stateRelay.accept(state)
    }
  }
  
  let feeStateRelay = BehaviorRelay<DataStatus<Decimal>>(value: .loading)
  var feeState: DataStatus<Decimal> = .loading {
    didSet {
      if !feeState.equalTo(oldValue) {
        feeStateRelay.accept(feeState)
      }
    }
  }
  
  private let sendAdressActiveRelay = PublishRelay<Bool>()
  private(set) var sendAdressActive: Bool = true {
    didSet {
      sendAdressActiveRelay.accept(sendAdressActive)
    }
  }
  
  private(set) var sendData: SendSuiService.SendData
  private(set) var dataState: DataState
  
  private let sendStateRelay = PublishRelay<SendState>()
  private(set) var sendState: SendState = .idle {
    didSet {
      sendStateRelay.accept(sendState)
    }
  }
  
  init(
    sendData: SendSuiService.SendData,
    coinKitWrapper: SuiKitWrapper,
    feeService: SendFeeService,
    evmLabelManager: EvmLabelManager
  ) {
    self.sendData = sendData
    self.coinKitWrapper = coinKitWrapper
    self.feeService = feeService
    self.evmLabelManager = evmLabelManager
    
    dataState = DataState(sendData: sendData)
    sendAddress = sendData.addressData.coinAddress
    feeService.feeValueService = self
    initCoinDecimals()
    syncAddress()
    estimateFee()
  }
  
  private var coinKit: SuiKit {
    coinKitWrapper.coinKit
  }
  
  private func initCoinDecimals() {
    var valueStr = "1"
    for _ in 1...coinKit.coinToken.decimals {
      valueStr.append("0")
    }
    coinDecimals = Decimal(string: valueStr) ?? 1_000_000_000
  }
  
  private func estimateFee() {
    Task { [weak self, coinKit, sendData] in
      var fee: BigUInt = 0
      var newSendSum: BigUInt = 0
      
      do {
        (fee, newSendSum) = try await coinKit.estimateFee(
          to: sendData.addressData.coinAddress.raw,
          sendAmount: sendData.sendAmount
        )
      } catch {
        self?.feeState = .failed(error)
        self?.state = .notReady(errors: [error])
        return
      }
      
      self?.handleFees(fee: fee, newSendSum: newSendSum)
    }.store(in: &tasks)
  }
  
  private func handleFees(fee: BigUInt, newSendSum: BigUInt) {
    feeState = .completed(Decimal(Int64(fee)) / coinDecimals)
    
    let balance: Int = Int(coinKit.balance(contractAddress: coinKit.address))
    let sendMax = sendData.sendAmount == balance
    
    let send: Int = Int(sendData.sendAmount) //TODO TEST
//    let send: Int = if sendData.sendAmount == newSendSum {
//      Int(sendData.sendAmount)
//    } else {
//      if sendMax {
//        Int(sendData.sendAmount)
//      } else {
//        Int(newSendSum)
//      }
//    }
    
    sendData.updateAmount(newAmount: BigUInt(send))
    
    let localFee: Int = Int(fee)
    
    if !sendMax, localFee + send > balance {
      state = .notReady(errors: [TransactionError.insufficientBalance(balance: BigUInt(balance))])
      return
    }
    
    state = .ready(fee: fee)
  }
  
  private func syncAddress() {
    guard let sendAddress = sendAddress else {
      return
    }
    
    self.sendAdressActive = true
  }
  
}

extension SendSuiConfirmationService: ISendXFeeValueService {
  
  var feeStateObservable: Observable<DataStatus<Decimal>> {
    feeStateRelay.asObservable()
  }
  
}

extension SendSuiConfirmationService {
  
  var stateObservable: Observable<State> {
    stateRelay.asObservable()
  }
  
  var sendStateObservable: Observable<SendState> {
    sendStateRelay.asObservable()
  }
  
  var sendAdressActiveObservable: Observable<Bool> {
    sendAdressActiveRelay.asObservable()
  }
  
  func getSendData() -> SendSuiService.SendData {
    return self.sendData
  }
  
  func send() {
    guard case .ready(let fee) = state, case .completed(_) = feeState else {
      return
    }
    
    sendState = .sending
    
    Task { [weak self, coinKitWrapper] in
      do {
        try await coinKitWrapper.send(
          to: sendData.addressData.coinAddress.raw,
          fee: fee,
          amount: sendData.sendAmount
        )
        self?.sendState = .sent
        self?.refreshCoinBalance()
      } catch {
        self?.sendState = .failed(error: error)
      }
    }.store(in: &tasks)
  }
  
  func refreshCoinBalance() {
    Task {
      try await Task.sleep(nanoseconds: 3_000_000_000)
      coinKitWrapper.refresh()
    }
  }
  
}

extension SendSuiConfirmationService {
  
  enum State {
    case ready(fee: BigUInt)
    case notReady(errors: [Error])
  }
  
  struct DataState {
    let sendData: SendSuiService.SendData?
  }
  
  enum SendState {
    case idle
    case sending
    case sent
    case failed(error: Error)
  }
  
  enum TransactionError: Error {
    case insufficientBalance(balance: BigUInt)
    case rentError(rent: BigUInt)
    case zeroAmount
  }
  
}
