import ComposableArchitecture

extension TransactionDetailCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish
        }
        
        case root(TransactionDetailFeature.Action)
        case delegate(Delegate)
    }
}

