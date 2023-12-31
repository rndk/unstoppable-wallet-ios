import Foundation
import Commons

struct SuiOwnedObjectsResponse: Codable {
    let id: Int?
    let result: SuiObjectResult?
    let jsonrpc: String?
}

struct SuiObjectResult: Codable {
    let nextCursor: String?
    let hasNextPage: Bool?
    let data: [SuiObjectData]?
}

struct SuiObjectData: Codable {
  let data: SuiObjectInfo?
}

struct SuiObjectInfo: Codable {
  let objectId: String?
  let version: String?
  let digest: String?
  let type: String?
  let display: SuiObjectDisplay?
  let content: SuiObjectContent?
  let owner: SuiObjectOwner?
  let previousTransaction: String?
}

struct SuiObjectContent: Codable {
  let type: String?
  let fields: SuiObjectField?
}

struct SuiObjectField: Codable {
  let balance: String?
}

struct SuiObjectOwner: Codable {
  let addressOwner: String?
  
  enum CodingKeys: String, CodingKey {
    case addressOwner = "AddressOwner"
  }
}

struct SuiObjectDisplay: Codable {
  let data: SuiDisplayInfo?
}

struct SuiDisplayInfo: Codable {
  let description: String?
  let kiosk: String?
  let image_url: String?
  let link: String?
  let name: String?
  let owner: String?
}
