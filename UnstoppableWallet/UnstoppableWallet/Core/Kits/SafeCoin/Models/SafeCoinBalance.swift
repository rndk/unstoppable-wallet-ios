import Foundation
import BigInt
import GRDB

class SafeCoinBalance: Record {
  let walletId: String
  var balance: BigUInt
  
  init(walletId: String, balance: BigUInt) {
    self.walletId = walletId
    self.balance = balance
    super.init()
  }
  
  override class var databaseTableName: String {
      return "safeCoinBalance"
  }
  
  enum Columns: String, ColumnExpression {
      case walletId
      case balance
  }
  
  required init(row: Row) {
      walletId = row[Columns.walletId]
      balance = row[Columns.balance]

      super.init(row: row)
  }
  
  override func encode(to container: inout PersistenceContainer) {
      container[Columns.walletId] = walletId
      container[Columns.balance] = balance
  }
}

//extension BigUInt: DatabaseValueConvertible {
//
//    public var databaseValue: DatabaseValue {
//        description.databaseValue
//    }
//
//    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BigUInt? {
//        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
//            return BigUInt(value)
//        }
//
//        return nil
//    }
//
//}
