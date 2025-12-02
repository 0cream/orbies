import ComposableArchitecture

extension WalletImportCoordinator {
    
    @CasePathable
    enum Action {
        case root(WalletImportFeature.Action)
        case destination(PresentationAction<Destination.Action>)
        case path(StackActionOf<Path>)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case didClose
            case didComplete
        }
    }
    
    @Reducer
    enum Path {
        // Add path screens if needed
    }
}

