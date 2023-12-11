import Foundation
import GRDB
import BigInt

class SafeCoinAccountInfoStorage {
  private let dbPool: DatabasePool

  init(databaseDirectoryUrl: URL, databaseFileName: String) {
      let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

      dbPool = try! DatabasePool(path: databaseURL.path)

      try! migrator.migrate(dbPool)
  }

  var migrator: DatabaseMigrator {
      var migrator = DatabaseMigrator()

      migrator.registerMigration("createSafeCoinBalances") { db in
          try db.create(table: SafeCoinBalance.databaseTableName, body: { t in
              t.column(SafeCoinBalance.Columns.walletId.name, .text).notNull().primaryKey(onConflict: .replace)
              t.column(SafeCoinBalance.Columns.balance.name, .text).notNull()
          })
      }

      return migrator
  }
}

extension SafeCoinAccountInfoStorage {
  
  func balance(address: String) -> BigUInt? {
      try! dbPool.read { db in
          try SafeCoinBalance.filter(SafeCoinBalance.Columns.walletId == address).fetchOne(db)?.balance
      }
  }
  
  func save(balance: BigUInt, address: String) {
      _ = try! dbPool.write { db in
          let balance = SafeCoinBalance(walletId: address, balance: balance)
          try balance.insert(db)
      }
  }
  
}
