import Foundation

public struct PublicKey: Codable, Equatable, CustomStringConvertible, Hashable {
  public static let NULL_PUBLICKEY_BYTES: [UInt8] = Array(repeating: UInt8(0), count: numberOfBytes)
  public static let numberOfBytes = 32
  public let bytes: [UInt8]
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(base58EncodedString)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    try self.init(string: string)
  }
  
  public init(string: String?) throws {
    guard let string = string, string.utf8.count >= PublicKey.numberOfBytes
    else {
      throw PublicKeyError.invalidAddress(string)
    }
    let bytes = Base58.decode(string)
    self.bytes = bytes
  }
  
  public init(data: Data) throws {
    guard data.count <= PublicKey.numberOfBytes else {
      throw PublicKeyError.invalidAddress(.init(data: data, encoding: .utf8))
    }
    bytes = [UInt8](data)
  }
  
  public init(bytes: [UInt8]?) throws {
    guard let bytes = bytes, bytes.count <= PublicKey.numberOfBytes else {
      throw PublicKeyError.invalidAddress(.init(data: Data(bytes ?? []), encoding: .utf8))
    }
    self.bytes = bytes
  }
  
  public var base58EncodedString: String {
    Base58.encode(bytes)
  }
  
  public var data: Data {
    Data(bytes)
  }
  
  public var description: String {
    base58EncodedString
  }
  
  public func short(numOfSymbolsRevealed: Int = 4) -> String {
    let pubkey = base58EncodedString
    return pubkey.prefix(numOfSymbolsRevealed) + "..." + pubkey.suffix(numOfSymbolsRevealed)
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(bytes)
  }
  
  public static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
    lhs.bytes == rhs.bytes
  }
}

private var maxSeedLength = 32
private let gf1 = NaclLowLevel.gf([1])

private extension Int {
  func toBool() -> Bool {
    self != 0
  }
}

extension PublicKey: BytesEncodable {}

public enum PublicKeyError: Error, Equatable {
  case notFound
  case invalidAddress(String?)
  case maxSeedLengthExceeded
  case invalidSeed(reason: String?)
}

extension PublicKey: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try bytes.forEach { try $0.serialize(to: &writer) }
  }
  
  public init(from reader: inout BinaryReader) throws {
    let byteArray = try Array(0 ..< PublicKey.numberOfBytes).map { _ in try UInt8(from: &reader) }
    bytes = byteArray
  }
}

public extension PublicKey {
  static func associatedTokenAddress(
    tokenProgramId: PublicKey,
    associatedProgramId: PublicKey,
    walletAddress: PublicKey,
    tokenMintAddress: PublicKey
  ) throws -> PublicKey {
    try findProgramAddress(
      seeds: [
        walletAddress.data,
        tokenProgramId.data,
        tokenMintAddress.data,
      ],
      programId: associatedProgramId
    ).0
  }
  
  // MARK: - Helpers
  
  static func findProgramAddress(
    seeds: [Data],
    programId: Self
  ) throws -> (Self, UInt8) {
    for nonce in stride(from: UInt8(255), to: 0, by: -1) {
      let seedsWithNonce = seeds + [Data([nonce])]
      do {
        let address = try createProgramAddress(
          seeds: seedsWithNonce,
          programId: programId
        )
        return (address, nonce)
      } catch {
        continue
      }
    }
    throw PublicKeyError.notFound
  }
  
  static func createProgramAddress(
    seeds: [Data],
    programId: PublicKey
  ) throws -> PublicKey {
    // construct data
    var data = Data()
    for seed in seeds {
      if seed.bytes.count > maxSeedLength {
        throw PublicKeyError.maxSeedLengthExceeded
      }
      data.append(seed)
    }
    data.append(programId.data)
    data.append("ProgramDerivedAddress".data(using: .utf8)!)
    
    // hash it
    let hash = data.sha256()
    let publicKeyBytes = Bignum(number: hash.hexString, withBase: 16).data
    
    // check it
    if isOnCurve(publicKeyBytes: publicKeyBytes).toBool() {
      throw PublicKeyError.invalidSeed(reason: "address must fall off the curve")
    }
    return try PublicKey(data: publicKeyBytes)
  }
  
  static func createWithSeed(
    fromPublicKey: PublicKey,
    seed: String,
    programId: PublicKey
  ) throws -> PublicKey {
    var data = Data()
    data += fromPublicKey.data
    guard let seedData = seed.data(using: .utf8) else {
      throw PublicKeyError.invalidSeed(reason: nil)
    }
    data += seedData
    data += programId.data
    let hash = data.sha256()
    return try PublicKey(data: hash)
  }
  
  static func isOnCurve(publicKey: String) -> Int {
    let data = Base58.decode(publicKey)
    return isOnCurve(publicKeyBytes: Data(data))
  }
  
  static func isOnCurve(publicKeyBytes: Data) -> Int {
    var r = [[Int64]](repeating: NaclLowLevel.gf(), count: 4)
    
    var t = NaclLowLevel.gf(),
        chk = NaclLowLevel.gf(),
        num = NaclLowLevel.gf(),
        den = NaclLowLevel.gf(),
        den2 = NaclLowLevel.gf(),
        den4 = NaclLowLevel.gf(),
        den6 = NaclLowLevel.gf()
    
    NaclLowLevel.set25519(&r[2], gf1)
    NaclLowLevel.unpack25519(&r[1], publicKeyBytes.bytes)
    NaclLowLevel.S(&num, r[1])
    NaclLowLevel.M(&den, num, NaclLowLevel.D)
    NaclLowLevel.Z(&num, num, r[2])
    NaclLowLevel.A(&den, r[2], den)
    
    NaclLowLevel.S(&den2, den)
    NaclLowLevel.S(&den4, den2)
    NaclLowLevel.M(&den6, den4, den2)
    NaclLowLevel.M(&t, den6, num)
    NaclLowLevel.M(&t, t, den)
    
    NaclLowLevel.pow2523(&t, t)
    NaclLowLevel.M(&t, t, num)
    NaclLowLevel.M(&t, t, den)
    NaclLowLevel.M(&t, t, den)
    NaclLowLevel.M(&r[0], t, den)
    
    NaclLowLevel.S(&chk, r[0])
    NaclLowLevel.M(&chk, chk, den)
    if NaclLowLevel.neq25519(chk, num).toBool() {
      NaclLowLevel.M(&r[0], r[0], NaclLowLevel.I)
    }
    
    NaclLowLevel.S(&chk, r[0])
    NaclLowLevel.M(&chk, chk, den)
    
    if NaclLowLevel.neq25519(chk, num).toBool() {
      return 0
    }
    return 1
  }
}
