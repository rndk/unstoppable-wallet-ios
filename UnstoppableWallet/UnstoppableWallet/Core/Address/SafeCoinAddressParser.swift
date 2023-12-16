import Foundation
import RxSwift

class SafeCoinAddressParser {
  
  private func validate(address: String) -> Single<Address> {
    do {
      let _ = try PublicKey(string: address)
      return Single.just(Address(raw: address, domain: nil))
    } catch {
      return Single.error(error)
    }
  }
  
}

extension SafeCoinAddressParser: IAddressParserItem {
  func handle(address: String) -> Single<Address> {
    validate(address: address)
  }
  
  func isValid(address: String) -> Single<Bool> {
    validate(address: address)
      .map { _ in true }
      .catchErrorJustReturn(false)
  }
}
