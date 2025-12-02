import ComposableArchitecture

@Reducer
struct WalletReceiveCoordinator {
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            WalletReceiveFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case .root:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - Root
    
    private func reduce(state: inout State, action: WalletReceiveFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didClose:
            return .send(.delegate(.didClose))
        }
    }
}

