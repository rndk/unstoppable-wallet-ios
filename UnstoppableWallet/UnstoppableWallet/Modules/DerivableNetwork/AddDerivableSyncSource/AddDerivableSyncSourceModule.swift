import Foundation
import UIKit
import ThemeKit
import MarketKit

struct AddDerivableSyncSourceModule {
  
  static func viewController(blockchainType: BlockchainType) -> UIViewController {
    let service = AddDerivableSyncSourceService(
      blockchainType: blockchainType,
      syncSourceManager: App.shared.derivableSyncSourceManager
    )
    let viewModel = AddDerivableSyncSourceViewModel(service: service)
    let viewController = AddDerivableSyncSourceViewController(viewModel: viewModel)
    
    return ThemeNavigationController(rootViewController: viewController)
  }
  
}
