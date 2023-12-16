import Foundation

public enum MemoProgramError: Error {
  case invalid
}

public enum MemoProgram {
  /// Create memo instruction
  public static func createMemoInstruction(
    id: PublicKey,
    memo: String
  ) throws -> TransactionInstruction {
    // TODO: - Memo length assertion
    guard let data = memo.data(using: .utf8) else {
      throw MemoProgramError.invalid
    }
    return TransactionInstruction(
      keys: [],
      programId: id,
      data: data.bytes
    )
  }
}
