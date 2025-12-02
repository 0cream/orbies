import ComposableArchitecture

@Reducer
struct TransactionDetailFeature {
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - View Actions
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didTapClose:
            return .send(.delegate(.didFinish))
            
        case .didTapCopySignature:
            // Haptic feedback could be added here
            return .none
        }
    }
}

