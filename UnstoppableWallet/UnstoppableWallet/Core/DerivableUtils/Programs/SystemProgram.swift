import Foundation

public enum SystemProgram {
  // MARK: - Nested type
  
  public enum Index {
    static let create: UInt32 = 0
    static let transfer: UInt32 = 2
  }
  
  // MARK: - Instruction builders
  
  public static func createAccountInstruction(
    id: PublicKey,
    from fromPublicKey: PublicKey,
    toNewPubkey newPubkey: PublicKey,
    lamports: UInt64,
    space: UInt64,
    programId: PublicKey
  ) -> TransactionInstruction {
    TransactionInstruction(
      keys: [
        AccountMeta(publicKey: fromPublicKey, isSigner: true, isWritable: true),
        AccountMeta(publicKey: newPubkey, isSigner: true, isWritable: true),
      ],
      programId: id,
      data: [Index.create, lamports, space, programId]
    )
  }
  
  public static func transferInstruction(
    id: PublicKey,
    from fromPublicKey: PublicKey,
    to toPublicKey: PublicKey,
    lamports: UInt64
  ) -> TransactionInstruction {
    TransactionInstruction(
      keys: [
        AccountMeta(publicKey: fromPublicKey, isSigner: true, isWritable: true),
        AccountMeta(publicKey: toPublicKey, isSigner: false, isWritable: true),
      ],
      programId: id,
      data: [Index.transfer, lamports]
    )
  }
}
