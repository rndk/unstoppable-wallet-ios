import Foundation

class SolanaNetwork: DerivableCoinNetwork {
  var mainNetUrl = "https://api.mainnet-beta.solana.com/"
  var testNetUrl = "https://api.testnet.solana.com/"
  var devNetUrl = "https://api.devnet.solana.com/"
  
  func isMainNet(source: String) -> Bool {
    source == mainNetUrl
  }
}
