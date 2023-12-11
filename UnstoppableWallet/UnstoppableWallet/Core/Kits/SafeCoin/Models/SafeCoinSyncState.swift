import Foundation

public enum SafeCoinSyncState {
    case synced
    case syncing(progress: Double?)
    case notSynced(error: Error)

    public var notSynced: Bool {
        if case .notSynced = self { return true } else { return false }
    }

    public var syncing: Bool {
        if case .syncing = self { return true } else { return false }
    }

    public var synced: Bool {
        self == .synced
    }
}

extension SafeCoinSyncState: Equatable {

    public static func ==(lhs: SafeCoinSyncState, rhs: SafeCoinSyncState) -> Bool {
        switch (lhs, rhs) {
            case (.synced, .synced): return true
            case (.syncing(let lhsProgress), .syncing(let rhsProgress)): return lhsProgress == rhsProgress
            case (.notSynced(let lhsError), .notSynced(let rhsError)): return "\(lhsError)" == "\(rhsError)"
            default: return false
        }
    }

}

extension SafeCoinSyncState: CustomStringConvertible {

    public var description: String {
        switch self {
            case .synced: return "synced"
            case .syncing(let progress): return "syncing \(progress ?? 0)"
            case .notSynced(let error): return "not synced: \(error)"
        }
    }

}

extension SafeCoinSyncState {
  
  public enum SyncError: Error {
    case notStarted
    case noNetworkConnection
  }
  
  public enum SendError: Error {
    case notSupportedContract
    case abnormalSend
    case invalidParameter
  }
  
}
