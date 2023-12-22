import Foundation

public class DerivableCoinSigner {
  private let keyPair: DerivableKeyPair
  
  init(pair: DerivableKeyPair) {
    self.keyPair = pair
  }
}

extension DerivableCoinSigner {
  
  public func address() -> String {
    keyPair.publicKey.base58EncodedString
  }
  
  public func addressKeyPair() -> DerivableKeyPair {
    self.keyPair
  }
  
}
