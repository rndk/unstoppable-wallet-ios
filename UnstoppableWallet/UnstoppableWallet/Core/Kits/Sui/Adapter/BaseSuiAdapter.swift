import Foundation
import BigInt

class BaseSuiAdapter {
  
  let decimals = 9
  let wrapper: SuiKitWrapper
  
  init(coinKitWrapper: SuiKitWrapper) {
    self.wrapper = coinKitWrapper
  }
  
  var kit: SuiKit {
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
  
  func accountActive(address: String) -> Bool {
    true
  }
  
}

extension BaseSuiAdapter: IDepositAdapter {
  
  var receiveAddress: DepositAddress {
    ActivatedDepositAddress(
      receiveAddress: kit.address,
      isActive: true
    )
  }
  
}
