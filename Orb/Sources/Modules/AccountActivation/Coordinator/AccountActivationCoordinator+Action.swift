import ComposableArchitecture

extension AccountActivationCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didComplete
        }
        
        case root(AccountActivationFeature.Action)
        case delegate(Delegate)
    }
}


