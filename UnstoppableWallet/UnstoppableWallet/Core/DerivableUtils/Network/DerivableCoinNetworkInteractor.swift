import Foundation
import BigInt
import Alamofire
import HsToolKit

class DerivableCoinNetworkInteractor {
  private var baseUrl: String
  private var blockchainUid: String
  private let networkManager: NetworkManager
  private let signer: DerivableCoinSigner
  
  private let systemProgramId: PublicKey
  private let tokenProgramId: PublicKey
  private let associatedProgramId: PublicKey
  private let sysvarRent: PublicKey
  
  private let apiClient: JSONRPCAPIClient
  private let blockchainClient: BlockchainClient
  
  private var currentRpcId = 0
  private let pageLimit = 1000
  
  init(
    baseUrl: String,
    blockchainUid: String,
    networkManager: NetworkManager,
    signer: DerivableCoinSigner,
    systemProframId: PublicKey,
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    sysvarRent: PublicKey
  ) {
    self.baseUrl = baseUrl
    self.blockchainUid = blockchainUid
    self.networkManager = networkManager
    self.signer = signer
    self.apiClient = JSONRPCAPIClient(endpoint: baseUrl)
    
    self.systemProgramId = systemProframId
    self.tokenProgramId = tokenProgramId
    self.associatedProgramId = associatedProgramId
    self.sysvarRent = sysvarRent
    
//    self.headers = HTTPHeaders()
    
//    self.blockchainClient = BlockchainClient(
//      apiClient: self.apiClient,
//      systemProgrammId: SafeCoinTokenProgram.systemProgramId,
//      tokenProgramId: SafeCoinTokenProgram.tokenProgramId,
//      associatedProgramId: SafeCoinTokenProgram.splAssociatedTokenAccountProgramId,
//      sysvarRent: SafeCoinTokenProgram.sysvarRent
//    )
    
    self.blockchainClient = BlockchainClient(
      apiClient: self.apiClient,
      systemProgrammId: self.systemProgramId,
      tokenProgramId: self.tokenProgramId,
      associatedProgramId: self.associatedProgramId,
      sysvarRent: self.sysvarRent
    )
  }
  
}

extension DerivableCoinNetworkInteractor {
  
  public enum RequestError: Error {
    case invalidResponse
    case invalidStatus
    case failedToFetchAccountInfo
    case fullNodeApiError(code: String, message: String)
  }
  
}

extension DerivableCoinNetworkInteractor {
  
  func updateBaseUrl(newSourceUrl: String) {
    self.baseUrl = newSourceUrl
    self.apiClient.updateEndpoint(newEndpoint: newSourceUrl)
  }
  
  var source: String {
    baseUrl
  }
  
  func getBalance(address: String) async throws -> UInt64 {
    return try await apiClient.getBalance(account: address)
  }
  
  func getLastBlockHeight() async throws -> UInt64 {
    try await apiClient.getBlockHeight()
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
  
  func safeTransfers(address: String) async throws -> [DerivableCoinTransaction] {
    print(">>> SafeCoinGridProvider safeTransfers address: \(address)")
    let signaturesInfos = try await apiClient.getSignaturesForAddress(
      address: address, configs: RequestConfiguration(limit: pageLimit)
    )
    var result: [DerivableCoinTransaction] = []
    for signatureInfo in signaturesInfos {
      let transactionResponse = try await apiClient.getTransaction(transactionSignature: signatureInfo.signature)
      
      let transferInfo = transactionResponse.transaction.message.instructions.first?.parsed?.info
      let amount = transferInfo?.lamports ?? UInt64(transferInfo?.amount ?? "0")
      
      let transaction = DerivableCoinTransaction(
        blockchainUid: self.blockchainUid,
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
  
  func splTransfers(address: String) async throws -> [DerivableCoinTransaction] {
    var result: [DerivableCoinTransaction] = []
    let tokenAccounts = try await getTokenAccountsByOwnerStrings(address: address)
    if tokenAccounts.isEmpty {
      return result
    }
    let signaturesInfo = try await apiClient.getSignaturesForAddress(address: address)
    for signatureInfo in signaturesInfo {
      let transactionResponse = try await apiClient.getTransaction(transactionSignature: signatureInfo.signature)
      
//      let transferInfo = transactionResponse.transaction.message.instructions.first?.parsed?.info
//      let amount = transferInfo?.lamports ?? (UInt64(transferInfo?.amount ?? "0"))
      
      let transaction = DerivableCoinTransaction(
        blockchainUid: self.blockchainUid,
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
//      programId: SafeCoinTokenProgram.tokenProgramId.base58EncodedString
      programId: tokenProgramId.base58EncodedString
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
//      programId: SafeCoinTokenProgram.tokenProgramId.base58EncodedString
      programId: tokenProgramId.base58EncodedString
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
  
  func prepareTransaction(to: String, amount: UInt64) async throws -> DerivablePreparedTransaction {
    let preparedTransaction = try await blockchainClient.prepareSendingNative(
      from: signer.addressKeyPair(),
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
  
  func calcMinRent() async throws -> BigUInt {
    return BigUInt(try await apiClient.getMinimumBalanceForRentExemption(span: 165))
  }
  
}
