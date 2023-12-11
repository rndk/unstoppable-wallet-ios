import Foundation

public enum SafeCoinNetwork: Equatable {
  case mainNet, testNet, devNet, custom(name: String, url: String)
  
  public static func ==(lhs: SafeCoinNetwork, rhs: SafeCoinNetwork) -> Bool {
    switch(lhs, rhs) {
    case ( .mainNet, .mainNet): return true
    case ( .testNet, .testNet): return true
    case ( .devNet, .devNet): return true
    case (let .custom(_, url1), let .custom(_, url2)): return url1 == url2
    default: return false
    }
  }
}
