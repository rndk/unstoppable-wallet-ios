import Foundation
import Alamofire
import SwiftyJSON

open class SuiClient {
  
  var rpc_endpoint: String!
  var faucet_endpoint: String!
  
  public static let shared = SuiClient()
  
  public init() { }
  
  public func setConfig(_ chainType: ChainType, _ end_point: String? = nil) {
    switch chainType {
    case .local:
      rpc_endpoint = end_point != nil ? end_point : SuiConstant.LOCAL_RPC_URL
      faucet_endpoint = SuiConstant.LOCAL_FAUCET_URL
    case .devnet:
      rpc_endpoint = end_point != nil ? end_point : SuiConstant.DEV_RPC_URL
      faucet_endpoint = SuiConstant.DEV_FAUCET_URL
    case .testnet:
      rpc_endpoint = end_point != nil ? end_point : SuiConstant.TEST_RPC_URL
      faucet_endpoint = SuiConstant.TEST_FAUCET_URL
    case .mainnet:
      rpc_endpoint = end_point != nil ? end_point : SuiConstant.MAIN_RPC_URL
      faucet_endpoint = ""
    }
  }
  
  public func updateBaseUrl(newSourceUrl: String) {
    rpc_endpoint = newSourceUrl;
  }
  
  public func generateMnemonic() -> String? {
    return try? BIP39.generateMnemonics(bitsOfEntropy: 128)
  }
  
  public func getAddress(_ mnemonic: String)  -> String {
    return SuiKey.getSuiAddress(mnemonic)
  }
  
  public func faucet(_ address: String) async throws -> JSON {
    return try await AF.request(
      faucet_endpoint,
      method: .post,
      parameters: FaucetRequest(FixedAmountRequest: FixedAmountRequest(recipient: address)),
      encoder: JSONParameterEncoder.default
    ).serializingDecodable(JSON.self).value
  }
  
  public func sign(
    _ mnemonic: String,
    _ txBytes: Data
  ) -> (pubKey: Data, signedData: Data) {
    let seedKey = SuiKey.getPrivKeyFromSeed(mnemonic)
    return (SuiKey.getPubKey(mnemonic), SuiKey.sign(seedKey, txBytes))
  }
  
  public func sign(
    _ privKey: Data,
    _ txBytes: Data
  ) -> Data {
    return SuiKey.sign(privKey, txBytes)
  }
  
  public func getSuiSystemstate(
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest("sui_getSuiSystemState", JSON())
    SuiRequest(params, listener)
  }
  
  public func getTotalSupply(
    _ coinType: String,
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest("sui_getTotalSupply", JSON())
    SuiRequest(params, listener)
  }
  
  public func getAllBalances(
    _ address: String,
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest("suix_getAllBalances", JSON(arrayLiteral: address))
    SuiRequest(params, listener)
  }
  
  public func getAllBalanceAsync(
    _ address: String,
    _ coinType: String
  ) async throws -> JSON {
    let params = JsonRpcRequest(
      "suix_getBalance",
      JSON(arrayLiteral: address, coinType)
    )
    return try await postJsonRpcRequest(params)
  }
  
  public func getAllCoins(
    _ owner: String,
    _ cursor: String? = nil,
    _ limit: Int? = nil,
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest(
      "sui_getAllCoins",
      JSON(arrayLiteral: owner, cursor, limit)
    )
    SuiRequest(params, listener)
  }
  
  public func getCoins(
    _ owner: String,
    _ coinType: String,
    _ cursor: String? = nil,
    _ limit: Int? = nil,
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest(
      "sui_getCoins",
      JSON(arrayLiteral: owner, cursor, limit)
    )
    SuiRequest(params, listener)
  }
  
  public func getCoinMetadata(_ coinType: String, _ listener: @escaping (JSON?, JSON?) -> Void) {
    let params = JsonRpcRequest(
      "sui_getCoinMetadata",
      JSON(arrayLiteral: coinType)
    )
    SuiRequest(params, listener)
  }
  
  public func getObjectsByOwnerAsync(_ address: String) async throws -> JSON {
    let params = JsonRpcRequest(
      "suix_getOwnedObjects",
      JSON(arrayLiteral: address, ["filter": nil, "options":["showContent":true, "showType":true]])
    )
    return try await postJsonRpcRequest(params)
  }
  
  public func getTransactionsAsync(
    _ transactionQuery: [String: String],
    _ nextOffset: String? = nil,
    _ limit: Int? = nil,
    _ descending: Bool = false
  ) async throws -> JSON {
    let params = JsonRpcRequest(
      "suix_queryTransactionBlocks",
      JSON(
        arrayLiteral: [
          "filter": transactionQuery,
          "options": ["showEffects": true, "showInput":true, "showBalanceChanges": true]
        ],
        nextOffset,
        limit,
        descending
      )
    )
    return try await postJsonRpcRequest(params)
  }
  
  public func paySui(
    _ objectIds: [String],
    _ receivers: [String],
    _ sender: String,
    _ gasBudget: String,
    _ amounts: [String]
  ) async throws -> JSON {
    let params = JsonRpcRequest(
      "unsafe_paySui",
      JSON(arrayLiteral: sender, objectIds, receivers, amounts, gasBudget)
    )
    return try await postJsonRpcRequest(params)
  }
  
  public func payMaxSui(
    _ objectIds: [String],
    _ receiver: String,
    _ sender: String,
    _ gasBudget: String
  ) async throws -> JSON {
    let params = JsonRpcRequest(
      "unsafe_payAllSui",
      JSON(arrayLiteral: sender, objectIds, receiver, gasBudget)
    )
    return try await postJsonRpcRequest(params)
  }
  
  func dryRunTransactionBlock(txBytes: String) async throws -> JSON {
    let params = JsonRpcRequest(
      "sui_dryRunTransactionBlock",
      JSON(arrayLiteral: txBytes)
    )
    return try await postJsonRpcRequest(params)
  }
  
  public func transferObject(
    _ objectId: String,
    _ receiver: String,
    _ sender: String,
    _ gas: String? = nil,
    _ gasBudget: Int = 1000,
    _ amount: Int? = nil,
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest(
      "unsafe_transferObject",
      JSON(arrayLiteral: sender, objectId, gas, gasBudget, receiver)
    )
    SuiRequest(params, listener)
  }
  
  public func executeTransaction(
    _ txBytes: Data,
    _ signedBytes: Data,
    _ pubKey: Data,
    _ options: [String: Bool],
    _ listener: @escaping (JSON?, JSON?) -> Void
  ) {
    let params = JsonRpcRequest(
      "sui_executeTransactionBlock",
      JSON(
        arrayLiteral: txBytes.base64EncodedString(),
        [(Data([0x00]) + signedBytes + pubKey).base64EncodedString()],
        options,
        "WaitForLocalExecution"
      )
    )
    SuiRequest(params, listener)
  }
  
  public func executeTransactionAsync(
    _ txBytes: Data,
    _ signedBytes: Data,
    _ pubKey: Data,
    _ options: [String: Bool]
  ) async throws -> JSON {
    let params = JsonRpcRequest(
      "sui_executeTransactionBlock",
      JSON(
        arrayLiteral: txBytes.base64EncodedString(),
        [(Data([0x00]) + signedBytes + pubKey).base64EncodedString()],
        options,
        "WaitForLocalExecution"
      )
    )
    return try await postJsonRpcRequest(params)
  }
  
  public func SuiRequest(_ params: JsonRpcRequest, _ listener: @escaping (JSON?, JSON?) -> Void) {
    AF.request(
      rpc_endpoint,
      method: .post,
      parameters: params,
      encoder: JSONParameterEncoder.default
    ).response { response in
      switch response.result {
      case .success(let value):
        if let value = value, let response = try? JSONDecoder().decode(JsonRpcResponse.self, from: value) {
          listener(response.result, response.error)
        } else {
          listener(nil, JSON(["code": -9999, "message": "Unknown"]))
        }
      case .failure(let error):
        listener(nil, JSON(["code": -9999, "message": "Unknown"]))
      }
    }
  }
  
  public func postJsonRpcRequest(_ params: JsonRpcRequest) async throws -> JSON {
    return try await AF.request(
      rpc_endpoint,
      method: .post,
      parameters: params,
      encoder: JSONParameterEncoder.default
    ).serializingDecodable(JSON.self).value
  }
}
