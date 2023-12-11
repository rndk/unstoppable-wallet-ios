import Foundation
import HdWalletKit
import BigInt
import HsCryptoKit
import HsToolKit

import TweetNacl
import CommonCrypto


class SafeCoinSigner {
  private let keyPair: DerivationPathKeyPair
  
  init(pair: DerivationPathKeyPair) {
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
  
}
