import Foundation

public enum AssociatedTokenProgram {
  // MARK: - Instruction builder
  
  public static func createAssociatedTokenAccountInstruction(
    associatedProgramId: PublicKey,
    systemProgramId: PublicKey,
    tokenProgramId: PublicKey,
    sysvarRent: PublicKey,
    mint: PublicKey,
    owner: PublicKey,
    payer: PublicKey
  ) throws -> TransactionInstruction {
    TransactionInstruction(
      keys: [
        .init(publicKey: payer, isSigner: true, isWritable: true),
        try .init(
          publicKey: PublicKey.associatedTokenAddress(
            tokenProgramId: tokenProgramId,
            associatedProgramId: associatedProgramId,
            walletAddress: owner,
            tokenMintAddress: mint
          ),
          isSigner: false,
          isWritable: true
        ),
        .init(publicKey: owner, isSigner: false, isWritable: false),
        .init(publicKey: mint, isSigner: false, isWritable: false),
        .init(publicKey: systemProgramId, isSigner: false, isWritable: false),
        .init(publicKey: tokenProgramId, isSigner: false, isWritable: false),
        .init(publicKey: sysvarRent, isSigner: false, isWritable: false),
      ],
      programId: associatedProgramId,
      data: []
    )
  }
}
