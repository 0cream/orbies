import ComposableArchitecture

extension DebugFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        enum View {
            case didTapClearKeychain
            case didTapClearTransactions
            case didTapCrash
            case didTapUpdateEvents
        }
        
        enum Reducer {
            case keychainCleared
            case transactionsCleared
            case eventsUpdated(Int)
            case operationFailed(String)
        }
        
        case view(View)
        case reducer(Reducer)
        case binding(BindingAction<DebugFeature.State>)
    }
}


