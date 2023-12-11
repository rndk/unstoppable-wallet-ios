import UIKit
import MarketKit

extension Coin {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        if (self.uid.compare("safe-coin-2", options: .caseInsensitive) == .orderedSame) {
          return "https://raw.githubusercontent.com/Fair-Exchange/safecoinwiki/master/Logos/SafeCoin/256.png"
        }
        return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
    }

}
