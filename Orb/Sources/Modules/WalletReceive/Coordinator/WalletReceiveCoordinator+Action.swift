import ComposableArchitecture

extension WalletReceiveCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didClose
        }
        
        case root(WalletReceiveFeature.Action)
        case delegate(Delegate)
    }
}

