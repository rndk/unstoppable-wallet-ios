import Foundation
//TODO сорцы
class SuiConstant {
    static let LOCAL_RPC_URL = "http://127.0.0.1:9000/"
    static let LOCAL_FAUCET_URL = "http://127.0.0.1:5003/gas"
    static let DEV_RPC_URL = "https://sui-devnet-kr-1.cosmostation.io"
    static let DEV_FAUCET_URL = "https://faucet.devnet.sui.io/gas"
    static let TEST_RPC_URL = "https://rpc-sui-testnet.cosmostation.io"
    static let TEST_FAUCET_URL = "https://faucet.testnet.sui.io/gas"
    static let MAIN_RPC_URL = "https://sui-mainnet-us-2.cosmostation.io"
}

public enum ChainType: Int {
    case local
    case devnet
    case testnet
    case mainnet
}
