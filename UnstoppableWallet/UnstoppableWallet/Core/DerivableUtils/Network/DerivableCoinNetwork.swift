import Foundation

public protocol DerivableCoinNetwork {
  var mainNetUrl: String { get }
  var testNetUrl: String { get }
  var devNetUrl: String { get }
  func isMainNet(source: String) -> Bool
}
