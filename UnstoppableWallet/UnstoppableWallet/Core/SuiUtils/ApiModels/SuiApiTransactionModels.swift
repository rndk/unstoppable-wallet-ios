import Foundation
import Commons

struct SuiApiTransactionResponse: Codable {
  let jsonrpc: String?
  let id: Int?
  let result: SuiTxResult?
}

struct SuiTxResult: Codable {
  let nextCursor: String?
  let hasNextPage: Bool?
  let data: [SuiTransactionData]?
}

struct SuiTransactionData: Codable {
  let digest: String?
  let transaction: SuiTx?
  let effects: Effects?
  let timestampMs: String?
  let balanceChanges: [BalanceChange]?
}

struct BalanceChange: Codable {
  let coinType: String?
  let amount: String?
  let owner: SuiTxOwner?
}

struct SuiTxOwner: Codable {
  let addressOwner: String?
  
  enum CodingKeys: String, CodingKey {
    case addressOwner = "AddressOwner"
  }
}

struct Effects: Codable {
  let transactionDigest: String?
  let messageVersion: String?
  let executedEpoch: String?
  let gasUsed: GasUsed?
  let status: Status?
  let dependencies: AnyCodable?
  let modifiedAtVersions: AnyCodable?
  let gasObject: AnyCodable?
  let deleted: AnyCodable?
  let mutated: AnyCodable?
}

struct GasUsed: Codable {
  let storageCost: String
  let storageRebate: String
  let computationCost: String
  let nonRefundableStorageFee: String
}

struct Status: Codable {
  let status: String?
}

struct SuiTx: Codable {
  let data: SuiTxData?
  let txSignatures: [String]?
}

struct SuiTxData: Codable {
  let sender: String?
  let messageVersion: String?
  let transaction: SuiTxDataTransaction?
  let gasData: GasData?
}

struct GasData: Codable {
  let price: String?
  let budget: String?
  let owner: String?
  let payment: AnyCodable?
}

struct SuiTxDataTransaction: Codable {
  let inputs: [SuiTxInput]?
  let transactions: AnyCodable?
  let kind: String?
}

struct SuiTxInput: Codable {
  let value: String?
  let valueType: String?
  let type: String?
}
