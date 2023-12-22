import Foundation
import GRDB
import BigInt

public class DerivableCoinAccountInfoStorage {
  private let dbPool: DatabasePool
  
  init (dbPool: DatabasePool) {
    self.dbPool = dbPool
    
    try! migrator.migrate(dbPool)
  }
  
  init(databaseDirectoryUrl: URL, databaseFileName: String) {
    let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")
    
    dbPool = try! DatabasePool(path: databaseURL.path)
    
    try! migrator.migrate(dbPool)
  }
  
  var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("Derivable Coin Balances") { db in
      try db.create(table: DerivableCoinBalance.databaseTableName, body: { t in
        t.column(DerivableCoinBalance.Columns.walletId.name, .text).notNull()
        t.column(DerivableCoinBalance.Columns.balance.name, .text).notNull()
        t.column(DerivableCoinBalance.Columns.blockchainId.name, .text).notNull()
        t.primaryKey(
          [DerivableCoinBalance.Columns.walletId.name, DerivableCoinBalance.Columns.blockchainId.name],
          onConflict: .replace
        )
      })
    }
    
    return migrator
  }
}

extension DerivableCoinAccountInfoStorage {
  
  func balance(address: String, blockchainUid: String) -> BigUInt? {
    try! dbPool.read { db in
      try DerivableCoinBalance
        .filter(
          DerivableCoinBalance.Columns.walletId == address
          && DerivableCoinBalance.Columns.blockchainId == blockchainUid
        )
        .fetchOne(db)?.balance
    }
  }
  
  func save(balance: BigUInt, address: String, blockchainUid: String) {
    _ = try! dbPool.write { db in
      let balance = DerivableCoinBalance(walletId: address, blockchainId: blockchainUid, balance: balance)
      try balance.insert(db)
    }
  }
  
}
