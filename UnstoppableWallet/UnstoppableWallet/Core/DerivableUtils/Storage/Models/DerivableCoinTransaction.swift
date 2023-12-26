import Foundation
import GRDB

public class DerivableCoinTransaction: Record {
  public let rpcSourceUrl: String
  public let blockchainUid: String
  public let hash: String
  public let currentAddress: String
  public let blockTime: UInt64
  public let from: String
  public let to: String
  public let value: UInt64
  public let fee: UInt64
  public let isFailed: Bool
  
  init(
    rpcSourceUrl: String,
    blockchainUid: String,
    hash: String,
    currentAddress: String,
    blockTime: UInt64,
    from: String,
    to: String,
    value: UInt64,
    fee: UInt64,
    isFailed: Bool
  ) {
    self.rpcSourceUrl = rpcSourceUrl
    self.blockchainUid = blockchainUid
    self.hash = hash
    self.currentAddress = currentAddress
    self.blockTime = blockTime
    self.from = from
    self.to = to
    self.value = value
    self.fee = fee
    self.isFailed = isFailed
    
    super.init()
  }
  
  override public class var databaseTableName: String {
    "derivable_coin_transactions"
  }
  
  enum Columns: String, ColumnExpression, CaseIterable {
    case rpcSourceUrl
    case blockchainUid
    case hash
    case currentAddress
    case blockTime
    case from
    case to
    case value
    case fee
    case isFailed
  }
  
  required init(row: Row) {
    rpcSourceUrl = row[Columns.rpcSourceUrl]
    blockchainUid = row[Columns.blockchainUid]
    hash = row[Columns.hash]
    currentAddress = row[Columns.currentAddress]
    blockTime = row[Columns.blockTime]
    from = row[Columns.from]
    to = row[Columns.to]
    value = row[Columns.value]
    fee = row[Columns.fee]
    isFailed = row[Columns.isFailed]
    
    super.init(row: row)
  }
  
  override public func encode(to container: inout PersistenceContainer) {
    container[Columns.rpcSourceUrl] = rpcSourceUrl
    container[Columns.blockchainUid] = blockchainUid
    container[Columns.hash] = hash
    container[Columns.currentAddress] = currentAddress
    container[Columns.blockTime] = blockTime
    container[Columns.from] = from
    container[Columns.to] = to
    container[Columns.value] = value
    container[Columns.fee] = fee
    container[Columns.isFailed] = isFailed
  }
}
