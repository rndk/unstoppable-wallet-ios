import Foundation
import BigInt

class BaseDerivableCoinAdapter {
  static let confirmationsThreshold = 18
  let decimals: Int = 9
  
  let wrapper: DerivableCoinKitWrapper
  
  init(coinKitWrapper: DerivableCoinKitWrapper) {
    self.wrapper = coinKitWrapper
  }
  
  var kit: DerivableCoinKit {
    wrapper.coinKit
  }
  
  var isMainNet: Bool {
    kit.isMainNet()
  }
  
  func convertToAdapterState(coinSyncState: DerivableCoinSyncState) -> AdapterState {
    switch coinSyncState {
    case .synced: return .synced
    case .notSynced(let error): return .notSynced(error: error.convertedError)
    case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
    }
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
    //return (try? await tronKit.accountActive(address: address)) ?? true
    true
  }
  
}

extension BaseDerivableCoinAdapter: IDepositAdapter {
  
  var receiveAddress: DepositAddress {
    ActivatedDepositAddress(
      receiveAddress: kit.address,
      isActive: true //TODO
    )
  }
  
}
