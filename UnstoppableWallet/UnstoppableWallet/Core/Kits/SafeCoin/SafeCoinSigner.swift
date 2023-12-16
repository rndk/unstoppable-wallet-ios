import Foundation
import HdWalletKit
import BigInt
import HsCryptoKit
import HsToolKit

import TweetNacl
import CommonCrypto


public class SafeCoinSigner {
  private let keyPair: DerivableKeyPair
  
  init(pair: DerivableKeyPair) {
    self.keyPair = pair
  }
  
  //  func signature(hash: Data) throws -> Data {
  //      try Crypto.ellipticSign(hash, privateKey: privateKey)
  //  }
}

extension SafeCoinSigner {
  
  public func address() -> String {
    keyPair.publicKey.base58EncodedString
  }
  
  public func addressKeyPair() -> DerivableKeyPair {
    self.keyPair
  }
  
}
