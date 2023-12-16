import Foundation

public protocol DerivationNetworkManager {
    func requestData(request: URLRequest) async throws -> Data
}
