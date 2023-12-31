import Foundation
import BigInt
import SwiftyJSON

class SuiNetworkInteractor {
  
  private var networkUrl: String
  private let blockchainUid: String
  private let signer: SuiSigner
  private let apiClient: SuiClient
  
  init(networkUrl: String, blockchainUid: String, signer: SuiSigner, apiClient: SuiClient) {
    self.networkUrl = networkUrl
    self.blockchainUid = blockchainUid
    self.signer = signer
    self.apiClient = apiClient
  }
}

extension SuiNetworkInteractor {
  
  func updateBaseUrl(newSourceUrl: String) {
    self.networkUrl = newSourceUrl
    self.apiClient.updateBaseUrl(newSourceUrl: newSourceUrl)
  }
  
}

extension SuiNetworkInteractor {
  
  var source: String {
    self.networkUrl
  }
  
  func sign(mnemonic: String, txBytes: Data) -> (pubKey: Data, signedData: Data) {
    apiClient.sign(mnemonic, txBytes)
  }
  
  func executeTransaction(
    txBytes: Data,
    signedBytes: Data,
    pubkey: Data,
    options: [String:Bool] = ["showInput": true, "showEffects": true, "showBalanceChanges": true]
  ) async throws {
    let result = try await apiClient.executeTransactionAsync(
      txBytes,
      signedBytes,
      pubkey,
      options
    )
  }
  
  func getBalance(address: String) async throws -> UInt64 {
    let response = try await apiClient.getAllBalanceAsync(address, "0x2::sui::SUI")
    let rawValue: String = response["result"]["totalBalance"].rawValue as! String
    return UInt64(rawValue) ?? 0
  }
  
  func getIncomingTransactions(address: String, lastHash: String?) async throws -> [DerivableCoinTransaction] {
    let response = try await apiClient.getTransactionsAsync(["ToAddress": address], lastHash)
    let parsedResponse = try? JSONDecoder().decode(SuiApiTransactionResponse.self, from: response.rawData())
    return parseTransactions(response: parsedResponse)
  }
  
  func getOutgoingTransactions(address: String, lastHash: String?) async throws -> [DerivableCoinTransaction] {
    let response = try await apiClient.getTransactionsAsync(["FromAddress": address], lastHash)
    let parsedResponse = try? JSONDecoder().decode(SuiApiTransactionResponse.self, from: response.rawData())
    return parseTransactions(response: parsedResponse)
  }
  
  private func parseTransactions(response: SuiApiTransactionResponse?) -> [DerivableCoinTransaction] {
    guard let parsedResponse = response else {
      return []
    }
    
    var parsedTransactions: [DerivableCoinTransaction] = []
    
    guard let parsedResponseData = parsedResponse.result?.data else {
      return []
    }
    
    for data in parsedResponseData {
      var amount: Int64 = 0
      var to = ""
      data.balanceChanges?.forEach { balanceInfo in
        let sum = Int64(balanceInfo.amount!)
        if sum != nil, sum! > 0 {
          amount += sum!
          if to.isEmpty {
            to = balanceInfo.owner?.addressOwner ?? ""
          }
        }
      }
      
      var gas: Int64 = 0
      let gasUsed = data.effects?.gasUsed
      let compCost = (Int64(gasUsed?.computationCost ?? "0"))
      let storCost = (Int64(gasUsed?.storageCost ?? "0"))
      let storRebate = (Int64(gasUsed?.storageRebate ?? "0"))
      
      gas = (compCost ?? 0) + (storCost ?? 0) - (storRebate ?? 0)
      
      let failed = data.effects?.status?.status != "success"
      
      parsedTransactions.append(DerivableCoinTransaction(
        rpcSourceUrl: self.networkUrl,
        blockchainUid: self.blockchainUid,
        hash: data.digest!,
        currentAddress: self.signer.coinAddress,
        blockTime: (UInt64(data.timestampMs ?? "0") ?? 0) / 1000,
        from: data.transaction!.data!.sender!,
        to: to,
        value: UInt64(amount),
        fee: UInt64(abs(gas)),
        isFailed: failed)
      )
    }
    
    return parsedTransactions
  }
  
  func getOwnedObjects(address: String) async throws -> SuiOwnedObjectsResponse? {
    let ownedObjects = try await apiClient.getObjectsByOwnerAsync(address)
    return try? JSONDecoder().decode(
      SuiOwnedObjectsResponse.self,
      from: ownedObjects.rawData()
    )
  }
  
  func paySui(
    ids: [String],
    receivers: [String],
    sender: String,
    feeBudged: BigUInt,
    amounts: [BigUInt]
  ) async throws -> SuiWrappedTxBytes? {
    let response = try await apiClient.paySui(
      ids,
      receivers,
      sender,
      String(feeBudged),
      amounts.map{ am in String(am) }
    )
    
    return try? JSONDecoder().decode(
      SuiApiDryRun.self,
      from: response.rawData()
    ).result
  }
  
  func payMaxSui(
    ids: [String],
    receiver: String,
    sender: String,
    feeBudged: BigUInt
  ) async throws -> SuiWrappedTxBytes? {
    let response = try await apiClient.payMaxSui(
      ids,
      receiver,
      sender,
      String(feeBudged)
    )
    
    return try? JSONDecoder().decode(
      SuiApiDryRun.self,
      from: response.rawData()
    ).result
  }
  
  func dryRunTransactionBlock(txBytes: String) async throws -> EstimateGas? {
    let response = try await apiClient.dryRunTransactionBlock(txBytes: txBytes)
    return try? JSONDecoder().decode(
      EstimateGas.self,
      from: response.rawData()
    )
  }
  
}
