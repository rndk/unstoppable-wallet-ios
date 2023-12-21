import Foundation
import GRDB

class DerivableRpcSource: Record {
  public let blockchainUid: String
  public let name: String
  public let link: String
  public let createdAt: UInt64
  
  init(blockchainUid: String, name: String, link: String, createdAt: UInt64) {
    self.blockchainUid = blockchainUid
    self.name = name
    self.link = link
    self.createdAt = createdAt
    super.init()
  }
  
  override public class var databaseTableName: String {
    "derivable_rpc_sources"
  }
  
  enum Columns: String, ColumnExpression, CaseIterable {
    case blockchainUid
    case name
    case link
    case createdAt
  }
  
  required init(row: Row) {
    name = row[Columns.name]
    blockchainUid = row[Columns.blockchainUid]
    link = row[Columns.link]
    createdAt = row[Columns.createdAt]
    
    super.init(row: row)
  }
  
  override public func encode(to container: inout PersistenceContainer) {
    container[Columns.blockchainUid] = blockchainUid
    container[Columns.name] = name
    container[Columns.link] = link
    container[Columns.createdAt] = createdAt
  }
  
}

extension DerivableRpcSource: Equatable {
  static func ==(lhs: DerivableRpcSource, rhs: DerivableRpcSource) -> Bool {
    lhs.link == rhs.link && lhs.blockchainUid == rhs.blockchainUid
  }
}
