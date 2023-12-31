import Foundation
import RxSwift

class SuiAddressParser {
  
  private func validate(address: String) -> Single<Address> {
//    do {
//      let _ = try PublicKey(string: address)
//      return Single.just(Address(raw: address, domain: nil))
//    } catch {
//      return Single.error(error)
//    }
    
    if (isHex(address: address) && getHexByteLength(address: address) == 32) {
      return Single.just(Address(raw: address, domain: nil))
    } else {
      return Single.error(SuiAddressError.wrongAddress)
    }
  }
  
  private func isHex(address: String) -> Bool {
    let matches = address.range(
      of: "(0x|0X)[a-zA-Z0-9]*",
      options: .regularExpression,
      range: nil,
      locale: nil
    ) != nil
    return address.count % 2 == 0 && matches
  }
  
  private func getHexByteLength(address: String) -> Int {
    if address.starts(with: "0x") || address.starts(with: "0X") {
      return (address.count - 2) / 2
    }
    return address.count / 2
  }
  
}

extension SuiAddressParser: IAddressParserItem {
  func handle(address: String) -> Single<Address> {
    validate(address: address)
  }
  
  func isValid(address: String) -> Single<Bool> {
    validate(address: address)
      .map { _ in true }
      .catchErrorJustReturn(false)
  }
}

enum SuiAddressError: Error {
    case wrongAddress
}
