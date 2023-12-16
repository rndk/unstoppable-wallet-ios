import Foundation

public struct DerivableConfirmedTransaction: Decodable {
    public let message: DerivableMessage
    public let signatures: [String]
}

public extension DerivableConfirmedTransaction {
    struct DerivableMessage: Decodable {
        public let accountKeys: [AccountMeta]
        public let instructions: [DerivableParsedInstruction]
        public let recentBlockhash: String
    }
}

public struct DerivableParsedInstruction: Decodable {
    public struct DerivableParsed: Decodable {
        public struct DerivableInfo: Decodable {
            public let owner: String?
            public let account: String?
            public let source: String?
            public let destination: String?

            // create account
            public let lamports: UInt64?
            public let newAccount: String?
            public let space: UInt64?

            // initialize account
            public let mint: String?
            public let rentSysvar: String?

            // approve
            public let amount: String?
            public let delegate: String?

            // transfer
            public let authority: String?
            public let wallet: String? // spl-associated-token-account

            // transferChecked
            public let tokenAmount: DerivableTokenAccountBalance?
        }

        public let info: DerivableInfo
        public let type: String?
    }

    public let program: String?
    public let programId: String
    public let parsed: DerivableParsed?

    // swap
    public let data: String?
    public let accounts: [String]?

    public enum DerivableCodingKeys: CodingKey {
        case program
        case programId
        case parsed
        case data
        case accounts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DerivableCodingKeys.self)
        program = try container.decodeIfPresent(String.self, forKey: .program)
        programId = try container.decode(String.self, forKey: .programId)
        parsed = try? container.decodeIfPresent(DerivableParsedInstruction.DerivableParsed.self, forKey: .parsed)
        data = try container.decodeIfPresent(String.self, forKey: .data)
        accounts = try container.decodeIfPresent([String].self, forKey: .accounts)
    }
}

extension Sequence where Iterator.Element == DerivableParsedInstruction {
    func containProgram(with name: String) -> Bool {
        getFirstProgram(with: name) != nil
    }

    func getFirstProgram(with name: String) -> DerivableParsedInstruction? {
        first(where: { $0.program == name })
    }
}
