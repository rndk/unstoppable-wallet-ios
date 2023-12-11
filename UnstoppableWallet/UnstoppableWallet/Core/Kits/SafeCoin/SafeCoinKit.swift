import Foundation
import HsToolKit
import BigInt
import Combine

public class SafeCoinKit {
  private let syncer: SafeCoinSyncer
  private let accountInfoManager: SafeCoinAccountInfoManager
  private let transactionManager: SafeCoinTransactionManager
  private let transactionSender: SafeCoinTransactionSender
  private let feeProvider: SafeCoinFeeProvider
  private let rpcSourceStorage: SafeCoinRpcSourceStorage
  
  public let address: String
  public let network: SafeCoinNetwork
  
  
  init(
    address: String,
    network: SafeCoinNetwork,
    syncer: SafeCoinSyncer,
    accountInfoManager: SafeCoinAccountInfoManager,
    transactionManager: SafeCoinTransactionManager,
    transactionSender: SafeCoinTransactionSender,
    feeProvider: SafeCoinFeeProvider,
    rpcSourceStorage: SafeCoinRpcSourceStorage
  ) {
    self.address = address
    self.network = network
    self.accountInfoManager = accountInfoManager
    self.transactionManager = transactionManager
    self.transactionSender = transactionSender
    self.syncer = syncer
    self.feeProvider = feeProvider
    self.rpcSourceStorage = rpcSourceStorage
  }
}

extension SafeCoinKit {
  
  //    public var lastBlockHeight: Int? {
  //        syncer.lastBlockHeight
  //    }
  
  public var syncState: SafeCoinSyncState {
    syncer.state
  }
  
  //    public var accountActive: Bool {
  //        accountInfoManager.accountActive
  //    }
  
  public var receiveAddress: String {
    self.address
  }
  
  //    public var lastBlockHeightPublisher: AnyPublisher<Int, Never> {
  //        syncer.$lastBlockHeight.eraseToAnyPublisher()
  //    }
  
  public var syncStatePublisher: AnyPublisher<SafeCoinSyncState, Never> {
    syncer.$state.eraseToAnyPublisher()
  }
  
  public var balancePublisher: AnyPublisher<BigUInt, Never> {
    accountInfoManager.balancePublisher
  }
  
  public var allTransactionsPublisher: AnyPublisher<[SafeCoinTransaction], Never> {
    transactionManager.transactionsPublisher
  }
  
  public func balance(contractAddress: String) -> BigUInt {
    accountInfoManager.balance(contractAddress: contractAddress)
  }
  
  public func balancePublisher(contractAddress: String) -> AnyPublisher<BigUInt, Never> {
    accountInfoManager.balancePublisher/*(contractAddress: contractAddress)*/
  }
  
  //    public func transactions(tagQueries: [TransactionTagQuery], fromHash: Data? = nil, limit: Int? = nil) -> [FullTransaction] {
  //        transactionManager.fullTransactions(tagQueries: tagQueries, fromHash: fromHash, limit: limit)
  //    }
  
  public func estimateFee(to: String, sendAmount: BigUInt) async throws -> BigUInt {
    try await feeProvider.estimateFee(
      to: to,
      sendAmount: sendAmount,
      currentAmount: accountInfoManager.safeCoinBalance
    )
  }
  
  //    public func transferContract(toAddress: Address, value: Int) -> TransferContract {
  //        TransferContract(amount: value, ownerAddress: address, toAddress: toAddress)
  //    }
  
  //    public func transferTrc20TriggerSmartContract(contractAddress: Address, toAddress: Address, amount: BigUInt) -> TriggerSmartContract {
  //        let transferMethod = TransferMethod(to: toAddress, value: amount)
  //        let data = transferMethod.encodedABI().hs.hex
  //        let parameter = ContractMethodHelper.encodedABI(methodId: Data(), arguments: transferMethod.arguments).hs.hex
  //
  //        return TriggerSmartContract(
  //            data: data,
  //            ownerAddress: address,
  //            contractAddress: contractAddress,
  //            callValue: nil,
  //            callTokenValue: nil,
  //            tokenId: nil,
  //            functionSelector: TransferMethod.methodSignature,
  //            parameter: parameter
  //        )
  //    }
  
  //    public func send(contract: Contract, signer: Signer, feeLimit: Int? = 0) async throws  {
  //        let newTransaction = try await transactionSender.sendTransaction(contract: contract, signer: signer, feeLimit: feeLimit)
  //        transactionManager.handle(newTransaction: newTransaction)
  //    }
  public func send(address: String, amount: BigUInt) async throws {
    let fee = try await estimateFee(to: address, sendAmount: amount)
    let newTransaction = try await transactionSender.sendTransaction(to: address, amount: amount, fee: fee)
    transactionManager.handle(/*newTransaction: newTransaction*/)
  }
  
  //    public func accountActive(address: Address) async throws -> Bool {
  //        try await feeProvider.isAccountActive(address: address)
  //    }
  
  public func start() {
    syncer.start()
  }
  
  public func stop() {
    syncer.stop()
  }
  
  public func refresh() {
    syncer.refresh()
  }
  
  //    public func fetchTransaction(hash: Data) async throws -> FullTransaction {
  //        throw SyncError.notStarted
  //    }
}

extension SafeCoinKit {
  
  //    public static func clear(exceptFor excludedFiles: [String]) throws {
  //        let fileManager = FileManager.default
  //        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)
  //
  //        for filename in fileUrls {
  //            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
  //                try fileManager.removeItem(at: filename)
  //            }
  //        }
  //    }
  
  public static func instance(
    address: String,
    network: SafeCoinNetwork,
    walletId: String,
    logger: Logger = Logger(minLogLevel: .error)
  ) throws -> SafeCoinKit {
    let databaseDirectoryUrl = try dataDirectoryUrl()
    
    let accountInfoStorage = SafeCoinAccountInfoStorage(
      databaseDirectoryUrl: databaseDirectoryUrl,
      databaseFileName: "safe-coinaccount-info-storage"
    )
    let transactionStorage = SafeCoinTransactionStorage(
      databaseDirectoryUrl: databaseDirectoryUrl,
      databaseFileName: "safe-coin-transactions-storage"
    )
    let rpcSourceStorage = SafeCoinRpcSourceStorage(
      databaseDirectoryUrl: databaseDirectoryUrl,
      databaseFileName: "safe-coin-rpc-sources-storage"
    )
    
    let accountInfoManager = SafeCoinAccountInfoManager(storage: accountInfoStorage, address: address)
    let transactionManager = SafeCoinTransactionManager(userAddress: address, storage: transactionStorage)
    
    let networkManager = NetworkManager(logger: logger)
    
    let tronGridProvider = SafeCoinGridProvider(baseUrl: provideUrl(network: network), networkManager: networkManager)
    let feeProvider = SafeCoinFeeProvider(safeCoinGridProvider: tronGridProvider)
    
    let syncer = SafeCoinSyncer(
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      safeCoinGridProvider: tronGridProvider,
      address: address
    )
    let transactionSender = SafeCoinTransactionSender(safeCoinGridProvider: tronGridProvider)
    
    let kit = SafeCoinKit(
      address: address,
      network: network,
      syncer: syncer,
      accountInfoManager: accountInfoManager,
      transactionManager: transactionManager,
      transactionSender: transactionSender,
      feeProvider: feeProvider,
      rpcSourceStorage: rpcSourceStorage
    )
    
    return kit
  }
  
  //    public static func call(networkManager: NetworkManager, network: Network, contractAddress: Address, data: Data, apiKey: String?) async throws -> Data {
  //        let tronGridProvider = TronGridProvider(networkManager: networkManager, baseUrl: providerUrl(network: network), apiKey: apiKey)
  //        let rpc = CallJsonRpc(contractAddress: contractAddress, data: data)
  //
  //        return try await tronGridProvider.fetch(rpc: rpc)
  //    }
  
  private static func dataDirectoryUrl() throws -> URL {
    let fileManager = FileManager.default
    
    let url = try fileManager
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("safe-coin-kit", isDirectory: true)
    
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    
    return url
  }
  
  private static func provideUrl(network: SafeCoinNetwork) -> String {
    switch network {
    case .mainNet: return "https://api.mainnet-beta.safecoin.org/"
    case .testNet: return "https://api.testnet.safecoin.org/"
    case .devNet: return "https://devnet.safely.org/"
    case .custom(_, let url): return url
    }
  }
  
}

extension SafeCoinKit {
  
  public enum SyncError: Error {
    case notStarted
    case noNetworkConnection
  }
  
  public enum SendError: Error {
    case notSupportedContract
    case abnormalSend
    case invalidParameter
  }
  
}
