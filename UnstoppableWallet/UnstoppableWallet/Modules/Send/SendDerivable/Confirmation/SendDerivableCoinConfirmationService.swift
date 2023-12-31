import Foundation
import RxSwift
import RxCocoa
import BigInt
import HsExtensions
import Combine

class SendDerivableCoinConfirmationService {
  private var tasks = Set<AnyTask>()
  
  private var coinDecimals = Decimal(1_000_000_000)
  private let feeService: SendFeeService
  private let coinKitWrapper: DerivableCoinKitWrapper
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
  
  private(set) var sendData: SendDerivableCoinService.SendData
  private(set) var dataState: DataState
  
  private let sendStateRelay = PublishRelay<SendState>()
  private(set) var sendState: SendState = .idle {
    didSet {
      sendStateRelay.accept(sendState)
    }
  }
  
  init(
    sendData: SendDerivableCoinService.SendData,
    coinKitWrapper: DerivableCoinKitWrapper,
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
    prepareTransaction()
    syncAddress()
  }
  
  private var coinKit: DerivableCoinKit {
    coinKitWrapper.coinKit
  }
  
  private func initCoinDecimals() {
    var valueStr = "1"
    for _ in 1...coinKit.coinToken.decimals {
      valueStr.append("0")
    }
    coinDecimals = Decimal(string: valueStr) ?? 1_000_000_000
  }
  
  private func prepareTransaction() {
    Task { [weak self, coinKit, sendData] in
      let preparedTransaction: DerivablePreparedTransaction
      let minRent: BigUInt
      
      do {
        minRent = try await coinKit.calcMinRent()
        
        preparedTransaction = try await coinKit.prepareTransaction(
          to: sendData.addressData.coinAddress.raw,
          sendAmount: sendData.sendAmount
        )
      } catch {
        self?.feeState = .failed(error)
        self?.state = .notReady(errors: [error])
        return
      }
      
      self?.handleFees(preparedTransaction: preparedTransaction, rent: minRent)
    }.store(in: &tasks)
  }
  
  private func handleFees(preparedTransaction: DerivablePreparedTransaction, rent: BigUInt) {
    feeState = .completed(Decimal(preparedTransaction.expectedFee.total) / coinDecimals)
    
    let balance: Int = Int(coinKit.balance(contractAddress: coinKit.address))
    let send: Int = Int(sendData.sendAmount)
    let rentInt: Int = Int(rent)
    let fee: Int = Int(preparedTransaction.expectedFee.total)
    
    if balance - send < fee {
      state = .notReady(errors: [TransactionError.insufficientBalance(balance: BigUInt(balance))])
      return
    }
    
    let checkEnoughtRent = balance - send - rentInt
    
    if checkEnoughtRent <= 0 {
      state = .notReady(errors: [TransactionError.rentError(rent: rent)])
      return
    }
    
    state = .ready(preparedTransaction: preparedTransaction)
  }
  
  private func syncAddress() {
    guard let sendAddress = sendAddress else {
      return
    }
    
    self.sendAdressActive = true
  }
  
}

extension SendDerivableCoinConfirmationService: ISendXFeeValueService {
  
  var feeStateObservable: Observable<DataStatus<Decimal>> {
    feeStateRelay.asObservable()
  }
  
}

extension SendDerivableCoinConfirmationService {
  
  var stateObservable: Observable<State> {
    stateRelay.asObservable()
  }
  
  var sendStateObservable: Observable<SendState> {
    sendStateRelay.asObservable()
  }
  
  var sendAdressActiveObservable: Observable<Bool> {
    sendAdressActiveRelay.asObservable()
  }
  
  func getSendData() -> SendDerivableCoinService.SendData {
    return self.sendData
  }
  
  func send() {
    guard case .ready(let preparedTransaction) = state, case .completed(_) = feeState else {
      return
    }
    
    sendState = .sending
    
    Task { [weak self, coinKitWrapper] in
      do {
        try await coinKitWrapper.send(preparedTransaction: preparedTransaction)
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

extension SendDerivableCoinConfirmationService {
  
  enum State {
    case ready(preparedTransaction: DerivablePreparedTransaction)
    case notReady(errors: [Error])
  }
  
  struct DataState {
    let sendData: SendDerivableCoinService.SendData?
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
