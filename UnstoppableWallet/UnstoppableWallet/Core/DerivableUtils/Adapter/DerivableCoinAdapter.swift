import Foundation
import RxSwift

class DerivableCoinAdapter: BaseDerivableCoinAdapter {
  
  override init(coinKitWrapper: DerivableCoinKitWrapper) {
    super.init(coinKitWrapper: coinKitWrapper)
    self.decimals = coinKitWrapper.coinKit.coinToken.decimals
  }
}

// IAdapter
extension DerivableCoinAdapter: IAdapter {
  var statusInfo: [(String, Any)] {
    []
  }
  
  var debugInfo: String {
    ""
  }
  
  func start() {
    kit.start()
  }
  
  func stop() {
    kit.stop()
  }
  
  func refresh() {
    kit.refresh()
  }
}

extension DerivableCoinAdapter: IBalanceAdapter {
  var balanceState: AdapterState {
    convertToAdapterState(coinSyncState: kit.syncState)
  }
  
  var balanceStateUpdatedObservable: Observable<AdapterState> {
    kit.syncStatePublisher.asObservable().map { [weak self] in
      self?.convertToAdapterState(coinSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
    }
  }
  
  var balanceData: BalanceData {
    balanceData(balance: kit.balance(contractAddress: kit.address))
  }
  
  var balanceDataUpdatedObservable: Observable<BalanceData> {
    kit.balancePublisher.asObservable().map { [weak self] in
      return self?.balanceData(balance: $0) ?? BalanceData(available: 0)
    }
  }
  
}

extension DerivableCoinAdapter: ISendDerivableCoinAdapter { }
