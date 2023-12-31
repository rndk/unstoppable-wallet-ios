import Foundation

public struct SuiApiDryRun: Codable {
  let id: Int?
  let result: SuiWrappedTxBytes?
  let jsonrpc: String?
}

public struct SuiWrappedTxBytes: Codable {
  let txBytes: String
  let gas: [SuiObjectRef]
  let inputObjects: [ImmOrOwnedMoveObject]
}

struct SuiObjectRef: Codable {
  let objectId: String
  let version: Int
  let digest: String
}

struct ImmOrOwnedMoveObject: Codable {
  let immOrOwnedMoveObject: SuiObjectRef
  
  enum CodingKeys: String, CodingKey {
    case immOrOwnedMoveObject = "ImmOrOwnedMoveObject"
  }
}
