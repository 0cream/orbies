import ComposableArchitecture

@Reducer
struct NewsArticleDetailCoordinator {
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            NewsArticleDetailFeature()
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
    
    private func reduce(state: inout State, action: NewsArticleDetailFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didFinish:
            return .send(.delegate(.didFinish))
        }
    }
}

