import SwiftUI

struct BlockchainSettingsModule {
    static func view() -> some View {
        let viewModel = BlockchainSettingsViewModel(
            btcBlockchainManager: App.shared.btcBlockchainManager,
            evmBlockchainManager: App.shared.evmBlockchainManager,
            evmSyncSourceManager: App.shared.evmSyncSourceManager,
            derivableSyncSourceManager: App.shared.derivableSyncSourceManager
        )
        return BlockchainSettingsView(viewModel: viewModel)
    }
}
