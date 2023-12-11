import Foundation

public struct EncodableWrapper: Encodable {
    let wrapped: Encodable

    public func encode(to encoder: Encoder) throws {
        try wrapped.encode(to: encoder)
    }
}

public struct RequestAPI: Encodable {
    public init(method: String, params: [Encodable]) {
        self.method = method
        self.params = params
    }

    public let id = UUID().uuidString
    public let method: String
    public let jsonrpc: String = "2.0"
    public let params: [Encodable]

    enum CodingKeys: String, CodingKey {
        case id
        case method
        case jsonrpc
        case params
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        let wrappedDict = params.map(EncodableWrapper.init(wrapped:))
        try container.encode(wrappedDict, forKey: .params)
    }
}

// MARK: - Transfer

public enum Transfer {
    public static func compile() -> Data {
        var result = Data(capacity: 17) // FIXME: - capacity
        result.append(0x2) // program index
        let keyIndeces = [UInt8]([0, 1])
        result.append(Data.encodeLength(keyIndeces.count)) // key size
        result.append(contentsOf: keyIndeces) // keyIndeces
        result.append(UInt8(12)) // FIXME: transfer data size

        result += UInt32(2).bytes // Program Index

        let lamports = 3000
        result += UInt64(lamports).bytes

        return result
    }
}

// MARK: - Public

public struct OwnerInfoParams: Encodable {
    public let mint: String?
    public let programId: String?

    public init(mint: String?, programId: String?) {
        self.mint = mint
        self.programId = programId
    }
}

public typealias Commitment = String

public struct RequestConfiguration: Encodable {
    public let commitment: Commitment?
    public let encoding: String?
    public let dataSlice: DataSlice?
    public let filters: [[String: EncodableWrapper]]?
    public let limit: Int?
    public let before: String?
    public let until: String?
    public let skipPreflight: Bool?
    public let preflightCommitment: Commitment?
    public let searchTransactionHistory: Bool?
    public let replaceRecentBlockhash: Bool?

    public init?(
        commitment: Commitment? = nil,
        encoding: String? = nil,
        dataSlice: DataSlice? = nil,
        filters: [[String: EncodableWrapper]]? = nil,
        limit: Int? = nil,
        before: String? = nil,
        until: String? = nil,
        skipPreflight: Bool? = nil,
        preflightCommitment: Commitment? = nil,
        searchTransactionHistory: Bool? = nil,
        replaceRecentBlockhash: Bool? = nil
    ) {
        if commitment == nil,
           encoding == nil,
           dataSlice == nil,
           filters == nil,
           limit == nil,
           before == nil,
           until == nil,
           skipPreflight == nil,
           preflightCommitment == nil,
           searchTransactionHistory == nil,
           replaceRecentBlockhash == nil
        {
            return nil
        }

        self.commitment = commitment
        self.encoding = encoding
        self.dataSlice = dataSlice
        self.filters = filters
        self.limit = limit
        self.before = before
        self.until = until
        self.skipPreflight = skipPreflight
        self.preflightCommitment = preflightCommitment
        self.searchTransactionHistory = searchTransactionHistory
        self.replaceRecentBlockhash = replaceRecentBlockhash
    }
}

public struct DataSlice: Encodable {
    public let offset: Int
    public let length: Int

    public init(offset: Int, length: Int) {
        self.offset = offset
        self.length = length
    }
}
