import Foundation

public enum BlockchainClientError: Error, Equatable {
  case sendTokenToYourSelf
  case invalidAccountInfo
  case other(String)
}

/// Default implementation of SolanaBlockchainClient
public class BlockchainClient: DerivableBlockchainClient {
  public var apiClient: JSONRPCAPIClient
  private let systemProgrammId: PublicKey
  private let tokenProgramId: PublicKey
  private let associatedProgramId: PublicKey
  private let sysvarRent: PublicKey
  
  public init(
    apiClient: JSONRPCAPIClient,
    systemProgrammId: PublicKey,
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    sysvarRent: PublicKey
  ) {
    self.apiClient = apiClient
    self.systemProgrammId = systemProgrammId
    self.tokenProgramId = tokenProgramId
    self.associatedProgramId = associatedProgramId
    self.sysvarRent = sysvarRent
  }
  
  /// Prepare a transaction to be sent using SolanaBlockchainClient
  /// - Parameters:
  ///   - instructions: the instructions of the transaction
  ///   - signers: the signers of the transaction
  ///   - feePayer: the feePayer of the transaction
  ///   - feeCalculator: (Optional) fee custom calculator for calculating fee
  /// - Returns: PreparedTransaction, can be sent or simulated using SolanaBlockchainClient
  public func prepareTransaction(
    instructions: [TransactionInstruction],
    signers: [DerivableKeyPair],
    feePayer: PublicKey,
    feeCalculator fc: FeeCalculator? = nil
  ) async throws -> DerivablePreparedTransaction {
    // form transaction
    var transaction = DerivableTransaction(
      instructions: instructions,
      recentBlockhash: nil,
      feePayer: feePayer
    )
    
    let feeCalculator: FeeCalculator
    if let fc = fc {
      feeCalculator = fc
    } else {
      let (lps, minRentExemption) = try await (
        apiClient.getFees(commitment: nil).feeCalculator?.lamportsPerSignature,
        apiClient.getMinimumBalanceForRentExemption(span: 165)
      )
      let lamportsPerSignature = lps ?? 5000
      feeCalculator = DefaultFeeCalculator(
        lamportsPerSignature: lamportsPerSignature,
        minRentExemption: minRentExemption
      )
    }
    let expectedFee = try feeCalculator.calculateNetworkFee(transaction: transaction)
    
    let blockhash = try await apiClient.getRecentBlockhash()
    transaction.recentBlockhash = blockhash
    
    // if any signers, sign
    if !signers.isEmpty {
      try transaction.sign(signers: signers)
    }
    
    // return formed transaction
    return .init(transaction: transaction, signers: signers, expectedFee: expectedFee)
  }
  
  /// Create prepared transaction for sending native coin
  /// - Parameters:
  ///   - account
  ///   - to: destination wallet address
  ///   - amount: amount in lamports
  ///   - feePayer: customm fee payer, can be omited if the authorized user is the payer
  ///    - recentBlockhash optional
  /// - Returns: PreparedTransaction, can be sent or simulated using SolanaBlockchainClient
  public func prepareSendingNative(
    from account: DerivableKeyPair,
    to destination: String,
    amount: UInt64,
    feePayer: PublicKey? = nil,
    sendMax: Bool = false
  ) async throws -> DerivablePreparedTransaction {
    let feePayer = feePayer ?? account.publicKey
    let fromPublicKey = account.publicKey
    if fromPublicKey.base58EncodedString == destination {
      throw BlockchainClientError.sendTokenToYourSelf
    }
    var accountInfo: BufferInfo<EmptyInfo>?
    do {
      accountInfo = try await apiClient.getAccountInfo(account: destination)
      guard accountInfo == nil || accountInfo?.owner == self.systemProgrammId.base58EncodedString
      else { throw BlockchainClientError.invalidAccountInfo }
    } catch let error as APIClientError where error == .couldNotRetrieveAccountInfo {
      // ignoring error
      accountInfo = nil
    } catch {
      throw error
    }
    
    // form instruction
    let instruction = try SystemProgram.transferInstruction(
      id: self.systemProgrammId,
      from: fromPublicKey,
      to: PublicKey(string: destination),
      lamports: amount
    )
    return try await prepareTransaction(
      instructions: [instruction],
      signers: [account],
      feePayer: feePayer
    )
  }
  
  /// Prepare for sending any SPLToken
  /// - Parameters:
  ///   - account: user's account to send from
  ///   - mintAddress: mint address of sending token
  ///   - decimals: decimals of the sending token
  ///   - fromPublicKey: the concrete spl token address in user's account
  ///   - destinationAddress: the destination address, can be token address or native Solana address
  ///   - amount: amount to be sent
  ///   - feePayer: (Optional) if the transaction would be paid by another user
  ///   - transferChecked: (Default: false) use transferChecked instruction instead of transfer transaction
  ///   - minRentExemption: (Optional) pre-calculated min rent exemption, will be fetched if not provided
  /// - Returns: (preparedTransaction: PreparedTransaction, realDestination: String), preparedTransaction can be sent
  /// or simulated using SolanaBlockchainClient, the realDestination is the real spl address of destination. Can be
  /// different from destinationAddress if destinationAddress is a native Solana address
  public func prepareSendingSPLTokens(
    account: DerivableKeyPair,
    mintAddress: String,
    decimals: Decimals,
    from fromPublicKey: String,
    to destinationAddress: String,
    amount: UInt64,
    feePayer: PublicKey? = nil,
    transferChecked: Bool = false,
    minRentExemption mre: DerivableLamports? = nil
  ) async throws -> (preparedTransaction: DerivablePreparedTransaction, realDestination: String) {
    let feePayer = feePayer ?? account.publicKey
    
    let minRenExemption: DerivableLamports
    if let mre = mre {
      minRenExemption = mre
    } else {
      minRenExemption = try await apiClient
        .getMinimumBalanceForRentExemption(span: SPLTokenAccountState.BUFFER_LENGTH)
    }
    let splDestination = try await apiClient.findSPLTokenDestinationAddress(
      mintAddress: mintAddress,
      destinationAddress: destinationAddress
    )
    
    // get address
    let toPublicKey = splDestination.destination
    
    // catch error
    if fromPublicKey == toPublicKey.base58EncodedString {
      throw BlockchainClientError.sendTokenToYourSelf
    }
    
    let fromPublicKey = try PublicKey(string: fromPublicKey)
    
    var instructions = [TransactionInstruction]()
    
    // create associated token address
    var accountsCreationFee: UInt64 = 0
    if splDestination.isUnregisteredAsocciatedToken {
      let mint = try PublicKey(string: mintAddress)
      let owner = try PublicKey(string: destinationAddress)
      
      let createATokenInstruction = try AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
        associatedProgramId: self.associatedProgramId,
        systemProgramId: self.systemProgrammId, //TODO ??????
        tokenProgramId: self.tokenProgramId, //TODO ???
        sysvarRent: self.sysvarRent, //TODO ???
        mint: mint,
        owner: owner,
        payer: feePayer
      )
      instructions.append(createATokenInstruction)
      accountsCreationFee += minRenExemption
    }
    
    // send instruction
    let sendInstruction: TransactionInstruction
    
    // use transfer checked transaction for proxy, otherwise use normal transfer transaction
    if transferChecked {
      // transfer checked transaction, //TODO id ???
      sendInstruction = try TokenProgram.transferCheckedInstruction(
        id: self.tokenProgramId,
        source: fromPublicKey,
        mint: PublicKey(string: mintAddress),
        destination: splDestination.destination,
        owner: account.publicKey,
        multiSigners: [],
        amount: amount,
        decimals: decimals
      )
    } else {
      // transfer transaction
      sendInstruction = TokenProgram.transferInstruction(
        id: self.tokenProgramId,
        source: fromPublicKey,
        destination: toPublicKey,
        owner: account.publicKey,
        amount: amount
      )
    }
    
    instructions.append(sendInstruction)
    
    var realDestination = destinationAddress
    if !splDestination.isUnregisteredAsocciatedToken {
      realDestination = splDestination.destination.base58EncodedString
    }
    
    // if not, serialize and send instructions normally
    let preparedTransaction = try await prepareTransaction(
      instructions: instructions,
      signers: [account],
      feePayer: feePayer
    )
    return (preparedTransaction, realDestination)
  }
}
