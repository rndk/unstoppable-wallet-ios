import Foundation
import BigInt

class SuiFeeProvider {
  
  private let networkInteractor: SuiNetworkInteractor
  private let suiCoinId = "0x2::coin::Coin<0x2::sui::SUI>"
  
  init(networkInteractor: SuiNetworkInteractor) {
    self.networkInteractor = networkInteractor
  }
  
}

extension SuiFeeProvider {
  
  func getOwnedObjects(address: String) async throws -> [SuiObjectData] {
    let response = try await networkInteractor.getOwnedObjects(address: address)
    return response?.result?.data ?? []
  }
  
  func calcInitialFee(wannaSend: BigUInt, available: BigUInt) -> (BigUInt, BigUInt) {
    var initialFee = BigUInt(Double(wannaSend) * 0.05)
    if initialFee < BigUInt(2_000_000) {
      initialFee = BigUInt(2_000_000)
    }
    if wannaSend + initialFee > available {
      let newSend = available - initialFee
      return (initialFee, newSend)
    }
    return (initialFee, wannaSend)
  }
  
  func getObjectsForAmount(desiredAmount: BigUInt, objects: [SuiObjectData]) -> [String] {
    var sum: Int64 = 0
    var ids: [String] = []
    
    for object in objects {
      if sum < desiredAmount {
        ids.append(object.data!.objectId!)
        let type = object.data?.type
        if type != nil, type == suiCoinId {
          let balanceString = object.data?.content?.fields?.balance
          if balanceString != nil {
            sum += abs(Int64(balanceString!) ?? 0)
          }
        }
      } else {
        break
      }
    }
    
    return ids
  }
  
  func calcRealFee(feeResponse: EstimateGas) -> BigInt {
    guard let gUsed = feeResponse.result?.effects?.gasUsed else {
      return BigInt.zero
    }
    
    let computationCost: Int = Int(gUsed.computationCost) ?? 0
    let storageCost: Int = Int(gUsed.storageCost) ?? 0
    let storageRebate: Int = Int(gUsed.storageRebate) ?? 0
    let result = computationCost + storageCost - storageRebate

    return BigInt(result)
  }
  
}
