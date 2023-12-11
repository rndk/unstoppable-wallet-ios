import Foundation

public enum APIClientError: Error, Equatable {
    case invalidAPIURL
    case invalidResponse
    case responseError(DerivableResponseError)
    case transactionSimulationError(logs: [String])
    case couldNotRetrieveAccountInfo
    case blockhashNotFound
}
