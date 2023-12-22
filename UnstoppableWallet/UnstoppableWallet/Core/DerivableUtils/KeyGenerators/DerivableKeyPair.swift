import CommonCrypto
import Foundation
import TweetNacl
import HdWalletKit

public struct DerivableKeyPair: Codable, Hashable {
  public let phrase: [String]
  public let publicKey: PublicKey
  public let secretKey: Data
  
  public init(phrase: [String], publicKey: PublicKey, secretKey: Data) {
    self.phrase = phrase
    self.publicKey = publicKey
    self.secretKey = secretKey
  }
  
  public init(secretKey: Data, words: [String]) throws {
    let keys = try NaclSign.KeyPair.keyPair(fromSecretKey: secretKey)
    publicKey = try PublicKey(data: keys.publicKey)
    self.secretKey = keys.secretKey
    self.phrase = words
  }
  
  public init(path: DerivablePath, seed: Data, words: [String]) throws {
    let phrase = words
    let publicKey: PublicKey
    let secretKey: Data
    
    let keys = try Ed25519HDKey.derivePath(path.rawValue, seed: seed.toHexString()).get()
    let keyPair = try NaclSign.KeyPair.keyPair(fromSeed: keys.key)
    let newKey = try PublicKey(data: keyPair.publicKey)
    
    publicKey = newKey
    secretKey = keyPair.secretKey
    
    self.phrase = phrase
    self.publicKey = publicKey
    self.secretKey = secretKey
  }
}
