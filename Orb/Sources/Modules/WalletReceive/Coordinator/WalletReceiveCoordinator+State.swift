import ComposableArchitecture

extension WalletReceiveCoordinator {
    @ObservableState
    struct State {
        var root: WalletReceiveFeature.State
        
        init(root: WalletReceiveFeature.State = WalletReceiveFeature.State()) {
            self.root = root
        }
    }
}

