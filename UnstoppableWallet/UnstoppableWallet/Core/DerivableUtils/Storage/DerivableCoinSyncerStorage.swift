import Foundation
import GRDB

class DerivableCoinSyncerStorage {
  private let dbPool: DatabasePool
  
  init(databaseDirectoryUrl: URL, databaseFileName: String) {
    let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")
    
    dbPool = try! DatabasePool(path: databaseURL.path)
    
    try! migrator.migrate(dbPool)
  }
  
  var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("createDerivableLastBlockHeight") { db in
      print(">>> DerivableCoinSyncerStorage register migration")
      try db.create(table: DerivableLastBlockHeight.databaseTableName, body: { t in
        t.column(DerivableLastBlockHeight.Columns.walletAddress.name, .text)
        t.column(DerivableLastBlockHeight.Columns.coinUid.name, .text)
        t.column(DerivableLastBlockHeight.Columns.height.name, .integer).notNull()
        t.primaryKey(
          [DerivableLastBlockHeight.Columns.walletAddress.name, DerivableLastBlockHeight.Columns.coinUid.name],
          onConflict: .replace
        )
      })
    }
    
    return migrator
  }
}

extension DerivableCoinSyncerStorage {
  
  func lastBlockHeight(address: String, coinUid: String) -> UInt64 {
    try! dbPool.read { db in
      try DerivableLastBlockHeight
        .filter(
          DerivableLastBlockHeight.Columns.coinUid == coinUid
          && DerivableLastBlockHeight.Columns.walletAddress == address
        )
        .fetchOne(db)?.height ?? 0
    }
  }
  
  func save(address: String, coinUid: String, blockHeight: UInt64) {
    try! dbPool.write { db in
      let record = DerivableLastBlockHeight(walletAddress: address, coinUid: coinUid, height: blockHeight)
      try record.insert(db)
    }
  }
  
}
