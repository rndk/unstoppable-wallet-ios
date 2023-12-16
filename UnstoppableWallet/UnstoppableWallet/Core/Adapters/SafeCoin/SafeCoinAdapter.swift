import Foundation
import RxSwift

class SafeCoinAdapter: BaseSafeCoinAdapter {
  static let decimals = 9
  
  override init(safeCoinKitWrapper: SafeCoinKitWrapper) {
    super.init(safeCoinKitWrapper: safeCoinKitWrapper)
  }
}

//extension SafeCoinAdapter {
//  static func clear(except excludedWalletIds: [String]) throws {
//    //try TronKit.Kit.clear(exceptFor: excludedWalletIds)
//  }
//}

// IAdapter
extension SafeCoinAdapter: IAdapter {
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

extension SafeCoinAdapter: IBalanceAdapter {
    var balanceState: AdapterState {
      convertToAdapterState(safeCoinSyncState: kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        kit.syncStatePublisher.asObservable().map { [weak self] in
            self?.convertToAdapterState(safeCoinSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
      let baldata = balanceData(balance: kit.balance(contractAddress: kit.address)) //TODO
      print(">>> SafeCoinAdapter balanceData:\(baldata.balanceTotal)")
      return baldata
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        kit.balancePublisher.asObservable().map { [weak self] in
          print(">>> SafeCoinAdapter balanceDataUpdatedObservable:\($0)")
           return self?.balanceData(balance: $0) ?? BalanceData(available: 0)
        }
    }
  
}

extension SafeCoinAdapter: ISendSafeCoinAdapter {
  func validate(address: String) throws {
    //TODO validate address
  }
  func sendTransaction(trx: String) {
    //TODO send transaction
  }
  var availableBalance: Decimal {
    //TODO balance to Decimals
    0
  }
}

//extension BaseTronAdapter: IDepositAdapter {
//    var receiveAddress: DepositAddress {
//        ActivatedDepositAddress(
//            receiveAddress: tronKit.receiveAddress.base58,
//            isActive: tronKit.accountActive
//        )
//    }
//}
