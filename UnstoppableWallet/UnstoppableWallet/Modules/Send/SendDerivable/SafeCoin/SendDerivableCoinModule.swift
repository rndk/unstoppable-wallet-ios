import Foundation
import UIKit
import MarketKit
import StorageKit

class SendDerivableCoinModule {
  static func viewController(
    token: Token,
    mode: SendBaseService.Mode,
    adapter: ISendDerivableCoinAdapter
  ) -> UIViewController? {
    
    let safeCoinAddressParserItem = DerivableCoinAddressParser()
    let addressParserChain = AddressParserChain().append(handler: safeCoinAddressParserItem)
    
    let addressService = AddressService(
//      mode: .parsers(AddressParserFactory.parser(blockchainType: .safeCoin), addressParserChain), //TODO TEST
      mode: .parsers(AddressParserFactory.parser(blockchainType: token.blockchainType), addressParserChain),
      marketKit: App.shared.marketKit,
      contactBookManager: App.shared.contactManager,
//      blockchainType: .safeCoin //TODO TEST
      blockchainType: token.blockchainType
    )
    
    let service = SendDerivableCoinService(
      token: token,
      mode: mode,
      adapter: adapter as! DerivableCoinAdapter,
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
    
    let viewModel = SendDerivableCoinViewModel(service: service)
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
    
    let recipientViewModel = DerivableCoinRecipientAddressViewModel(
      service: addressService,
      handlerDelegate: nil,
      sendService: service
    )
    
    let viewController = SendDerivableCoinViewController(
      coinKitWrapper: (adapter as! DerivableCoinAdapter).wrapper,
      viewModel: viewModel,
      availableBalanceViewModel: availableBalanceViewModel,
      amountViewModel: amountViewModel,
      recipientViewModel: recipientViewModel
    )
    
    return viewController
  }
}
