import Foundation
import UIKit
import ThemeKit
import MarketKit
import HsExtensions
import StorageKit

class SendSuiConfirmationModule {
  
  static func viewController(
    coinKitWrapper: SuiKitWrapper,
    sendData: SendSuiService.SendData
  ) -> UIViewController? {
    guard let coinServiceFactory = EvmCoinServiceFactory(
      blockchainType: coinKitWrapper.blockchainType,
      marketKit: App.shared.marketKit,
      currencyKit: App.shared.currencyKit,
      coinManager: App.shared.coinManager
    ) else {
      return nil
    }
    
    let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
    let feeFiatService = FiatService(
      switchService: switchService,
      currencyKit: App.shared.currencyKit,
      marketKit: App.shared.marketKit
    )
    let feeService = SendFeeService(
      fiatService: feeFiatService,
      feeToken: coinServiceFactory.baseCoinService.token
    )
    let feeViewModel = SendFeeViewModel(service: feeService)
    
    let service = SendSuiConfirmationService(
      sendData: sendData,
      coinKitWrapper: coinKitWrapper,
      feeService: feeService,
      evmLabelManager: App.shared.evmLabelManager
    )
    let contactLabelService = ContactLabelService(
      contactManager: App.shared.contactManager,
      blockchainType: coinKitWrapper.blockchainType
    )
    let viewModel = SendSuiConfirmationViewModel(
      service: service,
      coinServiceFactory: coinServiceFactory,
      evmLabelManager: App.shared.evmLabelManager,
      contactLabelService: contactLabelService
    )
    let controller = SendSuiConfirmationViewController(
      transactionViewModel: viewModel,
      feeViewModel: feeViewModel
    )
    
    return controller
  }
  
}
