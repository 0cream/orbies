import ComposableArchitecture

@Reducer
struct EarnCoordinator {
    
    var body: some Reducer<State, Action> {
        Scope(state: \.main, action: \.main) {
            EarnMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .main(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case .main, .path:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
    
    // MARK: - Main
    
    private func reduce(state: inout State, action: EarnMainFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didRequestClose:
            return .send(.delegate(.didFinish))
        }
    }
}

