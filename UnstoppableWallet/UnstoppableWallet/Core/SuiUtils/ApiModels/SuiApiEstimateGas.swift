import Foundation
import Commons

public struct EstimateGas: Codable {
  let jsonrpc: String?
  let id: Int?
  let result: EstimateGasResult?
}

public struct EstimateGasResult: Codable {
  let balanceChanges: [BalanceChange]?
  let objectChanges: AnyCodable?
  let effects: Effects?
  let sender: String?
  let input: AnyCodable?
}
