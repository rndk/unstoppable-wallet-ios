import Foundation

class SuiNetwork: DerivableCoinNetwork {
  var mainNetUrl = "https://fullnode.mainnet.sui.io/"
  var testNetUrl = "https://fullnode.testnet.sui.io/"
  var devNetUrl = "https://fullnode.devnet.sui.io/"
  
  func isMainNet(source: String) -> Bool {
    source != testNetUrl && source != devNetUrl
  }
}
