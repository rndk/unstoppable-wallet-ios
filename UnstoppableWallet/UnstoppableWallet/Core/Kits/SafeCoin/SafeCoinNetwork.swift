import Foundation

class SafeCoinNetwork: DerivableCoinNetwork {
  var mainNetUrl = "https://api.mainnet-beta.safecoin.org/"
  var testNetUrl = "https://api.testnet.safecoin.org/"
  var devNetUrl = "https://devnet.safely.org/"
  
  func isMainNet(source: String) -> Bool {
    source == mainNetUrl
  }
}
