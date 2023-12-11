import Foundation
import GRDB

class SafeCoinRpcSourceStorage {
  private let dbPool: DatabasePool
  
  init(databaseDirectoryUrl: URL, databaseFileName: String) {
    let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")
    
    dbPool = try! DatabasePool(path: databaseURL.path)
    
    try! migrator.migrate(dbPool)
  }
  
  var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("Create SafeCoin Rpc Sources") { db in
      try db.create(table: SafeCoinRpcSource.databaseTableName) { t in
        t.column(SafeCoinRpcSource.Columns.link.name, .text).notNull()
        t.column(SafeCoinRpcSource.Columns.name.name, .text).notNull()
        t.column(SafeCoinRpcSource.Columns.address.name, .text).notNull()
        t.primaryKey(
          [SafeCoinRpcSource.Columns.link.name, SafeCoinRpcSource.Columns.address.name],
          onConflict: .replace
        )
      }
    }
    
    return migrator
  }
}

extension SafeCoinRpcSourceStorage {
  //TODO сохранять сорцы + если выбрал какой-то, то тоже надо сохранять что он выбран, а остальные снимать что выбран
}
