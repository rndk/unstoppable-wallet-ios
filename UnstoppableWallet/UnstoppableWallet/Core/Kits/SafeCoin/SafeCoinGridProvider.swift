import Foundation
import BigInt
import Alamofire
import HsToolKit

class SafeCoinGridProvider {
  
  private let baseUrl: String
  private let networkManager: NetworkManager
  private let apiClient: JSONRPCAPIClient
  private let blockchainClient: BlockchainClient
  private let safeCoinSigner: SafeCoinSigner
  
  private let headers: HTTPHeaders
  private var currentRpcId = 0
  private let pageLimit = 1000
  
  init(
    baseUrl: String,
    networkManager: NetworkManager,
    safeCoinSigner: SafeCoinSigner
  ) {
    self.baseUrl = baseUrl
    self.networkManager = networkManager
    self.safeCoinSigner = safeCoinSigner
    self.apiClient = JSONRPCAPIClient(endpoint: baseUrl)
    
    self.headers = HTTPHeaders()
    
    self.blockchainClient = BlockchainClient(
      apiClient: self.apiClient,
      systemProgrammId: SafeCoinTokenProgram.systemProgramId,
      tokenProgramId: SafeCoinTokenProgram.tokenProgramId,
      associatedProgramId: SafeCoinTokenProgram.splAssociatedTokenAccountProgramId,
      sysvarRent: SafeCoinTokenProgram.sysvarRent
    )
  }
  
}

extension SafeCoinGridProvider {
  
  public enum RequestError: Error {
    case invalidResponse
    case invalidStatus
    case failedToFetchAccountInfo
    case fullNodeApiError(code: String, message: String)
  }
  
}

extension SafeCoinGridProvider {
  
  var source: String {
    baseUrl
  }
  
  func getBalance(address: String) async throws -> UInt64 {
    return try await apiClient.getBalance(account: address)
  }
  
  func getSignaturesForAddress(
    address: String,
    until: String? = nil,
    before: String? = nil,
    limit: Int? = nil
  ) async throws -> [DerivableSignatureInfo] {
    let requestConfiguration = RequestConfiguration(limit: limit, before: before, until: until)
    return try await apiClient.getSignaturesForAddress(address: address, configs: requestConfiguration)
  }
  
  func safeTransfers(address: String) async throws -> [SafeCoinTransaction] {
    let signaturesInfos = try await apiClient.getSignaturesForAddress(address: address)
    var result: [SafeCoinTransaction] = []
    for signatureInfo in signaturesInfos {
      let transactionResponse = try await apiClient.getTransaction(transactionSignature: signatureInfo.signature)
      
      let transferInfo = transactionResponse.transaction.message.instructions.first?.parsed?.info
      let amount = transferInfo?.lamports ?? UInt64(transferInfo?.amount ?? "0")
      
      let transaction = SafeCoinTransaction(
        hash: signatureInfo.signature,
        currentAddress: address,
        blockTime: signatureInfo.blockTime ?? 0,
        from: transferInfo?.source ?? "",
        to: transferInfo?.destination ?? "",
        value: amount ?? 0,
        fee: transactionResponse.meta?.fee ?? 0,
        isFailed: false
      )
      result.append(transaction)
    }
    return result
  }
  
  func splTransfers(address: String) async throws -> [SafeCoinTransaction] {
    var result: [SafeCoinTransaction] = []
    let tokenAccounts = try await getTokenAccountsByOwnerStrings(address: address)
    if tokenAccounts.isEmpty {
      return result
    }
    let signaturesInfo = try await apiClient.getSignaturesForAddress(address: address)
    for signatureInfo in signaturesInfo {
      let transactionResponse = try await apiClient.getTransaction(transactionSignature: signatureInfo.signature)
      
//      let transferInfo = transactionResponse.transaction.message.instructions.first?.parsed?.info
//      let amount = transferInfo?.lamports ?? (UInt64(transferInfo?.amount ?? "0"))
      
      let transaction = SafeCoinTransaction(
        hash: signatureInfo.signature,
        currentAddress: address,
        blockTime: signatureInfo.blockTime ?? 0,
        from: "",
        to: "",
        value: 0,
        fee: transactionResponse.meta?.fee ?? 0,
        isFailed: false
      ) //TODO тут в андроиде есть tokenAccountAddress, mintAccountAddress и splBalanceChange - надо ли оно тут?
      result.append(transaction)
    }
    return result
  }
  
  func getTokenAccountsByOwner(address: String) async throws -> [String] {
    let infoParams = OwnerInfoParams(
      mint: nil,
      programId: SafeCoinTokenProgram.tokenProgramId.base58EncodedString
    )
    let accounts = try await apiClient.getTokenAccountsByOwner(
      pubkey: address,
      params: infoParams
    )
    var result: [String] = []
    for acc in accounts {
      result.append(acc.account.data.mint.base58EncodedString) //TODO to base58?
    }
    return result
  }
  
  func getTokenAccountsByOwnerStrings(address: String) async throws -> [String] {
    let infoParams = OwnerInfoParams(
      mint: nil,
      programId: SafeCoinTokenProgram.tokenProgramId.base58EncodedString
    )
    let accounts = try await apiClient.getTokenAccountsByOwner(
      pubkey: address,
      params: infoParams
    )
    var result: [String] = []
    for acc in accounts {
      result.append(acc.pubkey)
    }
    return result
  }
  
  func estimateFee(to: String, amount: UInt64) async throws -> DerivablePreparedTransaction {
    let preparedTransaction = try await blockchainClient.prepareSendingNative(
      from: safeCoinSigner.addressKeyPair(),
      to: to,
      amount: amount
    )
    print(">>> SafeCoinGripProvider estimeteFee: \(preparedTransaction)")
    return preparedTransaction
  }
  
  func sendTransaction(transaction: String) async throws -> TransactionID {
    try await apiClient.sendTransaction(transaction: transaction)
  }
  
  func sendTransaction(transaction: DerivablePreparedTransaction) async throws -> String {
    try await blockchainClient.sendTransaction(preparedTransaction: transaction)
  }
  
}
