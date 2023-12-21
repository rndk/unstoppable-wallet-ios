import Foundation

//public enum SafeCoinNetwork: Equatable {
//  case mainNet, testNet, devNet, custom(name: String, url: String)
//  
//  public static func ==(lhs: SafeCoinNetwork, rhs: SafeCoinNetwork) -> Bool {
//    switch(lhs, rhs) {
//    case ( .mainNet, .mainNet): return true
//    case ( .testNet, .testNet): return true
//    case ( .devNet, .devNet): return true
//    case (let .custom(_, url1), let .custom(_, url2)): return url1 == url2
//    default: return false
//    }
//  }
//}

class SafeCoinNetwork {
  static let mainNetUrl = "https://api.mainnet-beta.safecoin.org/"
  static let testNetUrl = "https://api.testnet.safecoin.org/"
  static let devNetUrl = "https://devnet.safely.org/"
  
  static func isMainNet(source: String) -> Bool {
    source == mainNetUrl
  }
}

//private static func provideUrl(network: SafeCoinNetwork) -> String {
//    switch network {
//    case .mainNet: return "https://api.mainnet-beta.safecoin.org/"
//    case .testNet: return "https://api.testnet.safecoin.org/"
//    case .devNet: return "https://devnet.safely.org/"
//    case .custom(_, let url): return url
//    }
//  }
