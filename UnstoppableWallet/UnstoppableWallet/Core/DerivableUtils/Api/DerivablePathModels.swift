import Foundation

public typealias TransactionID = String
public typealias DerivableLamports = UInt64
public typealias Decimals = UInt8

public struct DerivableResponse<T: Decodable>: Decodable {
    public let jsonrpc: String
    public let id: String?
    public let result: T?
    public let error: DerivableResponseError?
    public let method: String?

    // socket
    public let params: DerivableSocketParams<T>?
}

public struct DerivableSocketParams<T: Decodable>: Decodable {
    public let result: DerivableRpc<T>?
    public let subscription: UInt64?
}

public struct DerivableResponseError: Codable, Equatable {
    public init(code: Int?, message: String?, data: DerivableResponseErrorData?) {
        self.code = code
        self.message = message
        self.data = data
    }

    public let code: Int?
    public let message: String?
    public let data: DerivableResponseErrorData?
}

public struct DerivableResponseErrorData: Codable, Equatable {
    public init(logs: [String]? = nil, numSlotsBehind: Int? = nil) {
        self.logs = logs
        self.numSlotsBehind = numSlotsBehind
    }

    // public let err: ResponseErrorDataError
    public let logs: [String]?
    public let numSlotsBehind: Int?
}

public struct DerivableRpc<T: Decodable>: Decodable {
    public let context: DerivableContext
    public let value: T
}

public struct DerivableContext: Decodable {
    public let slot: UInt64
}

public struct DerivableBlockCommitment: Decodable {
    public let commitment: [UInt64]?
    public let totalStake: UInt64
}

public struct DerivableClusterNodes: Decodable {
    public let pubkey: String
    public let gossip: String
    public let tpu: String?
    public let rpc: String?
    public let version: String?
}

public struct DerivableConfirmedBlock: Decodable {
    public let blockhash: String
    public let previousBlockhash: String
    public let parentSlot: UInt64
    public let transactions: [DerivableTransactionInfo]
    public let rewards: [DerivableReward]
    public let blockTime: UInt64?
}

public struct DerivableReward: Decodable {
    public let pubkey: String
    public let lamports: DerivableLamports
    public let postBalance: DerivableLamports
    public let rewardType: String?
}

public struct DerivableEpochInfo: Decodable {
    public let absoluteSlot: UInt64
    public let blockHeight: UInt64
    public let epoch: UInt64
    public let slotIndex: UInt64
    public let slotsInEpoch: UInt64
}

public struct DerivableEpochSchedule: Decodable {
    public let slotsPerEpoch: UInt64
    public let leaderScheduleSlotOffset: UInt64
    public let warmup: Bool
    public let firstNormalEpoch: UInt64
    public let firstNormalSlot: UInt64
}

public struct DerivableFee: Decodable {
    public let feeCalculator: DerivableFeeCalculatorResponse?
    public let feeRateGovernor: DerivableFeeRateGovernor?
    public let blockhash: String?
    public let lastValidSlot: UInt64?
}

public struct DerivableFeeCalculatorResponse: Decodable {
    public let lamportsPerSignature: DerivableLamports
}

public struct DerivableFeeRateGovernor: Decodable {
    public let burnPercent: UInt64
    public let maxLamportsPerSignature: DerivableLamports
    public let minLamportsPerSignature: DerivableLamports
    public let targetLamportsPerSignature: DerivableLamports
    public let targetSignaturesPerSlot: UInt64
}

public struct DerivableIdentity: Decodable {
    public let identity: String
}

public struct DerivableInflationGovernor: Decodable {
    public let foundation: Float64
    public let foundationTerm: Float64
    public let initial: Float64
    public let taper: Float64
    public let terminal: Float64
}

public struct DerivableInflationRate: Decodable {
    public let epoch: Float64
    public let foundation: Float64
    public let total: Float64
    public let validator: Float64
}

public struct DerivableLargestAccount: Decodable {
    public let lamports: DerivableLamports
    public let address: String
}

//public struct ProgramAccounts<T: BufferLayout>: Decodable {
//    public let accounts: [DerivableProgramAccount<T>]
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        let throwables = try container.decode([Throwable<DerivableProgramAccount<T>>].self)
//
//        var accounts = [DerivableProgramAccount<T>]()
//        throwables.forEach {
//            switch $0.result {
//            case let .success(account):
//                accounts.append(account)
//            case let .failure(error):
////                Logger.log(
////                    event: "Program Accounts",
////                    message: "Error decoding an account in program accounts list: \(error.localizedDescription)",
////                    logLevel: .error
////                )
//            }
//        }
//        self.accounts = accounts
//    }
//}

public struct DerivableProgramAccount<T: BufferLayout>: Decodable {
    public let account: BufferInfo<T>
    public let pubkey: String
}

public struct BufferInfo<T: BufferLayout>: Decodable, Equatable {
    public let lamports: DerivableLamports
    public let owner: String
    public let data: T
    public let executable: Bool
    public let rentEpoch: UInt64

    public init(lamports: DerivableLamports, owner: String, data: T, executable: Bool, rentEpoch: UInt64) {
        self.lamports = lamports
        self.owner = owner
        self.data = data
        self.executable = executable
        self.rentEpoch = rentEpoch
    }
}

public struct BufferInfoParsed<T: Decodable>: Decodable {
    public let lamports: DerivableLamports
    public let owner: String
    public let data: T?
    public let executable: Bool
    public let rentEpoch: UInt64
}

public struct DerivablePerformanceSample: Decodable {
    public let numSlots: UInt64
    public let numTransactions: UInt64
    public let samplePeriodSecs: UInt
    public let slot: UInt64
}

public struct DerivableSignatureInfo: Decodable {
    public let signature: String
    public let slot: UInt64?
    public let err: DerivableAnyTransactionError?
    public let memo: String?
    public let blockTime: UInt64?

    public init(signature: String) {
        self.signature = signature
        slot = nil
        err = nil
        memo = nil
        blockTime = nil
    }
}

public struct DerivableSignatureStatus: Decodable {
    public let slot: UInt64
    public let confirmations: UInt64?
    public let err: DerivableAnyTransactionError?
    public let confirmationStatus: String?
}

public struct DerivableTransactionInfo: Decodable {
    public let blockTime: UInt64?
    public let meta: DerivableTransactionMeta?
    public let transaction: DerivableConfirmedTransaction
    public let slot: UInt64?
}

public struct DerivableTransactionMeta: Decodable {
    public let err: DerivableAnyTransactionError?
    public let fee: DerivableLamports?
    public let innerInstructions: [DerivableInnerInstruction]?
    public let logMessages: [String]?
    public let postBalances: [DerivableLamports]?
    public let postTokenBalances: [DerivableTokenBalance]?
    public let preBalances: [DerivableLamports]?
    public let preTokenBalances: [DerivableTokenBalance]?
}

public enum DerivableAnyTransactionError: Codable {
    case detailed(DerivableTransactionError)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(DerivableTransactionError.self) {
            self = .detailed(x)
            return
        }
        throw DecodingError.typeMismatch(DerivableAnyTransactionError.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ErrUnion"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .detailed(x):
            try container.encode(x)
        case let .string(x):
            try container.encode(x)
        }
    }
}

public typealias DerivableTransactionError = [String: [DerivableErrorDetail]]
public struct DerivableErrorDetail: Codable {
    public init(wrapped: Any) {
        self.wrapped = wrapped
    }

    let wrapped: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            wrapped = value
        } else if let value = try? container.decode(Double.self) {
            wrapped = value
        } else if let value = try? container.decode(String.self) {
            wrapped = value
        } else if let value = try? container.decode(Int.self) {
            wrapped = value
        } else if let value = try? container.decode([String: Int].self) {
            wrapped = value
        } else {
            wrapped = ""
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrapped = wrapped as? Encodable {
            let wrapper = EncodableWrapper(wrapped: wrapped)
            try container.encode(wrapper)
        }
    }
}

public struct DerivableInnerInstruction: Decodable {
    public let index: UInt32
    public let instructions: [DerivableParsedInstruction]
}

public struct DerivableTokenBalance: Decodable {
    public let accountIndex: UInt64
    public let mint: String
    public let uiTokenAmount: DerivableTokenAccountBalance
}

public struct DerivableSimulationResult: Decodable {
    public let err: DerivableErrorDetail? // TransactionError? // string | object
    public let logs: [String]
}

public struct DerivableStakeActivation: Decodable {
    public let active: UInt64
    public let inactive: UInt64
    public let state: String
}

public struct DerivableSupply: Decodable {
    public let circulating: DerivableLamports
    public let nonCirculating: DerivableLamports
    public let nonCirculatingAccounts: [String]
    public let total: DerivableLamports
}

public struct DerivableTokenAccountBalance: Codable, Equatable, Hashable {
    public init(uiAmount: Float64?, amount: String, decimals: UInt8?, uiAmountString: String?) {
        self.uiAmount = uiAmount
        self.amount = amount
        self.decimals = decimals
        self.uiAmountString = uiAmountString
    }

    public init(amount: String, decimals: UInt8?) {
        uiAmount = UInt64(amount)?.convertToBalance(decimals: decimals)
        self.amount = amount
        self.decimals = decimals
        uiAmountString = "\(uiAmount ?? 0)"
    }

    public let uiAmount: Float64?
    public let amount: String
    public let decimals: UInt8?
    public let uiAmountString: String?

    public var amountInUInt64: UInt64? {
        UInt64(amount)
    }
}

public struct DerivableTokenAccount<T: BufferLayout>: Decodable, Equatable {
    public let pubkey: String
    public let account: BufferInfo<T>

    public init(pubkey: String, account: BufferInfo<T>) {
        self.pubkey = pubkey
        self.account = account
    }
}

public struct DerivableTokenAmount: Decodable {
    public let address: String?
    public let amount: String
    public let decimals: UInt8
    public let uiAmount: Float64
}

//TODO solana?
public struct DerivableVersion: Decodable {
    public let solanaCore: String

    private enum DerivableCodingKeys: String, CodingKey {
        case solanaCore = "solana-core"
    }
}

public struct DerivableVoteAccounts: Decodable {
    public let current: [DerivableVoteAccount]
    public let delinquent: [DerivableVoteAccount]
}

public struct DerivableVoteAccount: Decodable {
    public let commission: Int
    public let epochVoteAccount: Bool
    public let epochCredits: [[UInt64]]
    public let nodePubkey: String
    public let lastVote: UInt64
    public let activatedStake: UInt64
    public let votePubkey: String
}

public struct DerivablePerfomanceSamples: Decodable {
    public let numSlots: Int
    public let numTransactions: Int
    public let samplePeriodSecs: Int
    public let slot: Int
}
