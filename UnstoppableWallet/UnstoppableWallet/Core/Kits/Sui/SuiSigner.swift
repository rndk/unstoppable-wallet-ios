import Foundation

public class SuiSigner {
  private let address: String
  private let mnemonic: String
  
  init(mnemonic: String) {
    self.address = SuiKey.getSuiAddress(mnemonic)
    self.mnemonic = mnemonic
  }
  
}

extension SuiSigner {
  
  var coinAddress: String {
    self.address
  }
  
  var getMnemonic: String {
    self.mnemonic
  }
  
}
