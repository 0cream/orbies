import ComposableArchitecture

@Reducer
struct HoldingsCoordinator {
    
    var body: some Reducer<State, Action> {
        Scope(state: \.main, action: \.main) {
            HoldingsMainFeature()
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
    
    private func reduce(state: inout State, action: HoldingsMainFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didRequestBack:
            return .send(.delegate(.didFinish))
            
        case let .didRequestNavigateToTokenDetails(item):
            // Forward to Portfolio coordinator to handle navigation
            return .send(.delegate(.didRequestNavigateToTokenDetails(item: item)))
        }
    }
}

