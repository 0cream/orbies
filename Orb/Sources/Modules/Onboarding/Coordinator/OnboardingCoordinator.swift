import ComposableArchitecture

@Reducer
struct OnboardingCoordinator {
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            OnboardingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case let .destination(.presented(action)):
                return reduce(state: &state, action: action)
                
            case let .path(.element(_, action)):
                return reduce(state: &state, action: action)
                
            case .root, .destination, .path:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
    
    // MARK: - Root
    
    private func reduce(state: inout State, action: OnboardingFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didComplete:
            return .send(.delegate(.didComplete))
        }
    }
    
    // MARK: - Destination
    
    private func reduce(state: inout State, action: Destination.Action) -> Effect<Action> {
        return .none
    }
    
    // MARK: - Path
    
    private func reduce(state: inout State, action: Path.Action) -> Effect<Action> {
        // Empty for now
        return .none
    }
}
