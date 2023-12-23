import Foundation
import RxSwift
import RxCocoa
import BigInt
import HsExtensions
import Combine

class SendDerivableCoinConfirmationService {
  private var tasks = Set<AnyTask>()
  
  //TODO возможно тут придется передавать Token, чтоб взять из него decimals
  private let coinDecimals = Decimal(1_000_000_000)
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
    prepareTransaction()
    syncAddress()
  }
  
  private var coinKit: DerivableCoinKit {
    coinKitWrapper.coinKit
  }
  
  private func prepareTransaction() {
    Task { [weak self, coinKit, sendData] in
      let preparedTransaction: DerivablePreparedTransaction
      
      do {
        if coinKit.balance(contractAddress: coinKit.address) == self?.sendData.sendAmount {
          // если нажал "отправить все", то вычисляем цену ренты аккаунта и уменьшаем отправляемую сумму?
          let minRent = try await coinKit.calcMinRent()
          
          preparedTransaction = try await coinKit.prepareTransaction(
            to: sendData.addressData.coinAddress.raw,
            sendAmount: sendData.sendAmount - minRent
          )
        } else {
          preparedTransaction = try await coinKit.prepareTransaction(
            to: sendData.addressData.coinAddress.raw,
            sendAmount: sendData.sendAmount
          )
        }
      } catch {
        self?.feeState = .failed(error)
        self?.state = .notReady(errors: [error])
        return
      }
      
      self?.handleFees(preparedTransaction: preparedTransaction)
    }.store(in: &tasks)
  }
  
  private func handleFees(preparedTransaction: DerivablePreparedTransaction) {
//    var totalFees = 0
    //      for fee in fees {
    //          switch fee {
    //          case .bandwidth(let points, let price):
    //              totalFees += points * price
    //          case .energy(let required, let price):
    //              totalFees += required * price
    //          case .accountActivation(let amount):
    //              totalFees += amount
    //          }
    //      }
    
    //      feeState = .completed(Decimal(totalFees) / trxDecimals)
    //
    //      var totalAmount = 0
    //      if let transfer = contract as? TransferContract {
    //          var sentAmount = transfer.amount
    //          if tronKit.trxBalance == transfer.amount {
    //              // If the maximum amount is being sent, then we subtract fees from sent amount
    //              sentAmount = sentAmount - totalFees
    //
    //              guard sentAmount > 0 else {
    //                  state = .notReady(errors: [TransactionError.zeroAmount])
    //                  return
    //              }
    //
    //              contract = tronKit.transferContract(toAddress: transfer.toAddress, value: sentAmount)
    //              dataState = DataState(
    //                  contract: contract,
    //                  decoration: tronKit.decorate(contract: contract)
    //              )
    //          }
    //          totalAmount += sentAmount
    //      }
    //
    //      totalAmount += totalFees
    //
    //      if tronKit.trxBalance < totalAmount {
    //          state = .notReady(errors: [TransactionError.insufficientBalance(balance: tronKit.trxBalance)])
    //          return
    //      }
    
    //state = .ready(fees: fees)
    feeState = .completed(Decimal(preparedTransaction.expectedFee.total) / coinDecimals)
//    state = .ready(fee: BigUInt(fee.expectedFee.total))
    state = .ready(preparedTransaction: preparedTransaction)
  }
  
  private func syncAddress() {
    guard let sendAddress = sendAddress else {
      return
    }
    
    Task { [weak self, coinKit] in
      //let active = try? await tronKit.accountActive(address: sendAddress)
//      let active = try? await safeCoinKit.accountActive(address: sendAddress) //TODO IMPLEMENT
      let active = true //remove
      self?.sendAdressActive = active ?? true
    }.store(in: &tasks)
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
      try await Task.sleep(nanoseconds:1_000_000_000)
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
    case zeroAmount
  }
  
}
