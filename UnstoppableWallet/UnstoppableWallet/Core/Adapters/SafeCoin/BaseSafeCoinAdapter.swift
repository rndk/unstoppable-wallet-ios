import Foundation
import BigInt

class BaseSafeCoinAdapter {
  static let confirmationsThreshold = 18
  let decimals: Int = 9
  
  let safeCoinKitWrapper: SafeCoinKitWrapper
  
  init(safeCoinKitWrapper: SafeCoinKitWrapper) {
    self.safeCoinKitWrapper = safeCoinKitWrapper
  }
  
  var kit: SafeCoinKit {
    safeCoinKitWrapper.safeCoinKit
  }
  
  var isMainNet: Bool {
    kit.network == .mainNet
  }
  
  func convertToAdapterState(safeCoinSyncState: SafeCoinSyncState) -> AdapterState {
    switch safeCoinSyncState {
    case .synced: return .synced
    case .notSynced(let error): return .notSynced(error: error.convertedError)
    case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
    }
  }
  
  open var explorerTitle: String {
    fatalError("Must be overridden by subclass")
  }
  
  open func explorerUrl(transactionHash: String) -> String? {
    fatalError("Must be overridden by subclass")
  }
  
  func balanceDecimal(kitBalance: BigUInt?, decimals: Int) -> Decimal {
    guard let kitBalance = kitBalance else {
      return 0
    }
    guard let significand = Decimal(string: kitBalance.description) else {
      return 0
    }
    return Decimal(sign: .plus, exponent: -decimals, significand: significand)
  }
  
  func balanceData(balance: BigUInt?) -> BalanceData {
      BalanceData(available: balanceDecimal(kitBalance: balance, decimals: decimals))
  }

  func accountActive(address: String) /*async*/ -> Bool {
//      return (try? await tronKit.accountActive(address: address)) ?? true
    true
  }
  
}

// IAdapter
//extension BaseSafeCoinAdapter {
//
//    var statusInfo: [(String, Any)] {
//        []
//    }
//
//    var debugInfo: String {
//        ""
//    }
//
//}

extension BaseSafeCoinAdapter: IDepositAdapter {

    var receiveAddress: DepositAddress {
        ActivatedDepositAddress(
            receiveAddress: kit.address,
            isActive: true //TODO
        )
    }

}
