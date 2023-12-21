import Foundation
import MarketKit
import SwiftUI
import ThemeKit
import UIKit

struct DerivableNetworkModule {
  static func viewController(blockchain: Blockchain) -> UIViewController {
    let service = DerivableNetworkService(
      blockchain: blockchain,
      derivableSyncSourceManager: App.shared.derivableSyncSourceManager
    )
    let viewModel = DerivableNetworkViewModel(service: service)
    let viewController = DerivableNetworkViewController(viewModel: viewModel)
    
    return ThemeNavigationController(rootViewController: viewController)
  }
}

struct DerivableNetworkView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let blockchain: Blockchain

    func makeUIViewController(context _: Context) -> UIViewController {
      DerivableNetworkModule.viewController(blockchain: blockchain)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
