import ComposableArchitecture

@Reducer
struct AccountActivationFeature {
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
        case .didAppear:
            // After 2 seconds, switch to activated state
            return .run { send in
                try await Task.sleep(for: .seconds(2))
                await send(.view(.accountActivated))
            }
            
        case .accountActivated:
            state.isActivating = false
            // Wait another second before completing
            return .run { send in
                try await Task.sleep(for: .seconds(1))
                await send(.delegate(.didComplete))
            }
        }
    }
}

