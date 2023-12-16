import Foundation
import UIKit
import MarketKit
import StorageKit

class SendSafeCoinModule {
  static func viewController(
    token: Token,
    mode: SendBaseService.Mode,
    adapter: ISendSafeCoinAdapter
  ) -> UIViewController? {
    
    let safeCoinAddressParserItem = SafeCoinAddressParser()
    let addressParserChain = AddressParserChain().append(handler: safeCoinAddressParserItem)
    
    let addressService = AddressService(
      mode: .parsers(AddressParserFactory.parser(blockchainType: .safeCoin), addressParserChain),
      marketKit: App.shared.marketKit,
      contactBookManager: App.shared.contactManager,
      blockchainType: .safeCoin
    )
    
    let service = SendSafeCoinService(
      token: token,
      mode: mode,
      adapter: adapter as! SafeCoinAdapter,
      addressService: addressService
    )
    let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
    let fiatService = FiatService(
      switchService: switchService,
      currencyKit: App.shared.currencyKit,
      marketKit: App.shared.marketKit
    )
    
    switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)
    
    let coinService = CoinService(
      token: token,
      currencyKit: App.shared.currencyKit,
      marketKit: App.shared.marketKit
    )
    
    let viewModel = SendSafeCoinViewModel(service: service)
    let availableBalanceViewModel = SendAvailableBalanceViewModel(
      service: service,
      coinService: coinService,
      switchService: switchService
    )
    
    let amountViewModel = AmountInputViewModel(
      service: service,
      fiatService: fiatService,
      switchService: switchService,
      decimalParser: AmountDecimalParser()
    )
    addressService.amountPublishService = amountViewModel
    
    let recipientViewModel = SafeCoinRecipientAddressViewModel(
      service: addressService,
      handlerDelegate: nil,
      sendService: service
    )
    
    let viewController = SendSafeCoinViewController(
      safeCoinKitWrapper: (adapter as! SafeCoinAdapter).safeCoinKitWrapper,
      viewModel: viewModel,
      availableBalanceViewModel: availableBalanceViewModel,
      amountViewModel: amountViewModel,
      recipientViewModel: recipientViewModel
    )
    
    return viewController
  }
}
