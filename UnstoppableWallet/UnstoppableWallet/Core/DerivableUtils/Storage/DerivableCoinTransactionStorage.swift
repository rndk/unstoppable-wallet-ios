import Foundation
import GRDB

public class DerivableCoinTransactionStorage {
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
    
    migrator.registerMigration("Derivable Coin Transactioins") { db in
      print(">>> DerivableCoinTransactionStorage in migrator, register migrator -> Create Derivable Transactions")
      try db.create(table: DerivableCoinTransaction.databaseTableName) { t in
        t.column(DerivableCoinTransaction.Columns.rpcSourceUrl.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.blockchainUid.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.hash.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.currentAddress.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.blockTime.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.from.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.to.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.value.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.fee.name, .text).notNull()
        t.column(DerivableCoinTransaction.Columns.isFailed.name, .boolean).notNull()
        t.primaryKey(
          [
            DerivableCoinTransaction.Columns.rpcSourceUrl.name,
            DerivableCoinTransaction.Columns.blockchainUid.name,
            DerivableCoinTransaction.Columns.currentAddress.name,
            DerivableCoinTransaction.Columns.hash.name
          ],
          onConflict: .replace
        )
      }
    }
    
    return migrator
  }
}

extension DerivableCoinTransactionStorage {
  
  func lastTransaction(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String
  ) -> DerivableCoinTransaction? {
    try! dbPool.read { db in
      try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .order(DerivableCoinTransaction.Columns.blockTime.desc)
        .fetchOne(db)
    }
  }
  
  func allTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchAll(db)
    }
  }
  
  func incomingTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.to == address
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchAll(db)
    }
  }
  
  func outgoingTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.from == address
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchAll(db)
    }
  }
  
  func save(
    transactions: [DerivableCoinTransaction],
    replaceOnConflict: Bool
  ) {
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
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String,
    fromHash: String?,
    filter: TransactionTypeFilter,
    limit: Int?
  ) -> [DerivableCoinTransaction] {
    switch filter {
    case .all: return allTransactions(
      rpcSourceUrl: rpcSourceUrl,
      address: address,
      blockchainUid: blockchainUid
    )
    case .incoming: do {
      if fromHash != nil, limit != nil {
        return incomingTransactions(
          rpcSourceUrl: rpcSourceUrl,
          address: address,
          blockchainUid: blockchainUid,
          fromHash: fromHash!,
          limit: limit!
        )
      } else if fromHash != nil {
        return incomingTransactions(
          rpcSourceUrl: rpcSourceUrl,
          address: address,
          blockchainUid: blockchainUid,
          fromHash: fromHash!
        )
      } else {
        return incomingTransactions(
          rpcSourceUrl: rpcSourceUrl,
          address: address,
          blockchainUid: blockchainUid
        )
      }
    }
    case .outgoing: do {
      if fromHash != nil, limit != nil {
        return outgoingTransactions(
          rpcSourceUrl: rpcSourceUrl,
          address: address,
          blockchainUid: blockchainUid,
          fromHash: fromHash!,
          limit: limit!
        )
      } else if fromHash != nil {
        return outgoingTransactions(
          rpcSourceUrl: rpcSourceUrl,
          address: address,
          blockchainUid: blockchainUid,
          fromHash: fromHash!
        )
      } else {
        return outgoingTransactions(
          rpcSourceUrl: rpcSourceUrl,
          address: address,
          blockchainUid: blockchainUid
        )
      }
    }
    default: return allTransactions(
      rpcSourceUrl: rpcSourceUrl,
      address: address,
      blockchainUid: blockchainUid
    )
    }
  }
  
  private func incomingTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String,
    fromHash: String
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      
      let transaction = try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.to == address
          && DerivableCoinTransaction.Columns.hash == fromHash
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.to == address
          && DerivableCoinTransaction.Columns.blockTime > trans.blockTime
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchAll(db)
    }
  }
  
  private func incomingTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String,
    fromHash: String,
    limit: Int
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      
      let transaction = try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.to == address
          && DerivableCoinTransaction.Columns.hash == fromHash
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.to == address
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
          && DerivableCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .limit(limit)
        .fetchAll(db)
    }
  }
  
  private func outgoingTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String,
    fromHash: String
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      let transaction = try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.from == address
          && DerivableCoinTransaction.Columns.hash == fromHash
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.from == address
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
          && DerivableCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .fetchAll(db)
    }
  }
  
  private func outgoingTransactions(
    rpcSourceUrl: String,
    address: String,
    blockchainUid: String,
    fromHash: String,
    limit: Int
  ) -> [DerivableCoinTransaction] {
    try! dbPool.read { db in
      let transaction = try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.from == address
          && DerivableCoinTransaction.Columns.hash == fromHash
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
        )
        .fetchOne(db)
      
      guard let trans = transaction else {
        return []
      }
      
      return try DerivableCoinTransaction
        .filter(
          DerivableCoinTransaction.Columns.currentAddress == address
          && DerivableCoinTransaction.Columns.blockchainUid == blockchainUid
          && DerivableCoinTransaction.Columns.from == address
          && DerivableCoinTransaction.Columns.rpcSourceUrl == rpcSourceUrl
          && DerivableCoinTransaction.Columns.blockTime > trans.blockTime
        )
        .limit(limit)
        .fetchAll(db)
    }
  }
  
}
