import Foundation

/// JSON RPC
public class JSONRPCAPIClient: DerivationApiClient {
  public typealias ResponseDecoder = JSONRPCResponseDecoder
  public typealias RequestEncoder = JSONRPCRequestEncoder
  
  // MARK: -
  
  public var endpoint: String
  private let networkManager: DerivationNetworkManager
  
  public init(
    endpoint: String,
    networkManager: DerivationNetworkManager = URLSession(configuration: .default)
  ) {
    self.endpoint = endpoint
    self.networkManager = networkManager
  }
  
  func updateEndpoint(newEndpoint: String) {
    self.endpoint = newEndpoint
  }
  
  // MARK: -
  
  public func getTransaction(
    signature: String,
    commitment: Commitment?
  ) async throws -> DerivableTransactionInfo? {
    try await get(
      method: "getTransaction",
      params: [signature, RequestConfiguration(commitment: commitment, encoding: "jsonParsed")]
    )
  }
  
  public func getAccountInfo<T: BufferLayout>(account: String) async throws -> BufferInfo<T>? {
    do {
      let response: DerivableRpc<BufferInfo<T>?> = try await get(method: "getAccountInfo", params: [
        account,
        RequestConfiguration(encoding: "base64"),
      ])
      return response.value
    } catch is BinaryReaderError {
      throw APIClientError.couldNotRetrieveAccountInfo
    } catch APIClientError.invalidResponse {
      throw APIClientError.couldNotRetrieveAccountInfo
    } catch {
      throw error
    }
  }
  
  public func getBlockHeight() async throws -> UInt64 {
    try await get(method: "getBlockHeight", params: [])
  }
  
  public func getConfirmedBlocksWithLimit(
    startSlot: UInt64,
    limit: UInt64
  ) async throws -> [UInt64] {
    try await get(
      method: "getConfirmedBlocksWithLimit",
      params: [startSlot, limit]
    )
  }
  
  public func getBalance(
    account: String,
    commitment: Commitment? = nil
  ) async throws -> UInt64 {
    let response: DerivableRpc<UInt64> = try await get(method: "getBalance", params: [
      account,
      RequestConfiguration(commitment: commitment),
    ])
    return response.value
  }
  
  public func getBlockCommitment(
    block: UInt64
  ) async throws -> DerivableBlockCommitment {
    try await get(method: "getBlockCommitment", params: [block])
  }
  
  public func getBlockTime(
    block: UInt64
  ) async throws -> Date {
    let response: Double = try await get(
      method: "getBlockTime",
      params: [block]
    )
    return Date(timeIntervalSince1970: TimeInterval(response))
  }
  
  public func getClusterNodes() async throws -> [DerivableClusterNodes] {
    try await get(method: "getClusterNodes", params: [])
  }
  
  public func getConfirmedBlock(
    slot: UInt64,
    encoding: String
  ) async throws -> DerivableConfirmedBlock {
    try await get(
      method: "getConfirmedBlock",
      params: [slot, encoding]
    )
  }
  
  public func getConfirmedSignaturesForAddress(
    account: String, startSlot: UInt64,
    endSlot: UInt64
  ) async throws -> [String] {
    try await get(
      method: "getConfirmedSignaturesForAddress",
      params: [account, startSlot, endSlot]
    )
  }
  
  public func getTransaction(
    transactionSignature: String
  ) async throws -> DerivableTransactionInfo {
    try await get(
      method: "getTransaction",
      params: [transactionSignature, "jsonParsed"]
    )
  }
  
  public func getEpochInfo(
    commitment: Commitment? = nil
  ) async throws -> DerivableEpochInfo {
    try await get(
      method: "getEpochInfo",
      params: [RequestConfiguration(commitment: commitment)]
    )
  }
  
  public func getFees(
    commitment: Commitment? = nil
  ) async throws -> DerivableFee {
    let result: DerivableRpc<DerivableFee> = try await get(
      method: "getFees",
      params: [RequestConfiguration(commitment: commitment)]
    )
    return result.value
  }
  
  public func getMinimumBalanceForRentExemption(
    dataLength: UInt64,
    commitment: Commitment? = "recent"
  ) async throws -> UInt64 {
    try await get(
      method: "getMinimumBalanceForRentExemption",
      params: [dataLength, RequestConfiguration(commitment: commitment)]
    )
  }
  
  public func getRecentBlockhash(commitment: Commitment? = nil) async throws -> String {
    let result: DerivableRpc<DerivableFee> = try await get(
      method: "getRecentBlockhash",
      params: [RequestConfiguration(commitment: commitment)]
    )
    guard let blockhash = result.value.blockhash else {
      throw APIClientError.blockhashNotFound
    }
    return blockhash
  }
  
  public func getSignatureStatuses(
    signatures: [String],
    configs: RequestConfiguration? = nil
  ) async throws -> [DerivableSignatureStatus?] {
    let result: DerivableRpc<[DerivableSignatureStatus?]> = try await get(
      method: "getSignatureStatuses",
      params: [signatures, configs]
    )
    return result.value
  }
  
  public func getSignatureStatus(
    signature: String,
    configs _: RequestConfiguration? = nil
  ) async throws -> DerivableSignatureStatus {
    guard let result = try await getSignatureStatuses(signatures: [signature]).first else {
      throw APIClientError.invalidResponse
    }
    return try result ?! APIClientError.invalidResponse
  }
  
  public func getTokenAccountBalance(
    pubkey: String,
    commitment: Commitment? = nil
  ) async throws -> DerivableTokenAccountBalance {
    let result: DerivableRpc<DerivableTokenAccountBalance> = try await get(
      method: "getTokenAccountBalance",
      params: [pubkey, RequestConfiguration(commitment: commitment)]
    )
    if UInt64(result.value.amount) == nil {
      throw APIClientError.couldNotRetrieveAccountInfo
    }
    return result.value
  }
  
  public func getTokenAccountsByDelegate(
    pubkey: String,
    mint: String? = nil,
    programId: String? = nil,
    configs: RequestConfiguration? = nil
  ) async throws -> [DerivableTokenAccount<SPLTokenAccountState>] {
    let result: DerivableRpc<[DerivableTokenAccount<SPLTokenAccountState>]> = try await get(
      method: "getTokenAccountsByDelegate",
      params: [
        pubkey,
        mint,
        programId,
        configs,
      ]
    )
    return result.value
  }
  
  public func getTokenAccountsByOwner(
    pubkey: String,
    params: OwnerInfoParams? = nil,
    configs: RequestConfiguration? = nil
  ) async throws -> [DerivableTokenAccount<SPLTokenAccountState>] {
    let result: DerivableRpc<[DerivableTokenAccount<SPLTokenAccountState>]> = try await get(
      method: "getTokenAccountsByOwner",
      params: [pubkey, params, configs]
    )
    return result.value
  }
  
  public func getTokenLargestAccounts(
    pubkey: String,
    commitment: Commitment? = nil
  ) async throws -> [DerivableTokenAmount] {
    try await get(
      method: "getTokenLargestAccounts",
      params: [pubkey, RequestConfiguration(commitment: commitment)]
    )
  }
  
  public func getTokenSupply(
    pubkey: String,
    commitment: Commitment? = nil
  ) async throws -> DerivableTokenAmount {
    let result: DerivableRpc<DerivableTokenAmount> = try await get(
      method: "getTokenSupply",
      params: [pubkey, RequestConfiguration(commitment: commitment)]
    )
    return result.value
  }
  
  public func getVersion() async throws -> DerivableVersion {
    try await get(
      method: "getVersion",
      params: []
    )
  }
  
  public func getVoteAccounts(
    commitment: Commitment? = nil
  ) async throws -> DerivableVoteAccounts {
    try await get(
      method: "getVoteAccounts",
      params: [RequestConfiguration(commitment: commitment)]
    )
  }
  
  public func minimumLedgerSlot() async throws -> UInt64 {
    try await get(
      method: "minimumLedgerSlot",
      params: []
    )
  }
  
  public func requestAirdrop(
    account: String, lamports: UInt64,
    commitment: Commitment? = nil
  ) async throws -> String {
    try await get(
      method: "requestAirdrop",
      params: [account, lamports, RequestConfiguration(commitment: commitment)]
    )
  }
  
  public func sendTransaction(
    transaction: String,
    configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!
  ) async throws -> TransactionID {
    do {
      return try await get(method: "sendTransaction", params: [transaction, configs])
    } catch let APIClientError.responseError(response) {
      // Convert to APIClientError.blockhashNotFound
      if response.message?.contains("Blockhash not found") == true {
        throw APIClientError.blockhashNotFound
      }
      
      // FIXME: - Remove later: Modify error message
      var message = response.message
      if let readableMessage = response.data?.logs?
        .first(where: { $0.contains("Error:") })?
        .components(separatedBy: "Error: ")
        .last
      {
        message = readableMessage
      } else if let readableMessage = response.message?
        .components(separatedBy: "Transaction simulation failed: ")
        .last
      {
        message = readableMessage
      }
      
      // Log
      //      Logger.log(
      //        event: "SolanaSwift: sendTransaction",
      //        message: (message ?? "") + "\n " + (response.data?.logs?.joined(separator: " ") ?? ""),
      //        logLevel: .error
      //      )
      
      // Rethrow modified error
      throw APIClientError.responseError(
        DerivableResponseError(
          code: response.code,
          message: message,
          data: response.data
        )
      )
    }
  }
  
  public func getRecentPerformanceSamples(
    limit: [UInt]
  ) async throws -> [DerivablePerfomanceSamples] {
    try await get(
      method: "getRecentPerformanceSamples",
      params: limit
    )
  }
  
  public func getSignaturesForAddress(
    address: String,
    configs: RequestConfiguration? = nil
  ) async throws -> [DerivableSignatureInfo] {
    //TODO method: "getSignaturesForAddress", - официальное название, а второе - это что дергает наш эксплорер
    try await get(
      method: "getConfirmedSignaturesForAddress2",
      params: [address, configs]
    )
  }
  
  public func simulateTransaction(
    transaction: String,
    configs: RequestConfiguration = RequestConfiguration(
      commitment: "confirmed",
      encoding: "base64",
      replaceRecentBlockhash: true
    )!
  ) async throws -> DerivableSimulationResult {
    let result: DerivableRpc<DerivableSimulationResult> = try await get(
      method: "simulateTransaction",
      params: [transaction, configs]
    )
    
    // Error assertion
    if let err = result.value.err {
      if (err.wrapped as? String) == "BlockhashNotFound" {
        throw APIClientError.blockhashNotFound
      }
      throw APIClientError.transactionSimulationError(logs: result.value.logs)
    }
    
    // Return value
    return result.value
  }
  
  //  public func observeSignatureStatus(
  //    signature: String,
  //    timeout: Int = 60,
  //    delay: Int = 2
  //  ) -> AsyncStream<PendingTransactionStatus> {
  //    AsyncStream { continuation in
  //      let monitor = TransactionMonitor(
  //        apiClient: self,
  //        signature: signature,
  //        timeout: timeout,
  //        delay: delay,
  //        responseHandler: { transactionStatus in
  //          continuation.yield(transactionStatus)
  //          if transactionStatus == .finalized {
  //            continuation.finish()
  //          }
  //        },
  //        timedOutHandler: {
  //          continuation.finish()
  //        }
  //      )
  //      continuation.onTermination = { @Sendable _ in
  //        monitor.stopMonitoring()
  //      }
  //      monitor.startMonitoring()
  //    }
  //  }
  
  public func setLogFilter(filter: String) async throws -> String? {
    try await get(
      method: "setLogFilter",
      params: [filter]
    )
  }
  
  public func validatorExit() async throws -> Bool {
    try await get(
      method: "validatorExit",
      params: []
    )
  }
  
  public func getMultipleAccounts<T>(
    pubkeys: [String],
    commitment: Commitment
  ) async throws -> [BufferInfo<T>?]
  where T: BufferLayout
  {
    let configs = RequestConfiguration(commitment: commitment, encoding: "base64")
    guard !pubkeys.isEmpty else { return [] }
    
    let result: DerivableRpc<[BufferInfo<T>?]> = try await get(
      method: "getMultipleAccounts",
      params: [pubkeys, configs]
    )
    return result.value
  }
  
  public func request<Entity>(
    method: String,
    params: [Encodable]
  ) async throws -> Entity where Entity: Decodable {
    try await get(
      method: method,
      params: params
    )
  }
  
  // MARK: - Batch requests
  
  public func batchRequest(
    with requests: [RequestEncoder.RequestType]
  ) async throws -> [AnyResponse<RequestEncoder.RequestType.Entity>] {
    let data = try await makeRequest(requests: requests)
    let response = try ResponseDecoder<[AnyResponse<AnyDecodable>]>().decode(with: data)
    let ret = response.map { resp in
      AnyResponse<RequestEncoder.RequestType.Entity>(resp)
    }
    return ret
  }
  
  public func batchRequest<Entity: Decodable>(
    method: String,
    params: [[Encodable]]
  ) async throws -> [Entity?] {
    if params.isEmpty { return [] }
    
    let data = try await makeRequest(requests: params.map { args in
        .init(method: method, params: args)
    })
    let response = try ResponseDecoder<[AnyResponse<Entity>]>().decode(with: data)
    return response.map(\.result)
  }
  
  public func getSlot() async throws -> UInt64 {
    try await get(
      method: "getSlot",
      params: []
    )
  }
  
  //    public func getAddressLookupTable(accountKey: PublicKey) async throws -> AddressLookupTableAccount? {
  //        guard let result: BufferInfo<AddressLookupTableState> = try await getAccountInfo(account: accountKey
  //            .base58EncodedString)
  //        else {
  //            return nil
  //        }
  //
  //        return .init(key: accountKey, state: result.data)
  //    }
  
  // MARK: - Private
  
  private func get<Entity: Decodable>(method: String, params: [Encodable]) async throws -> Entity {
    let request = RequestEncoder.RequestType(method: method, params: params)
    let data = try await makeRequest(request: request)
    let response: AnyResponse<Entity> = try ResponseDecoder<AnyResponse<Entity>>().decode(with: data)
    if let error = response.error {
      //            Logger.log(
      //                event: "SolanaSwift: get<Entity>",
      //                message: (String(data: data, encoding: .utf8) ?? "") + "\n" + (error.message ?? ""),
      //                logLevel: .error
      //            )
      print(">>> JsonRpcApiClient error in get with method: \(method) and params: \(params), error: \(error)")
      throw APIClientError.responseError(error)
    }
    guard let result = response.result else {
      //            Logger.log(
      //                event: "SolanaSwift: get<Entity>",
      //                message: String(data: data, encoding: .utf8),
      //                logLevel: .error
      //            )
      throw APIClientError.invalidResponse
    }
    return result
  }
  
  private func makeRequest(request: RequestEncoder.RequestType) async throws -> Data {
    // encode params
    let encodedParams = try RequestEncoder(request: request).encoded()
    
    // request data
    let responseData = try await networkManager.requestData(request: urlRequest(data: encodedParams))
    
    // log
    //Logger.log(event: "response", message: String(data: responseData, encoding: .utf8) ?? "", logLevel: .debug)
    
    return responseData
  }
  
  private func makeRequest(requests: [RequestEncoder.RequestType]) async throws -> Data {
    // encode params
    let encodedParams = try RequestEncoder(requests: requests).encoded()
    
    // request data
    let responseData = try await networkManager.requestData(request: urlRequest(data: encodedParams))
    
    // log
    //Logger.log(event: "response", message: String(data: responseData, encoding: .utf8) ?? "", logLevel: .debug)
    
    return responseData
  }
  
  private func urlRequest(data: Data) throws -> URLRequest {
    guard let url = URL(string: endpoint) else { throw APIClientError.invalidAPIURL }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpBody = data
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    // log
    //Logger.log(event: "request", message: urlRequest.cURL(), logLevel: .debug)
    
    return urlRequest
  }
}
