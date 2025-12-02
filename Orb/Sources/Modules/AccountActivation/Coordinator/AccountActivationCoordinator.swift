import ComposableArchitecture

@Reducer
struct AccountActivationCoordinator {
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            AccountActivationFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .root(.delegate(.didComplete)):
                return .send(.delegate(.didComplete))
                
            case .root:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

