import Foundation
import RxSwift

class SuiAdapter: BaseSuiAdapter {
  
  override init(coinKitWrapper: SuiKitWrapper) {
    super.init(coinKitWrapper: coinKitWrapper)
  }
  
}

extension SuiAdapter: IAdapter {
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

extension SuiAdapter: IBalanceAdapter {
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

extension SuiAdapter: ISendSuiAdapter { }
