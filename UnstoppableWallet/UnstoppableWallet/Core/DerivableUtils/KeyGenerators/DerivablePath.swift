import Foundation

public struct DerivablePath: Hashable, Codable {
  
  public enum DerivableType: String, CaseIterable, Codable {
    case bip44Change
    case bip44
    case deprecated
    
    var prefix: String {
      switch self {
      case .deprecated:
        return "m/"
      case .bip44, .bip44Change:
        return "m/44'/"
      }
    }
  }
  
  public let type: DerivableType
  public let walletIndex: Int
  public let coinId: Int
  public let accountIndex: Int?
  
  public init(
    type: DerivablePath.DerivableType,
    coinId: Int,
    walletIndex: Int,
    accountIndex: Int? = nil
  ) {
    self.type = type
    self.coinId = coinId
    self.walletIndex = walletIndex
    self.accountIndex = accountIndex
  }
  
  public static var `default`: Self {
    .init(
      type: .bip44Change,
      coinId: 19165,
      walletIndex: 0,
      accountIndex: 0
    )
  }
  
  public var rawValue: String {
    var value = type.prefix
    switch type {
    case .deprecated:
      value += "\(coinId)'/\(walletIndex)'/0/\(accountIndex ?? 0)"
    case .bip44:
      value += "\(coinId)'/\(walletIndex)'"
    case .bip44Change:
      value += "\(coinId)'/\(walletIndex)'/0'"
    }
    return value
  }
}
