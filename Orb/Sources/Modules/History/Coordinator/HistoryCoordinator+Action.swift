import ComposableArchitecture

extension HistoryCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            // delegate actions
        }
        
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case root(HistoryMainFeature.Action)
        case delegate(Delegate)
    }
}

extension HistoryCoordinator {
    @Reducer
    enum Path {
        // No navigation paths yet
    }
}

extension HistoryCoordinator {
    @Reducer
    enum Destination {
        case transactionDetail(TransactionDetailCoordinator)
    }
}

