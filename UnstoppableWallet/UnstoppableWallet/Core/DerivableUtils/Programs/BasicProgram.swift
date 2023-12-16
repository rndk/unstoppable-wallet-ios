import Foundation

public protocol BasicProgram {
  static var tokenProgramId: PublicKey { get }
  static var sysvarRent: PublicKey { get }
  static var systemProgramId: PublicKey { get }
  static var memoProgramId: PublicKey { get }
  static var splAssociatedTokenAccountProgramId: PublicKey { get }
  static var usdcMint: PublicKey { get }
  static var usdtMint: PublicKey { get }
}
