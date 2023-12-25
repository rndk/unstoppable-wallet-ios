import Foundation

public struct SolanaTokenProgram: BasicProgram {
  
  public static var tokenProgramId: PublicKey {
    "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
  }
  
  public static var sysvarRent: PublicKey {
    "SysvarRent111111111111111111111111111111111"
  }
  
  public static var systemProgramId: PublicKey {
    "11111111111111111111111111111111"
  }
  
  public static var memoProgramId: PublicKey {
    "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"
  }
  
  public static var splAssociatedTokenAccountProgramId: PublicKey {
    "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
  }
  
  public static var usdcMint: PublicKey {
    ""
  }
  
  public static var usdtMint: PublicKey {
    ""
  }
  
}
