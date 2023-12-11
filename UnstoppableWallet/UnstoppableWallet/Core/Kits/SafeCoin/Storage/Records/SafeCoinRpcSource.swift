import Foundation
import GRDB

class SafeCoinRpcSource: Record {
  public let name: String
  public let link: String
  public let address: String
  
  init(name: String, link: String, address: String) {
    self.name = name
    self.link = link
    self.address = address
    super.init()
  }
  
  override public class var databaseTableName: String {
    "safe_coin_rpc_sources"
  }
  
  enum Columns: String, ColumnExpression, CaseIterable {
    case name
    case link
    case address
  }
  
  required init(row: Row) {
    name = row[Columns.name]
    link = row[Columns.link]
    address = row[Columns.address]
    
    super.init(row: row)
  }
  
  override public func encode(to container: inout PersistenceContainer) {
    container[Columns.name] = name
    container[Columns.link] = link
    container[Columns.address] = address
  }
  
}
