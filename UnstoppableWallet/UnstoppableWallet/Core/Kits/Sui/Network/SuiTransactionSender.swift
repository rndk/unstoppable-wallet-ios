import Foundation
import BigInt

class SuiTransactionSender {
  
  private let networkInteractor: SuiNetworkInteractor
  
  init(networkInteractor: SuiNetworkInteractor) {
    self.networkInteractor = networkInteractor
  }
  
}

extension SuiTransactionSender {
  
  func getPayTransaction(
    sendMax: Bool,
    ids: [String],
    receivers: [String],
    sender: String,
    feeBudged: BigUInt,
    amounts: [BigUInt]
  ) async throws -> SuiWrappedTxBytes? {
    if sendMax {
      return try await getPayAllSuiTransaction(
        ids: ids,
        receiver: receivers.first!,
        sender: sender,
        feeBudged: feeBudged
      )
    } else {
      return try await getPaySuiTransaction(
        ids: ids,
        receivers: receivers,
        sender: sender,
        feeBudged: feeBudged,
        amounts: amounts
      )
    }
  }
  
  func getPaySuiTransaction(
    ids: [String],
    receivers: [String],
    sender: String,
    feeBudged: BigUInt,
    amounts: [BigUInt]
  ) async throws -> SuiWrappedTxBytes? {
    try await networkInteractor.paySui(
      ids: ids,
      receivers: receivers,
      sender: sender,
      feeBudged: feeBudged,
      amounts: amounts
    )
  }
  
  func getPayAllSuiTransaction(
    ids: [String],
    receiver: String,
    sender: String,
    feeBudged: BigUInt
  ) async throws -> SuiWrappedTxBytes? {
    try await networkInteractor.payMaxSui(
      ids: ids,
      receiver: receiver,
      sender: sender,
      feeBudged: feeBudged
    )
  }
  
  func dryRunTransaction(tx: SuiWrappedTxBytes) async throws -> EstimateGas? {
    try await networkInteractor.dryRunTransactionBlock(txBytes: tx.txBytes)!
  }
  
  func sign(mnemonic: String, txBytes: Data) -> (pubKey: Data, signedData: Data) {
    networkInteractor.sign(mnemonic: mnemonic, txBytes: txBytes)
  }
  
  func executeTransaction(
    txBytes: Data,
    signedBytes: Data,
    pubkey: Data
  ) async throws {
    try await networkInteractor.executeTransaction(
      txBytes: txBytes, signedBytes: signedBytes, pubkey: pubkey
    )
  }
  
}
