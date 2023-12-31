import Foundation
import UIKit
import MarketKit
import StorageKit

class SendSuiModule {
  
  static func viewController(
    token: Token,
    mode: SendBaseService.Mode,
    adapter: ISendSuiAdapter
  ) -> UIViewController? {
    
    let derivableAddressParserItem = SuiAddressParser()
    let addressParserChain = AddressParserChain().append(handler: derivableAddressParserItem)
    
    let addressService = AddressService(
      mode: .parsers(AddressParserFactory.parser(blockchainType: token.blockchainType), addressParserChain),
      marketKit: App.shared.marketKit,
      contactBookManager: App.shared.contactManager,
      blockchainType: token.blockchainType
    )
    
    let service = SendSuiService(
      token: token,
      mode: mode,
      adapter: adapter as! SuiAdapter,
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
    
    let viewModel = SendSuiViewModel(service: service)
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
    
    let recipientViewModel = SuiRecipientAddressViewModel(
      service: addressService,
      handlerDelegate: nil,
      sendService: service
    )
    
    let viewController = SendSuiViewController(
      coinKitWrapper: (adapter as! SuiAdapter).wrapper,
      viewModel: viewModel,
      availableBalanceViewModel: availableBalanceViewModel,
      amountViewModel: amountViewModel,
      recipientViewModel: recipientViewModel
    )
    
    return viewController
  }
  
}
