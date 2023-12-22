import Foundation

class SafeCoinNetwork {
  static let mainNetUrl = "https://api.mainnet-beta.safecoin.org/"
  static let testNetUrl = "https://api.testnet.safecoin.org/"
  static let devNetUrl = "https://devnet.safely.org/"
  
  static func isMainNet(source: String) -> Bool {
    source == mainNetUrl
  }
}
