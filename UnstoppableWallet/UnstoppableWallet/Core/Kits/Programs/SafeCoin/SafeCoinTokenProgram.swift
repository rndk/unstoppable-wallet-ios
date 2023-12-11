import Foundation

public struct SafeCoinTokenProgram: BasicProgram {
  
  public static var tokenProgramId: PublicKey {
    "ToKLx75MGim1d1jRusuVX8xvdvvbSDESVaNXpRA9PHN"
  }
  
  public static var sysvarRent: PublicKey {
    "SysvarRent111111111111111111111111111111111"
  }
  
  public static var systemProgramId: PublicKey {
    "11111111111111111111111111111111"
  }
  
  public static var memoProgramId: PublicKey {
    "MEMDqRW2fYAU19mcFnoDVoqG4Br4t7TdyWjjv38P6Nc"
  }
  
  public static var splAssociatedTokenAccountProgramId: PublicKey {
    "AToD9iqHSc2fhEP9Jp7UYA6mRjHQ4CTWyzCsw8X3tH7K"
  }
  
  public static var usdcMint: PublicKey {
    ""
  }
  
  public static var usdtMint: PublicKey {
    ""
  }
  
}
