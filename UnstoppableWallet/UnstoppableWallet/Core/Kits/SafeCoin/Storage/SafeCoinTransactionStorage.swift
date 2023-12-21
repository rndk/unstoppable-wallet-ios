import Foundation
import GRDB

class SafeCoinTransactionStorage {
  private let dbPool: DatabasePool
  
  init(databaseDirectoryUrl: URL, databaseFileName: String) {
    let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")
    
    dbPool = try! DatabasePool(path: databaseURL.path)
    
    try! migrator.migrate(dbPool)
  }
  
  var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("Create SafeCoin Transactioins") { db in
      print(">>> SafeCoinTransactionsStorage in migrator, register migrator -> Create SafeCoin Transactions")
      try db.create(table: SafeCoinTransaction.databaseTableName) { t in
        t.column(SafeCoinTransaction.Columns.hash.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.currentAddress.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.blockTime.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.from.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.to.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.value.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.fee.name, .text).notNull()
        t.column(SafeCoinTransaction.Columns.isFailed.name, .boolean).notNull()
        t.primaryKey(
          [SafeCoinTransaction.Columns.hash.name, SafeCoinTransaction.Columns.currentAddress.name],
          onConflict: .replace
        ) //TODO test
      }
    }
    
    return migrator
  }
}

extension SafeCoinTransactionStorage {
  
  func lastTransaction(address: String) -> SafeCoinTransaction? {
    try! dbPool.read { db in
      try SafeCoinTransaction
        .filter(SafeCoinTransaction.Columns.currentAddress == address)
        .order(SafeCoinTransaction.Columns.blockTime.desc)
        .fetchOne(db)
    }
  }
  
  func allTransactions(address: String) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      try SafeCoinTransaction
        .filter(SafeCoinTransaction.Columns.currentAddress == address)
        .fetchAll(db)
    }
  }
  
  func incomingTransactions(address: String) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.to == address
        ) //TODO test
        .fetchAll(db)
    }
  }
  
  func outgoingTransactions(address: String) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.from == address
        ) //TODO test
        .fetchAll(db)
    }
  }
  
  func save(transactions: [SafeCoinTransaction], replaceOnConflict: Bool) {
    try! dbPool.write { db in
      for transaction in transactions {
        if !replaceOnConflict, try transaction.exists(db) {
          continue
        }
        
        try transaction.save(db)
      }
    }
  }
  
  func transactions(
    address: String,
    coinUid: String,
    fromHash: String?,
    filter: TransactionTypeFilter,
    limit: Int?
  ) -> [SafeCoinTransaction] {
    switch filter {
    case .all: return allTransactions(address: address)
    case .incoming: do {
      if fromHash != nil, limit != nil {
        return incomingTransactions(address: address, fromHash: fromHash!, limit: limit!)
      } else if fromHash != nil {
        return incomingTransactions(address: address, fromHash: fromHash!)
      } else {
        return incomingTransactions(address: address)
      }
    }
    case .outgoing: do {
      if fromHash != nil, limit != nil {
        return outgoingTransactions(address: address, fromHash: fromHash!, limit: limit!)
      } else if fromHash != nil {
        return outgoingTransactions(address: address, fromHash: fromHash!)
      } else {
        return outgoingTransactions(address: address)
      }
    }
    default: return allTransactions(address: address)
    }
  }
  
  private func incomingTransactions(address: String, fromHash: String) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      
      let transaction = try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.to == address
          && SafeCoinTransaction.Columns.hash == fromHash
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.to == address
          && SafeCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .fetchAll(db)
    }
  }
  
  private func incomingTransactions(address: String, fromHash: String, limit: Int) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      
      let transaction = try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.to == address
          && SafeCoinTransaction.Columns.hash == fromHash
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.to == address
          && SafeCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .limit(limit)
        .fetchAll(db)
    }
  }
  
  private func outgoingTransactions(address: String, fromHash: String) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      let transaction = try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.from == address
          && SafeCoinTransaction.Columns.hash == fromHash
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.from == address
          && SafeCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .fetchAll(db)
    }
  }
  
  private func outgoingTransactions(address: String, fromHash: String, limit: Int) -> [SafeCoinTransaction] {
    try! dbPool.read { db in
      let transaction = try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.from == address
          && SafeCoinTransaction.Columns.hash == fromHash
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try SafeCoinTransaction
        .filter(
          SafeCoinTransaction.Columns.currentAddress == address
          && SafeCoinTransaction.Columns.from == address
          && SafeCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .limit(limit)
        .fetchAll(db)
    }
  }
  
}
