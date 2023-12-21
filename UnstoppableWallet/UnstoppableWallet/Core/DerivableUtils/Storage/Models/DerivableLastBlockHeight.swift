import Foundation
import GRDB

class DerivableLastBlockHeight: Record {
  
  public let walletAddress: String
  public let coinUid: String
  public let height: UInt64
  
  init(walletAddress: String, coinUid: String, height: UInt64) {
    self.walletAddress = walletAddress;
    self.coinUid = coinUid;
    self.height = height;
    super.init()
  }
  
  override class var databaseTableName: String {
    return "derivable_last_block_height"
  }
  
  enum Columns: String, ColumnExpression {
    case walletAddress
    case coinUid
    case height
  }
  
  required init(row: Row) {
    walletAddress = row[Columns.walletAddress]
    coinUid = row[Columns.coinUid]
    height = row[Columns.height]
    
    super.init(row: row)
  }
  
  override func encode(to container: inout PersistenceContainer) {
    container[Columns.walletAddress] = walletAddress
    container[Columns.coinUid] = coinUid
    container[Columns.height] = height
  }
  
}
