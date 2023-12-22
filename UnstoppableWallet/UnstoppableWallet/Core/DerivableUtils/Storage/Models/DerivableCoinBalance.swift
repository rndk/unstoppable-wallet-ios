import Foundation
import BigInt
import GRDB

class DerivableCoinBalance: Record {
  let walletId: String
  let blockchainId: String
  var balance: BigUInt
  
  init(walletId: String, blockchainId: String, balance: BigUInt) {
    self.walletId = walletId
    self.balance = balance
    self.blockchainId = blockchainId
    super.init()
  }
  
  override class var databaseTableName: String {
      return "derivableCoinBalance"
  }
  
  enum Columns: String, ColumnExpression {
      case walletId
      case balance
      case blockchainId
  }
  
  required init(row: Row) {
      walletId = row[Columns.walletId]
      balance = row[Columns.balance]
    blockchainId = row[Columns.blockchainId]

      super.init(row: row)
  }
  
  override func encode(to container: inout PersistenceContainer) {
      container[Columns.walletId] = walletId
      container[Columns.balance] = balance
      container[Columns.blockchainId] = blockchainId
  }
}
