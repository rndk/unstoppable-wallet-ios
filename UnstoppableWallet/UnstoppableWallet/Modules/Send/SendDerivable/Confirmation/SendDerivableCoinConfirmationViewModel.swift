import Foundation
import RxSwift
import RxCocoa
import BigInt
import MarketKit
import HsExtensions

class SendDerivableCoinConfirmationViewModel {
  private let disposeBag = DisposeBag()
  
  private let service: SendDerivableCoinConfirmationService
  private let coinServiceFactory: EvmCoinServiceFactory
  private let evmLabelManager: EvmLabelManager
  private let contactLabelService: ContactLabelService
  
  private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
  
  private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
  private let cautionsRelay = BehaviorRelay<[TitledCaution]>(value: [])
  
  private let sendingRelay = PublishRelay<()>()
  private let sendSuccessRelay = PublishRelay<Void>()
  private let sendFailedRelay = PublishRelay<String>()
  
  private let feesRelay = PublishRelay<[DerivableCoinFeeViewItem]>()
  
  init(
    service: SendDerivableCoinConfirmationService,
    coinServiceFactory: EvmCoinServiceFactory,
    evmLabelManager: EvmLabelManager,
    contactLabelService: ContactLabelService
  ) {
    self.service = service
    self.coinServiceFactory = coinServiceFactory
    self.evmLabelManager = evmLabelManager
    self.contactLabelService = contactLabelService
    
    subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }
    subscribe(disposeBag, service.sendAdressActiveObservable) { [weak self] _ in self?.reSyncServiceState() }
    subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in self?.reSyncServiceState() }
    
    sync(state: service.state)
    sync(sendState: service.sendState)
  }
  
  private func reSyncServiceState() {
    sync(state: service.state)
  }
  
  private func sync(state: SendDerivableCoinConfirmationService.State) {
    switch state {
    case .ready(let fee):
      feesRelay.accept(feeItems(fee: BigUInt(fee.expectedFee.total)))
      sendEnabledRelay.accept(true)
      cautionsRelay.accept([])
      
    case .notReady(let errors):
      feesRelay.accept([])
      sendEnabledRelay.accept(false)
      
      let cautions = errors.map { error in
        if let someError = error as? SendDerivableCoinConfirmationService.TransactionError {
          switch someError {
          case .insufficientBalance(let balance):
            let coinValue = coinServiceFactory.baseCoinService.coinValue(value: balance)
            let balanceString = ValueFormatter.instance.formatShort(coinValue: coinValue)
            
            return TitledCaution(
              title: "fee_settings.errors.insufficient_balance".localized,
              text: "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? ""),
              type: .error
            )
            
          case .zeroAmount:
            return TitledCaution(
              title: "alert.error".localized,
              text: "fee_settings.errors.zero_amount.info".localized,
              type: .error
            )
          case .rentError(let rent):
            let coinValue = coinServiceFactory.baseCoinService.coinValue(value: rent)
            let cost = ValueFormatter.instance.formatShort(coinValue: coinValue)
            return TitledCaution(
              title: "Error",
              text: "fee_settings.errors.transaction_underpriced_rent".localized(cost!),
              type: .error
            )
          }
        } else {
          return TitledCaution(
            title: "Error",
            text: error.convertedError.smartDescription,
            type: .error
          )
        }
      }
      
      cautionsRelay.accept(cautions)
    }
    
    sectionViewItemsRelay.accept(items(dataState: service.dataState))
  }
  
  private func formatted(slippage: Decimal) -> String? {
    guard slippage != OneInchSettingsService.defaultSlippage else {
      return nil
    }
    
    return "\(slippage)%"
  }
  
  private func sync(sendState: SendDerivableCoinConfirmationService.SendState) {
    switch sendState {
    case .idle: ()
    case .sending: sendingRelay.accept(())
    case .sent: sendSuccessRelay.accept(())
    case .failed(let error): sendFailedRelay.accept(error.convertedError.smartDescription)
    }
  }
  
  private func feeItems(fee: BigUInt) -> [DerivableCoinFeeViewItem] {
    var viewItems = [DerivableCoinFeeViewItem]()
    let coinService = coinServiceFactory.baseCoinService
    
    let amountData = coinService.amountData(value: BigUInt(service.getSendData().sendAmount))
    
    viewItems.append(
      DerivableCoinFeeViewItem(
        title: "tron.send.activation_fee".localized,
        info: "tron.send.activation_fee.info".localized,
        value1: ValueFormatter.instance.formatShort(coinValue: amountData.coinValue) ?? "n/a".localized,
        value2: amountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) },
        value2IsSecondary: true
      )
    )
    
    return []
  }
  
  private func items(
    dataState: SendDerivableCoinConfirmationService.DataState
  ) -> [SectionViewItem] {
    return sendBaseCoinItems(
      to: dataState.sendData!.addressData.coinAddress,
      value: dataState.sendData!.sendAmount
    )
    
  }
  
  private func addressActiveViewItems() -> [ViewItem] {
    guard !service.sendAdressActive else {
      return []
    }
    
    return [
      .warning(
        text: "tron.send.inactive_address".localized,
        title: "tron.send.activation_fee".localized,
        info: "tron.send.activation_fee.info".localized
      )
    ]
  }
  
  private func amountViewItem(
    coinService: CoinService,
    value: BigUInt,
    type: AmountType
  ) -> ViewItem {
    amountViewItem(
      coinService: coinService,
      amountData: coinService.amountData(value: value, sign: type.sign),
      type: type
    )
  }
  
  private func amountViewItem(
    coinService: CoinService,
    value: Decimal,
    type: AmountType
  ) -> ViewItem {
    amountViewItem(
      coinService: coinService,
      amountData: coinService.amountData(value: value, sign: type.sign),
      type: type
    )
  }
  
  private func amountViewItem(
    coinService: CoinService,
    amountData: AmountData,
    type: AmountType
  ) -> ViewItem {
    let token = coinService.token
    
    return .amount(
      iconUrl: token.coin.imageUrl,
      iconPlaceholderImageName: token.placeholderImageName,
      coinAmount: ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized,
      currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
      type: type
    )
  }
  
  private func estimatedAmountViewItem(
    coinService: CoinService,
    value: Decimal,
    type: AmountType
  ) -> ViewItem {
    let token = coinService.token
    let amountData = coinService.amountData(value: value, sign: type.sign)
    let coinAmount = ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized
    
    return .amount(
      iconUrl: token.coin.imageUrl,
      iconPlaceholderImageName: token.placeholderImageName,
      coinAmount: "\(coinAmount) \("swap.estimate_short".localized)",
      currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
      type: type
    )
  }
  
  private func sendBaseCoinItems(
    to: Address,
    value: BigUInt
  ) -> [SectionViewItem] {
    let toValue = to.raw
    let contactData = contactLabelService.contactData(for: toValue)
    
    var viewItems: [ViewItem] = [
      .subhead(
        iconName: "arrow_medium_2_up_right_24",
        title: "send.confirmation.you_send".localized,
        value: coinServiceFactory.baseCoinService.token.coin.name
      ),
      amountViewItem(
        coinService: coinServiceFactory.baseCoinService,
        value: value,
        type: .neutral
      ),
      .address(
        title: "send.confirmation.to".localized,
        value: toValue,
        valueTitle: evmLabelManager.addressLabel(address: toValue),
        contactAddress: contactData.contactAddress
      ),
    ]
    
    if let contactName = contactData.name {
      viewItems.append(.value(
        title: "send.confirmation.contact_name".localized,
        value: contactName,
        type: .regular)
      )
    }
    
    return [SectionViewItem(viewItems: viewItems + addressActiveViewItems())]
  }
  
  private func coinService(token: MarketKit.Token) -> CoinService {
    coinServiceFactory.coinService(token: token)
  }
  
}

extension SendDerivableCoinConfirmationViewModel {
  
  var sectionViewItemsDriver: Driver<[SectionViewItem]> {
    sectionViewItemsRelay.asDriver()
  }
  
  var feesSignal: Signal<[DerivableCoinFeeViewItem]> {
    feesRelay.asSignal()
  }
  
  var sendEnabledDriver: Driver<Bool> {
    sendEnabledRelay.asDriver()
  }
  
  var cautionsDriver: Driver<[TitledCaution]> {
    cautionsRelay.asDriver()
  }
  
  var sendingSignal: Signal<()> {
    sendingRelay.asSignal()
  }
  
  var sendSuccessSignal: Signal<Void> {
    sendSuccessRelay.asSignal()
  }
  
  var sendFailedSignal: Signal<String> {
    sendFailedRelay.asSignal()
  }
  
  func send() {
    service.send()
  }
  
}

extension SendDerivableCoinConfirmationViewModel {
  
  struct SectionViewItem {
    let viewItems: [ViewItem]
  }
  
  enum ViewItem {
    case subhead(iconName: String, title: String, value: String)
    case amount(
      iconUrl: String?,
      iconPlaceholderImageName: String,
      coinAmount: String,
      currencyAmount: String?,
      type: AmountType
    )
    case address(title: String, value: String, valueTitle: String?, contactAddress: ContactAddress?)
    case value(title: String, value: String, type: ValueType)
    case warning(text: String, title: String, info: String)
  }
  
  struct DerivableCoinFeeViewItem {
    let title: String
    let info: String
    let value1: String
    let value2: String?
    let value2IsSecondary: Bool
  }
  
}
