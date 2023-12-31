import Foundation
import GRDB

class DerivableSyncSourceStorage {
  private let dbPool: DatabasePool
  
  init(dbPool: DatabasePool) {
    self.dbPool = dbPool
    
    try! migrator.migrate(dbPool)
  }
  
  var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("Create Derivable Rpc Sources") { db in
      try db.create(table: DerivableRpcSource.databaseTableName) { t in
        t.column(DerivableRpcSource.Columns.blockchainUid.name, .text).notNull()
        t.column(DerivableRpcSource.Columns.link.name, .text).notNull()
        t.column(DerivableRpcSource.Columns.name.name, .text).notNull()
        t.column(DerivableRpcSource.Columns.createdAt.name, .integer).notNull()
        t.primaryKey(
          [
            DerivableRpcSource.Columns.link.name,
            DerivableRpcSource.Columns.blockchainUid.name
          ],
          onConflict: .replace
        )
      }
    }
    
    return migrator
  }
}

extension DerivableSyncSourceStorage {
  
  func get(blockchainUid: String) -> [DerivableRpcSource] {
    try! dbPool.read { db in
      try DerivableRpcSource
        .filter(DerivableRpcSource.Columns.blockchainUid == blockchainUid)
        .order(DerivableRpcSource.Columns.createdAt.asc)
        .fetchAll(db)
    }
  }
  
  func delete(blockchainUid: String, link: String) throws {
    _ = try dbPool.write { db in
      try DerivableRpcSource
        .filter(
          DerivableRpcSource.Columns.blockchainUid == blockchainUid
          && DerivableRpcSource.Columns.link == link
        )
        .deleteAll(db)
    }
  }
  
  func save(record: DerivableRpcSource) throws {
    _ = try dbPool.write { db in
        try record.insert(db)
    }
  }
  
}
